#!/bin/bash

# WordPress Composer Management Script
# Usage: ./composer.sh [command] [arguments]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to ensure containers are ready and fix permissions
ensure_ready() {
    print_info "Ensuring Docker containers are ready and permissions are correct..."
    
    # Start containers if they're not running
    if ! docker compose ps wordpress | grep -q "Up"; then
        print_info "Starting WordPress containers..."
        docker compose up -d
        
        # Wait for WordPress to be ready
        print_info "Waiting for WordPress to be ready..."
        for i in {1..30}; do
            if docker compose exec -T wordpress curl -f http://localhost >/dev/null 2>&1; then
                break
            fi
            sleep 2
        done
    fi
    
    # Always fix permissions after ensuring containers are up
    print_info "Auto-fixing permissions..."
    auto_fix_permissions
    print_success "System ready!"
}

# Function to run composer commands
run_composer() {
    print_info "Running: composer $*"
    docker compose --profile tools run --rm composer "$@"
    
    # Auto-fix permissions after composer operations that modify files
    case "$1" in
        "install"|"update"|"require"|"remove")
            print_info "Auto-fixing permissions after Composer operation..."
            auto_fix_permissions
            ;;
    esac
}

# Function to automatically fix permissions (silent version)
auto_fix_permissions() {
    if [ -d "wp_data" ] && check_containers wordpress >/dev/null 2>&1; then
        # Get www-data UID/GID
        WWW_DATA_UID=$(docker compose exec -T wordpress id -u www-data 2>/dev/null)
        WWW_DATA_GID=$(docker compose exec -T wordpress id -g www-data 2>/dev/null)
        
        if [ -n "$WWW_DATA_UID" ] && [ -n "$WWW_DATA_GID" ]; then
            # Fix ownership of all WordPress content directories
            sudo chown -R "$WWW_DATA_UID:$WWW_DATA_GID" wp_data/wp-content/ 2>/dev/null || true
            
            # Set proper permissions for directories and files
            sudo find wp_data/wp-content/ -type d -exec chmod 755 {} \; 2>/dev/null || true
            sudo find wp_data/wp-content/ -type f -exec chmod 644 {} \; 2>/dev/null || true
            
            # Ensure uploads directory is fully writable
            if [ -d "wp_data/wp-content/uploads" ]; then
                sudo chmod -R 755 wp_data/wp-content/uploads/ 2>/dev/null || true
            fi
            
            # Make wp-config.php writable for WordPress updates
            if [ -f "wp_data/wp-config.php" ]; then
                sudo chown "$WWW_DATA_UID:$WWW_DATA_GID" wp_data/wp-config.php 2>/dev/null || true
                sudo chmod 644 wp_data/wp-config.php 2>/dev/null || true
            fi
        fi
    fi
}

# Function to check container health
check_containers() {
    local service="$1"
    if [ -z "$service" ]; then
        # Check all containers
        if ! docker compose ps | grep -q "Up"; then
            print_warning "Some containers may not be running. Consider running: docker compose up -d"
            return 1
        fi
    else
        # Check specific service
        if ! docker compose ps "$service" | grep -q "Up"; then
            print_warning "$service container is not running. Consider running: docker compose up -d"
            return 1
        fi
    fi
    return 0
}

# Function to run WP-CLI commands with timeout and error handling
run_wpcli_safe() {
    local timeout=10
    local command="$*"
    
    print_info "Running WP-CLI command with ${timeout}s timeout: wp $command"
    
    # Check if WordPress containers are running
    if ! docker compose ps wordpress | grep -q "Up"; then
        print_warning "WordPress container is not running. Skipping WP-CLI command."
        return 1
    fi
    
    # Run with timeout
    if timeout $timeout docker compose --profile tools run --rm wpcli "$@" 2>/dev/null; then
        return 0
    else
        print_warning "WP-CLI command timed out or failed after ${timeout}s"
        return 1
    fi
}

# Function to run WP-CLI commands
run_wpcli() {
    print_info "Running: wp $*"
    docker compose --profile tools run --rm wpcli "$@"
}

# Main script logic
case "${1:-help}" in
    "ready"|"ensure-ready")
        ensure_ready
        ;;
    
    "start"|"up")
        print_info "Starting WordPress containers and ensuring permissions..."
        docker compose up -d
        
        # Wait for containers to be healthy
        print_info "Waiting for containers to be ready..."
        sleep 5
        
        # Auto-fix permissions
        auto_fix_permissions
        print_success "WordPress is ready!"
        ;;
    
    "install"|"i")
        print_info "Installing Composer dependencies..."
        ensure_ready
        run_composer install
        print_success "Dependencies installed successfully!"
        ;;
    
    "update"|"u")
        print_info "Updating Composer dependencies..."
        ensure_ready
        run_composer update
        print_success "Dependencies updated successfully!"
        ;;
    
    "require"|"r")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh require wpackagist-plugin/plugin-name"
            exit 1
        fi
        
        ensure_ready
        
        # Check if version constraint is provided
        if [ -n "$3" ]; then
            print_info "Adding package: $2 with version constraint: $3"
            run_composer require "$2:$3"
        else
            print_info "Adding package: $2"
            run_composer require "$2"
        fi
        print_success "Package $2 added successfully!"
        ;;
    
    "remove"|"rm")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh remove wpackagist-plugin/plugin-name"
            exit 1
        fi
        ensure_ready
        print_info "Removing package: $2"
        run_composer remove "$2"
        print_success "Package $2 removed successfully!"
        ;;
    
    "downgrade"|"dg")
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Package name and version required. Usage: ./composer.sh downgrade wpackagist-plugin/plugin-name 1.2.3"
            exit 1
        fi
        print_info "Downgrading package $2 to version $3"
        run_composer require "$2:$3"
        print_success "Package $2 downgraded to version $3 successfully!"
        ;;
    
    "upgrade"|"up")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh upgrade wpackagist-plugin/plugin-name"
            exit 1
        fi
        print_info "Upgrading package: $2 to latest version"
        run_composer require "$2:*"
        print_success "Package $2 upgraded successfully!"
        ;;
    
    "version"|"v")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh version wpackagist-plugin/plugin-name"
            exit 1
        fi
        print_info "Checking available versions for: $2"
        run_composer show "$2" --all
        ;;
    
    "why")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh why wpackagist-plugin/plugin-name"
            exit 1
        fi
        print_info "Checking why package $2 is installed"
        run_composer why "$2"
        ;;
    
    "clean")
        print_warning "This will remove all Composer dependencies and reinstall them."
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning and reinstalling dependencies..."
            rm -rf vendor/ composer.lock
            run_composer install
            print_success "Dependencies cleaned and reinstalled!"
        else
            print_info "Operation cancelled."
        fi
        ;;
    
    "doctor"|"diagnose")
        print_info "Running diagnostics..."
        echo ""
        
        print_info "=== Container Status ==="
        docker compose ps
        echo ""
        
        print_info "=== Composer Validation ==="
        run_composer validate
        echo ""
        
        print_info "=== Installed Packages ==="
        run_composer show
        echo ""
        
        print_info "=== WordPress Status ==="
        if check_containers wordpress; then
            if run_wpcli_safe core version; then
                print_success "WordPress is accessible"
                run_wpcli_safe plugin list --status=active --format=table
            else
                print_warning "WordPress not accessible via WP-CLI"
            fi
        else
            print_warning "WordPress container not running"
        fi
        echo ""
        
        print_info "=== Disk Usage ==="
        echo "Vendor directory: $(du -sh vendor/ 2>/dev/null || echo 'Not found')"
        echo "WordPress plugins: $(du -sh wp_data/wp-content/plugins/ 2>/dev/null || echo 'Not found')"
        echo "WordPress themes: $(du -sh wp_data/wp-content/themes/ 2>/dev/null || echo 'Not found')"
        ;;
        
    "fix-permissions"|"permissions"|"perms")
        print_info "Fixing WordPress file permissions..."
        
        # Check if wp_data directory exists
        if [ ! -d "wp_data" ]; then
            print_error "wp_data directory not found. Make sure WordPress is installed."
            exit 1
        fi
        
        # Ensure containers are running
        if ! docker compose ps wordpress | grep -q "Up"; then
            print_warning "WordPress container is not running. Starting it..."
            docker compose up -d wordpress
            sleep 5
        fi
        
        # Get the www-data user ID from the WordPress container
        print_info "Getting www-data user ID from WordPress container..."
        WWW_DATA_UID=$(docker compose exec -T wordpress id -u www-data 2>/dev/null)
        WWW_DATA_GID=$(docker compose exec -T wordpress id -g www-data 2>/dev/null)
        
        # Check if UID/GID retrieval was successful
        if [[ -z "$WWW_DATA_UID" || -z "$WWW_DATA_GID" || ! "$WWW_DATA_UID" =~ ^[0-9]+$ || ! "$WWW_DATA_GID" =~ ^[0-9]+$ ]]; then
            print_error "Failed to retrieve valid www-data UID/GID from the WordPress container."
            print_info "Trying fallback approach with common www-data ID (33:33)..."
            WWW_DATA_UID=33
            WWW_DATA_GID=33
        fi
        
        print_info "Setting ownership to www-data ($WWW_DATA_UID:$WWW_DATA_GID)..."
        
        # Fix ownership recursively for WordPress content
        sudo chown -R "$WWW_DATA_UID:$WWW_DATA_GID" wp_data/wp-content/
        
        # Also fix wp-config.php
        if [ -f "wp_data/wp-config.php" ]; then
            sudo chown "$WWW_DATA_UID:$WWW_DATA_GID" wp_data/wp-config.php
        fi
        
        # Set proper permissions
        print_info "Setting proper file permissions..."
        
        # WordPress content directories
        sudo find wp_data/wp-content/ -type d -exec chmod 755 {} \;
        sudo find wp_data/wp-content/ -type f -exec chmod 644 {} \;
        
        # Make uploads directory fully writable
        if [ -d "wp_data/wp-content/uploads" ]; then
            sudo chmod -R 755 wp_data/wp-content/uploads/
            print_info "Uploads directory permissions set to 755 (writable)"
        fi
        
        # Make wp-config.php appropriately writable
        if [ -f "wp_data/wp-config.php" ]; then
            sudo chmod 644 wp_data/wp-config.php
            print_info "wp-config.php permissions set to 644"
        fi
        
        # Create uploads directory if it doesn't exist
        if [ ! -d "wp_data/wp-content/uploads" ]; then
            print_info "Creating uploads directory..."
            sudo mkdir -p wp_data/wp-content/uploads
            sudo chown "$WWW_DATA_UID:$WWW_DATA_GID" wp_data/wp-content/uploads
            sudo chmod 755 wp_data/wp-content/uploads
        fi
        
        print_success "File permissions fixed!"
        print_info "WordPress should now be able to:"
        print_info "  ✓ Update plugins and themes through admin interface"
        print_info "  ✓ Upload media files"
        print_info "  ✓ Create temporary files and cache"
        print_info "  ✓ Generate PDFs and other dynamic content"
        ;;
        
    "validate")
        print_info "Validating composer.json..."
        run_composer validate
        ;;
        
    "info"|"search")
        if [ -z "$2" ]; then
            print_error "Package name required. Usage: ./composer.sh info wpackagist-plugin/plugin-name"
            exit 1
        fi
        print_info "Getting information about: $2"
        run_composer show "$2"
        ;;
    
    "show"|"list")
        print_info "Listing installed packages..."
        run_composer show
        ;;
    
    "outdated")
        print_info "Checking for outdated packages..."
        run_composer outdated
        ;;
    
    "plugin")
        case "${2:-help}" in
            "install")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin install plugin-name [version]"
                    exit 1
                fi
                
                ensure_ready
                
                if [ -n "$4" ]; then
                    print_info "Installing plugin via Composer: $3 with version constraint: $4"
                    run_composer require "wpackagist-plugin/$3:$4"
                else
                    print_info "Installing plugin via Composer: $3"
                    run_composer require "wpackagist-plugin/$3"
                fi
                print_success "Plugin $3 installed successfully!"
                ;;
            "remove")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin remove plugin-name"
                    exit 1
                fi
                
                print_info "Removing plugin: $3"
                
                # Option 1: Try to deactivate plugin first (with timeout and fallback)
                print_info "Step 1: Attempting to deactivate plugin safely..."
                if run_wpcli_safe plugin deactivate "$3"; then
                    print_success "Plugin $3 deactivated successfully"
                else
                    print_warning "Could not deactivate plugin (WordPress may not be accessible or plugin already inactive)"
                    print_info "Continuing with removal..."
                fi
                
                # Option 2: Remove via Composer (this should always work)
                print_info "Step 2: Removing plugin via Composer..."
                if run_composer remove "wpackagist-plugin/$3"; then
                    print_success "Plugin $3 removed successfully via Composer!"
                else
                    print_error "Failed to remove plugin via Composer"
                    
                    # Option 3: Fallback - manual removal
                    print_warning "Attempting manual cleanup..."
                    
                    # Check if plugin directory exists and remove it
                    plugin_dir="wp_data/wp-content/plugins/$3"
                    if [ -d "$plugin_dir" ]; then
                        print_info "Removing plugin directory manually: $plugin_dir"
                        rm -rf "$plugin_dir"
                        print_success "Plugin directory removed manually"
                    fi
                    
                    # Try to remove from composer.json manually
                    print_info "Attempting to remove from composer.json..."
                    if command -v jq >/dev/null 2>&1; then
                        # Use jq if available
                        jq "del(.require[\"wpackagist-plugin/$3\"]) | del(.\"require-dev\"[\"wpackagist-plugin/$3\"])" composer.json > composer.json.tmp && mv composer.json.tmp composer.json
                        print_success "Removed from composer.json"
                    else
                        print_warning "Please manually remove 'wpackagist-plugin/$3' from composer.json"
                    fi
                fi
                ;;
            "force-remove")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin force-remove plugin-name"
                    exit 1
                fi
                
                print_warning "Force removing plugin $3 (skipping deactivation)..."
                
                # Skip deactivation, go straight to removal
                print_info "Removing plugin via Composer..."
                run_composer remove "wpackagist-plugin/$3"
                
                # Also remove directory if it exists
                plugin_dir="wp_data/wp-content/plugins/$3"
                if [ -d "$plugin_dir" ]; then
                    print_info "Force removing plugin directory: $plugin_dir"
                    rm -rf "$plugin_dir"
                fi
                
                print_success "Plugin $3 force-removed successfully!"
                ;;
            "downgrade")
                if [ -z "$3" ] || [ -z "$4" ]; then
                    print_error "Plugin name and version required. Usage: ./composer.sh plugin downgrade plugin-name 1.2.3"
                    exit 1
                fi
                print_info "Downgrading plugin $3 to version $4"
                run_composer require "wpackagist-plugin/$3:$4"
                print_success "Plugin $3 downgraded to version $4 successfully!"
                ;;
            "upgrade")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin upgrade plugin-name"
                    exit 1
                fi
                print_info "Upgrading plugin $3 to latest version"
                run_composer require "wpackagist-plugin/$3:*"
                print_success "Plugin $3 upgraded successfully!"
                ;;
            "version")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin version plugin-name"
                    exit 1
                fi
                print_info "Checking available versions for plugin: $3"
                run_composer show "wpackagist-plugin/$3" --all
                ;;
            "activate")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin activate plugin-name"
                    exit 1
                fi
                print_info "Activating plugin via WP-CLI: $3"
                run_wpcli plugin activate "$3"
                print_success "Plugin $3 activated successfully!"
                ;;
            "deactivate")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin deactivate plugin-name"
                    exit 1
                fi
                print_info "Deactivating plugin via WP-CLI: $3"
                run_wpcli plugin deactivate "$3"
                print_success "Plugin $3 deactivated successfully!"
                ;;
            "status")
                if [ -z "$3" ]; then
                    print_error "Plugin name required. Usage: ./composer.sh plugin status plugin-name"
                    exit 1
                fi
                print_info "Checking plugin status: $3"
                run_wpcli plugin status "$3"
                ;;
            "list")
                print_info "Listing WordPress plugins..."
                run_wpcli plugin list
                ;;
            "search")
                if [ -z "$3" ]; then
                    print_error "Search term required. Usage: ./composer.sh plugin search search-term"
                    exit 1
                fi
                print_info "Searching for plugins with term: $3"
                print_warning "Searching WPackagist repository..."
                run_composer search "wpackagist-plugin" "$3"
                ;;
            *)
                echo "Plugin management commands:"
                echo "  ./composer.sh plugin install <plugin-name> [version]  - Install plugin via Composer"
                echo "  ./composer.sh plugin remove <plugin-name>            - Remove plugin via Composer (safe)"
                echo "  ./composer.sh plugin force-remove <plugin-name>      - Force remove plugin (skip deactivation)"
                echo "  ./composer.sh plugin downgrade <plugin-name> <ver>   - Downgrade plugin to specific version"
                echo "  ./composer.sh plugin upgrade <plugin-name>           - Upgrade plugin to latest version"
                echo "  ./composer.sh plugin version <plugin-name>           - Show available versions"
                echo "  ./composer.sh plugin activate <plugin-name>          - Activate plugin via WP-CLI"
                echo "  ./composer.sh plugin deactivate <plugin-name>        - Deactivate plugin via WP-CLI"
                echo "  ./composer.sh plugin status <plugin-name>            - Check plugin status"
                echo "  ./composer.sh plugin list                            - List all plugins"
                echo "  ./composer.sh plugin search <term>                   - Search for plugins"
                echo ""
                echo "Safe removal (default): Tries to deactivate first, has fallbacks"
                echo "Force removal: Skips deactivation, removes immediately"
                ;;
        esac
        ;;
    
    "theme")
        case "${2:-help}" in
            "install")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme install theme-name [version]"
                    exit 1
                fi
                
                ensure_ready
                
                if [ -n "$4" ]; then
                    print_info "Installing theme via Composer: $3 with version constraint: $4"
                    run_composer require "wpackagist-theme/$3:$4"
                else
                    print_info "Installing theme via Composer: $3"
                    run_composer require "wpackagist-theme/$3"
                fi
                print_success "Theme $3 installed successfully!"
                ;;
            "remove")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme remove theme-name"
                    exit 1
                fi
                print_info "Removing theme: $3"
                run_composer remove "wpackagist-theme/$3"
                print_success "Theme $3 removed successfully!"
                ;;
            "downgrade")
                if [ -z "$3" ] || [ -z "$4" ]; then
                    print_error "Theme name and version required. Usage: ./composer.sh theme downgrade theme-name 1.2.3"
                    exit 1
                fi
                print_info "Downgrading theme $3 to version $4"
                run_composer require "wpackagist-theme/$3:$4"
                print_success "Theme $3 downgraded to version $4 successfully!"
                ;;
            "upgrade")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme upgrade theme-name"
                    exit 1
                fi
                print_info "Upgrading theme $3 to latest version"
                run_composer require "wpackagist-theme/$3:*"
                print_success "Theme $3 upgraded successfully!"
                ;;
            "version")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme version theme-name"
                    exit 1
                fi
                print_info "Checking available versions for theme: $3"
                run_composer show "wpackagist-theme/$3" --all
                ;;
            "activate")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme activate theme-name"
                    exit 1
                fi
                print_info "Activating theme via WP-CLI: $3"
                run_wpcli theme activate "$3"
                print_success "Theme $3 activated successfully!"
                ;;
            "status")
                if [ -z "$3" ]; then
                    print_error "Theme name required. Usage: ./composer.sh theme status theme-name"
                    exit 1
                fi
                print_info "Checking theme status: $3"
                run_wpcli theme status "$3"
                ;;
            "list")
                print_info "Listing WordPress themes..."
                run_wpcli theme list
                ;;
            "search")
                if [ -z "$3" ]; then
                    print_error "Search term required. Usage: ./composer.sh theme search search-term"
                    exit 1
                fi
                print_info "Searching for themes with term: $3"
                print_warning "Searching WPackagist repository..."
                run_composer search "wpackagist-theme" "$3"
                ;;
            *)
                echo "Theme management commands:"
                echo "  ./composer.sh theme install <theme-name> [version]  - Install theme via Composer"
                echo "  ./composer.sh theme remove <theme-name>             - Remove theme via Composer"
                echo "  ./composer.sh theme downgrade <theme-name> <ver>    - Downgrade theme to specific version"
                echo "  ./composer.sh theme upgrade <theme-name>            - Upgrade theme to latest version"
                echo "  ./composer.sh theme version <theme-name>            - Show available versions"
                echo "  ./composer.sh theme activate <theme-name>           - Activate theme via WP-CLI"
                echo "  ./composer.sh theme status <theme-name>             - Check theme status"
                echo "  ./composer.sh theme list                            - List all themes"
                echo "  ./composer.sh theme search <term>                   - Search for themes"
                ;;
        esac
        ;;
    
    "wp")
        shift
        run_wpcli "$@"
        ;;
    
    "help"|*)
        echo "WordPress Composer Management Script"
        echo ""
        echo "Container & System commands:"
        echo "  ./composer.sh start                       - Start containers and fix permissions"
        echo "  ./composer.sh ready                       - Ensure containers are ready and fix permissions"
        echo "  ./composer.sh fix-permissions             - Fix WordPress file permissions for web updates"
        echo ""
        echo "Basic Composer commands:"
        echo "  ./composer.sh install                     - Install all dependencies"
        echo "  ./composer.sh update                      - Update all dependencies"
        echo "  ./composer.sh require <package> [version] - Add a new package"
        echo "  ./composer.sh remove <package>            - Remove a package"
        echo "  ./composer.sh downgrade <package> <ver>   - Downgrade to specific version"
        echo "  ./composer.sh upgrade <package>           - Upgrade package to latest"
        echo "  ./composer.sh show                        - List installed packages"
        echo "  ./composer.sh outdated                    - Check for outdated packages"
        echo "  ./composer.sh version <package>           - Show available versions"
        echo "  ./composer.sh why <package>               - Show why package is installed"
        echo "  ./composer.sh info <package>              - Get package information"
        echo "  ./composer.sh validate                    - Validate composer.json"
        echo "  ./composer.sh clean                       - Clean and reinstall all"
        echo "  ./composer.sh doctor                      - Run diagnostics and health checks"
        echo ""
        echo "Plugin management:"
        echo "  ./composer.sh plugin install <name> [ver] - Install plugin from WPackagist"
        echo "  ./composer.sh plugin remove <name>        - Remove plugin (safe, with fallbacks)"
        echo "  ./composer.sh plugin force-remove <name>  - Force remove plugin (skip deactivation)"
        echo "  ./composer.sh plugin downgrade <name> <v> - Downgrade plugin version"
        echo "  ./composer.sh plugin upgrade <name>       - Upgrade plugin to latest"
        echo "  ./composer.sh plugin activate <name>      - Activate plugin"
        echo "  ./composer.sh plugin deactivate <name>    - Deactivate plugin"
        echo "  ./composer.sh plugin status <name>        - Check plugin status"
        echo "  ./composer.sh plugin version <name>       - Show available versions"
        echo "  ./composer.sh plugin list                 - List all plugins"
        echo "  ./composer.sh plugin search <term>        - Search for plugins"
        echo ""
        echo "Theme management:"
        echo "  ./composer.sh theme install <name> [ver]  - Install theme from WPackagist"
        echo "  ./composer.sh theme remove <name>         - Remove theme"
        echo "  ./composer.sh theme downgrade <name> <v>  - Downgrade theme version"
        echo "  ./composer.sh theme upgrade <name>        - Upgrade theme to latest"
        echo "  ./composer.sh theme activate <name>       - Activate theme"
        echo "  ./composer.sh theme status <name>         - Check theme status"
        echo "  ./composer.sh theme version <name>        - Show available versions"
        echo "  ./composer.sh theme list                  - List all themes"
        echo "  ./composer.sh theme search <term>         - Search for themes"
        echo ""
        echo "WP-CLI commands:"
        echo "  ./composer.sh wp <command>                - Run any WP-CLI command"
        echo ""
        echo "Examples:"
        echo "  ./composer.sh plugin install contact-form-7"
        echo "  ./composer.sh plugin install wordfence 7.10.1"
        echo "  ./composer.sh plugin downgrade wordfence 7.9.0"
        echo "  ./composer.sh plugin remove contact-form-7"
        echo "  ./composer.sh theme install astra 4.0.0"
        echo "  ./composer.sh downgrade wpackagist-plugin/akismet 4.2.0"
        echo "  ./composer.sh version wpackagist-plugin/wordfence"
        echo "  ./composer.sh wp core version"
        ;;
esac