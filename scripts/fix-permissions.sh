#!/bin/bash

# Intelligent WordPress Permissions Script
# This script sets up permissions that work for both development and production
# It uses a shared group approach to allow both www-data and host user access

set -e

WP_ROOT="/var/www/html"
WP_CONTENT="$WP_ROOT/wp-content"
WPDEV_GROUP="wpdev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[PERMISSIONS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PERMISSIONS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[PERMISSIONS]${NC} $1"
}

log_error() {
    echo -e "${RED}[PERMISSIONS]${NC} $1"
}

# Function to set permissions for a directory
set_directory_permissions() {
    local dir="$1"
    local dir_perms="$2"
    local file_perms="$3"
    local group="$4"
    
    if [ ! -d "$dir" ]; then
        log_warning "Directory $dir does not exist, skipping..."
        return
    fi
    
    # Set group ownership
    chgrp -R "$group" "$dir" 2>/dev/null || log_warning "Could not set group for $dir"
    
    # Set directory permissions
    find "$dir" -type d -exec chmod "$dir_perms" {} \; 2>/dev/null || log_warning "Could not set directory permissions for $dir"
    
    # Set file permissions
    find "$dir" -type f -exec chmod "$file_perms" {} \; 2>/dev/null || log_warning "Could not set file permissions for $dir"
    
    log_info "Set permissions for $dir (dirs: $dir_perms, files: $file_perms, group: $group)"
}

# Function to create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    local owner="$2"
    local group="$3"
    local perms="$4"
    
    if [ ! -d "$dir" ]; then
        log_info "Creating directory: $dir"
        mkdir -p "$dir"
        chown "$owner:$group" "$dir"
        chmod "$perms" "$dir"
    fi
}

# Main permissions setup
setup_permissions() {
    log_info "Setting up WordPress permissions with shared group approach..."
    
    # Ensure WordPress root exists
    if [ ! -d "$WP_ROOT" ]; then
        log_error "WordPress root directory $WP_ROOT not found!"
        exit 1
    fi
    
    # Check if wpdev group exists
    if ! getent group "$WPDEV_GROUP" > /dev/null 2>&1; then
        log_warning "Group $WPDEV_GROUP not found, creating it..."
        groupadd "$WPDEV_GROUP"
        usermod -a -G "$WPDEV_GROUP" www-data
    fi
    
    # Core WordPress files - readable by all, writable by www-data
    log_info "Setting permissions for core WordPress files..."
    chown -R www-data:"$WPDEV_GROUP" "$WP_ROOT"
    
    # WordPress core files (conservative permissions)
    find "$WP_ROOT" -maxdepth 1 -type f -exec chmod 644 {} \;
    find "$WP_ROOT" -maxdepth 1 -type d -exec chmod 755 {} \;
    
    # wp-config.php - secure but writable by WordPress
    if [ -f "$WP_ROOT/wp-config.php" ]; then
        chmod 644 "$WP_ROOT/wp-config.php"
        chown www-data:"$WPDEV_GROUP" "$WP_ROOT/wp-config.php"
        log_info "Set secure permissions for wp-config.php"
    fi
    
    # Ensure critical directories exist
    ensure_directory "$WP_CONTENT" "www-data" "$WPDEV_GROUP" "775"
    ensure_directory "$WP_CONTENT/themes" "www-data" "$WPDEV_GROUP" "775"
    ensure_directory "$WP_CONTENT/plugins" "www-data" "$WPDEV_GROUP" "775"
    ensure_directory "$WP_CONTENT/uploads" "www-data" "$WPDEV_GROUP" "775"
    ensure_directory "$WP_CONTENT/upgrade" "www-data" "$WPDEV_GROUP" "775"
    ensure_directory "$WP_CONTENT/cache" "www-data" "$WPDEV_GROUP" "775"
    
    # wp-content directory - development and WordPress friendly
    # Using 775 for directories and 664 for files allows both www-data and group members to write
    set_directory_permissions "$WP_CONTENT" "775" "664" "$WPDEV_GROUP"
    
    # Special handling for uploads - needs to be very permissive
    if [ -d "$WP_CONTENT/uploads" ]; then
        chmod -R 775 "$WP_CONTENT/uploads"
        chown -R www-data:"$WPDEV_GROUP" "$WP_CONTENT/uploads"
        log_info "Set permissive permissions for uploads directory"
    fi
    
    # Set sticky bit on wp-content to ensure new files inherit group
    chmod g+s "$WP_CONTENT"
    find "$WP_CONTENT" -type d -exec chmod g+s {} \; 2>/dev/null || true
    
    log_success "WordPress permissions configured successfully!"
    log_info "Permissions summary:"
    log_info "  • Core WP files: 644 (www-data:$WPDEV_GROUP)"
    log_info "  • wp-content dirs: 775 with sticky bit (www-data:$WPDEV_GROUP)"
    log_info "  • wp-content files: 664 (www-data:$WPDEV_GROUP)"
    log_info "  • Both www-data and host user can read/write in wp-content"
}

# Development mode - more permissive
setup_dev_permissions() {
    log_info "Setting up DEVELOPMENT permissions (more permissive)..."
    setup_permissions
    
    # Make everything in wp-content more permissive for development
    if [ -d "$WP_CONTENT" ]; then
        chmod -R g+w "$WP_CONTENT"
        log_info "Made wp-content group writable for development"
    fi
}

# Production mode - more secure
setup_prod_permissions() {
    log_info "Setting up PRODUCTION permissions (more secure)..."
    
    # In production, prioritize security
    chown -R www-data:www-data "$WP_ROOT"
    
    # Core files - read-only
    find "$WP_ROOT" -maxdepth 1 -type f -exec chmod 644 {} \;
    find "$WP_ROOT" -maxdepth 1 -type d -exec chmod 755 {} \;
    
    # wp-config.php - very secure
    if [ -f "$WP_ROOT/wp-config.php" ]; then
        chmod 600 "$WP_ROOT/wp-config.php"
        chown www-data:www-data "$WP_ROOT/wp-config.php"
    fi
    
    # wp-content - restrictive but functional
    if [ -d "$WP_CONTENT" ]; then
        set_directory_permissions "$WP_CONTENT" "755" "644" "www-data"
        
        # Uploads need to be writable
        if [ -d "$WP_CONTENT/uploads" ]; then
            set_directory_permissions "$WP_CONTENT/uploads" "755" "644" "www-data"
        fi
    fi
    
    log_success "Production permissions set - prioritizing security"
}

# Full access mode - maximum permissions for development/editing
setup_full_access_permissions() {
    log_info "Setting up FULL ACCESS permissions (777/666 - maximum access)..."
    
    if [ ! -d "$WP_ROOT" ]; then
        log_error "WordPress root directory $WP_ROOT not found!"
        exit 1
    fi
    
    # Set all files to 666 (rw-rw-rw-)
    log_info "Setting all files to 666 (full read/write)..."
    find "$WP_ROOT" -type f -exec chmod 666 {} \; 2>/dev/null || log_warning "Some files could not be modified"
    
    # Set all directories to 777 (rwxrwxrwx)
    log_info "Setting all directories to 777 (full read/write/execute)..."
    find "$WP_ROOT" -type d -exec chmod 777 {} \; 2>/dev/null || log_warning "Some directories could not be modified"
    
    log_success "Full access permissions configured!"
    log_info "Permissions summary:"
    log_info "  • All files: 666 (rw-rw-rw-) - Everyone can read/write"
    log_info "  • All directories: 777 (rwxrwxrwx) - Everyone can read/write/delete"
    log_info "  • This is the most permissive mode for development/editing"
}

# Main script logic
MODE="${1:-auto}"

# Skip permissions setup in CI environments
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$GITLAB_CI" ]; then
    log_info "CI environment detected, skipping permissions setup"
    exit 0
fi

# Check if we have necessary permissions to modify files
if [ "$(id -u)" -ne 0 ] && ! groups | grep -q sudo; then
    log_warning "Limited permissions detected, some operations may be skipped"
fi

case "$MODE" in
    "dev"|"development")
        setup_dev_permissions
        ;;
    "prod"|"production")
        setup_prod_permissions
        ;;
    "full"|"full-access"|"maximum")
        setup_full_access_permissions
        ;;
    "auto"|*)
        # Auto-detect based on environment
        if [ "${WORDPRESS_DEBUG:-false}" = "true" ] || [ "${NODE_ENV:-}" = "development" ]; then
            setup_dev_permissions
        else
            setup_prod_permissions
        fi
        ;;
esac

log_success "Permission setup complete!"