#!/bin/bash

# Backup and restore script for WordPress Docker environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Get current directory name for backup naming
PROJECT_NAME=$(basename "$(pwd)")
BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)

backup_create() {
    local backup_name="${PROJECT_NAME}_${DATE}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    print_info "Creating backup: $backup_name"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup database
    print_info "Backing up database..."
    docker-compose exec -T db mariadb-dump \
        -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d'=' -f2)" \
        --all-databases \
        --single-transaction \
        --routines \
        --triggers > "$backup_path/database.sql"
    
    # Backup WordPress files
    print_info "Backing up WordPress files..."
    tar -czf "$backup_path/wp_data.tar.gz" -C wp_data .
    
    # Backup configuration
    print_info "Backing up configuration..."
    cp .env "$backup_path/"
    cp composer.json "$backup_path/"
    cp composer.lock "$backup_path/" 2>/dev/null || true
    cp docker-compose.yml "$backup_path/"
    
    # Create backup info
    cat > "$backup_path/backup_info.txt" << EOF
Backup Created: $(date)
Project: $PROJECT_NAME
WordPress Version: $(docker-compose exec -T wordpress wp core version 2>/dev/null || echo "Unknown")
Database Size: $(du -sh wp_data/ | cut -f1)
Files Size: $(du -sh wp_data/ | cut -f1)
EOF
    
    # Compress entire backup
    tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    print_success "Backup created: ${backup_path}.tar.gz"
    print_info "Size: $(du -sh "${backup_path}.tar.gz" | cut -f1)"
}

backup_restore() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file to restore"
        print_info "Available backups:"
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || print_warning "No backups found"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will overwrite your current WordPress installation!"
    read -p "Are you sure? (type 'yes' to continue): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Stop services
    print_info "Stopping services..."
    docker-compose down
    
    # Extract backup
    local temp_dir="/tmp/wp_restore_$$"
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local backup_name=$(basename "$backup_file" .tar.gz)
    local backup_path="$temp_dir/$backup_name"
    
    # Restore configuration
    print_info "Restoring configuration..."
    cp "$backup_path/.env" .
    cp "$backup_path/composer.json" .
    cp "$backup_path/composer.lock" . 2>/dev/null || true
    cp "$backup_path/docker-compose.yml" .
    
    # Start database service only
    print_info "Starting database service..."
    docker-compose up -d db
    
    # Wait for database
    sleep 10
    
    # Restore database
    print_info "Restoring database..."
    docker-compose exec -T db mysql \
        -u root -p"$(grep MYSQL_ROOT_PASSWORD .env | cut -d'=' -f2)" \
        < "$backup_path/database.sql"
    
    # Restore WordPress files
    print_info "Restoring WordPress files..."
    rm -rf wp_data/*
    tar -xzf "$backup_path/wp_data.tar.gz" -C wp_data/
    
    # Start all services
    print_info "Starting all services..."
    docker-compose up -d
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Restore completed!"
    print_info "Your site should be available at the configured URL"
}

backup_list() {
    print_info "Available backups:"
    if ls "$BACKUP_DIR"/*.tar.gz 1> /dev/null 2>&1; then
        for backup in "$BACKUP_DIR"/*.tar.gz; do
            local size=$(du -sh "$backup" | cut -f1)
            local date=$(basename "$backup" | sed 's/.*_\([0-9]\{8\}_[0-9]\{6\}\).*/\1/')
            echo "  📦 $(basename "$backup") ($size) - $date"
        done
    else
        print_warning "No backups found in $BACKUP_DIR/"
    fi
}

backup_cleanup() {
    local keep_days="${1:-30}"
    
    print_info "Cleaning up backups older than $keep_days days..."
    
    if [ -d "$BACKUP_DIR" ]; then
        find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$keep_days -delete
        print_success "Cleanup completed"
    else
        print_warning "Backup directory not found"
    fi
}

# Main script logic
case "${1:-help}" in
    "create"|"backup")
        backup_create
        ;;
    "restore")
        backup_restore "$2"
        ;;
    "list"|"ls")
        backup_list
        ;;
    "cleanup")
        backup_cleanup "$2"
        ;;
    "help"|*)
        echo "WordPress Docker Backup Script"
        echo ""
        echo "Usage:"
        echo "  $0 create                    - Create a new backup"
        echo "  $0 restore <backup-file>     - Restore from backup"
        echo "  $0 list                      - List available backups"
        echo "  $0 cleanup [days]           - Clean up old backups (default: 30 days)"
        echo ""
        echo "Examples:"
        echo "  $0 create"
        echo "  $0 restore backups/myproject_20241008_143022.tar.gz"
        echo "  $0 cleanup 7"
        ;;
esac