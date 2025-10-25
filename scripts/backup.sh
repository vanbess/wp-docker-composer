#!/bin/bash

# Backup and restore script for WordPress Docker environment
# Allows creating full backups and restoring from them in case of breaking changes

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

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

backup_create() {
    local backup_name="${PROJECT_NAME}_${DATE}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    print_info "Creating backup: $backup_name"
    
    # Create temporary backup directory
    mkdir -p "$backup_path"
    
    # Check if containers are running
    if ! docker compose ps db | grep -q "Up"; then
        print_warning "Database container not running, starting it..."
        docker compose up -d db
        sleep 5
    fi
    
    # Backup database
    print_info "Backing up database..."
    if [ ! -f ".env" ]; then
        print_error ".env file not found"
        rm -rf "$backup_path"
        exit 1
    fi
    
    local mysql_root_password=$(grep MYSQL_ROOT_PASSWORD .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    if [ -z "$mysql_root_password" ]; then
        print_error "Could not read MYSQL_ROOT_PASSWORD from .env"
        rm -rf "$backup_path"
        exit 1
    fi
    
    docker compose exec -T db mariadb-dump \
        -u root -p"$mysql_root_password" \
        --all-databases \
        --single-transaction \
        --routines \
        --triggers > "$backup_path/database.sql" || {
        print_error "Database backup failed"
        rm -rf "$backup_path"
        exit 1
    }
    
    # Backup WordPress files
    print_info "Backing up WordPress files..."
    if [ -d "wp_data" ]; then
        tar -czf "$backup_path/wp_data.tar.gz" -C wp_data . 2>/dev/null || {
            print_warning "Some WordPress files could not be backed up (may be locked)"
        }
    else
        print_warning "wp_data directory not found, skipping WordPress files backup"
    fi
    
    # Backup configuration files
    print_info "Backing up configuration..."
    [ -f ".env" ] && cp .env "$backup_path/"
    [ -f "composer.json" ] && cp composer.json "$backup_path/"
    [ -f "composer.lock" ] && cp composer.lock "$backup_path/" 2>/dev/null || true
    [ -f "docker-compose.yml" ] && cp docker-compose.yml "$backup_path/"
    [ -f "docker-compose.prod.yml" ] && cp docker-compose.prod.yml "$backup_path/" 2>/dev/null || true
    
    # Create backup metadata
    cat > "$backup_path/backup_info.txt" << EOF
Backup Created: $(date)
Project: $PROJECT_NAME
Hostname: $(hostname)
User: $(whoami)
Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
EOF
    
    # Compress entire backup
    print_info "Compressing backup..."
    tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$backup_name" && rm -rf "$backup_path"
    
    local size=$(du -sh "${backup_path}.tar.gz" | cut -f1)
    print_success "Backup created: ${backup_path}.tar.gz"
    print_info "Size: $size"
}

backup_restore() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file to restore"
        print_info "Available backups:"
        if ls "$BACKUP_DIR"/*.tar.gz 1> /dev/null 2>&1; then
            ls -lh "$BACKUP_DIR"/*.tar.gz | awk '{print "  " $NF " (" $5 ")"}'
        else
            print_warning "No backups found in $BACKUP_DIR/"
        fi
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "⚠️  This will overwrite your current WordPress installation and database!"
    print_warning "Make sure you have a recent backup before proceeding."
    read -p "Are you sure? (type 'yes' to continue): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Stop services
    print_info "Stopping services..."
    docker compose down
    
    # Extract backup
    local temp_dir="/tmp/wp_restore_$$"
    mkdir -p "$temp_dir"
    print_info "Extracting backup..."
    tar -xzf "$backup_file" -C "$temp_dir" || {
        print_error "Failed to extract backup"
        rm -rf "$temp_dir"
        exit 1
    }
    
    local backup_name=$(basename "$backup_file" .tar.gz)
    local backup_path="$temp_dir/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        print_error "Backup structure invalid"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Restore configuration
    print_info "Restoring configuration..."
    [ -f "$backup_path/.env" ] && cp "$backup_path/.env" .
    [ -f "$backup_path/composer.json" ] && cp "$backup_path/composer.json" .
    [ -f "$backup_path/composer.lock" ] && cp "$backup_path/composer.lock" . 2>/dev/null || true
    [ -f "$backup_path/docker-compose.yml" ] && cp "$backup_path/docker-compose.yml" .
    [ -f "$backup_path/docker-compose.prod.yml" ] && cp "$backup_path/docker-compose.prod.yml" . 2>/dev/null || true
    
    # Start database service only
    print_info "Starting database service..."
    docker compose up -d db
    
    # Wait for database to be ready
    print_info "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec -T db mariadb-admin ping >/dev/null 2>&1; then
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Restore database
    print_info "Restoring database..."
    if [ -f "$backup_path/database.sql" ]; then
        local mysql_root_password=$(grep MYSQL_ROOT_PASSWORD .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        docker compose exec -T db mysql \
            -u root -p"$mysql_root_password" \
            < "$backup_path/database.sql" || {
            print_error "Database restore failed"
            rm -rf "$temp_dir"
            exit 1
        }
    else
        print_error "Database backup file not found in backup"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Restore WordPress files
    print_info "Restoring WordPress files..."
    if [ -f "$backup_path/wp_data.tar.gz" ]; then
        rm -rf wp_data/*
        tar -xzf "$backup_path/wp_data.tar.gz" -C wp_data/ 2>/dev/null || {
            print_warning "Some WordPress files could not be restored (may be locked)"
        }
    else
        print_warning "WordPress files backup not found"
    fi
    
    # Start all services
    print_info "Starting all services..."
    docker compose up -d
    
    # Cleanup temp directory
    rm -rf "$temp_dir"
    
    print_success "Restore completed!"
    print_info "Your site should be available at the configured URL"
    print_info "Run './composer.sh fix-permissions' if you encounter permission issues"
}

backup_list() {
    print_info "Available backups:"
    if ls "$BACKUP_DIR"/*.tar.gz 1> /dev/null 2>&1; then
        echo ""
        ls -lhS "$BACKUP_DIR"/*.tar.gz | awk '{printf "  📦 %-50s %6s\n", $NF, $5}'
        echo ""
        local total=$(du -sh "$BACKUP_DIR" | cut -f1)
        print_info "Total backup size: $total"
    else
        print_warning "No backups found in $BACKUP_DIR/"
    fi
}

backup_cleanup() {
    local keep_days="${1:-30}"
    
    print_info "Cleaning up backups older than $keep_days days..."
    
    if [ -d "$BACKUP_DIR" ]; then
        local deleted=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$keep_days -delete -print | wc -l)
        if [ "$deleted" -gt 0 ]; then
            print_success "Deleted $deleted old backup(s)"
        else
            print_info "No backups older than $keep_days days found"
        fi
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
        cat << 'EOF'
WordPress Docker Backup & Restore Script
=========================================

This script creates and manages backups of your WordPress installation,
including the database, WordPress files, and configuration.

Usage:
  ./scripts/backup.sh create                    - Create a new backup
  ./scripts/backup.sh restore <backup-file>     - Restore from backup
  ./scripts/backup.sh list                      - List available backups
  ./scripts/backup.sh cleanup [days]           - Clean up old backups (default: 30 days)
  ./scripts/backup.sh help                      - Show this help message

Examples:
  # Create a backup before making changes
  ./scripts/backup.sh create

  # List all backups
  ./scripts/backup.sh list

  # Restore from a specific backup
  ./scripts/backup.sh restore backups/myproject_20241008_143022.tar.gz

  # Remove backups older than 7 days
  ./scripts/backup.sh cleanup 7

What's Included in a Backup:
  • Database (all tables, triggers, routines)
  • WordPress files (wp_data directory)
  • Configuration (.env, composer.json, docker-compose.yml)
  • Backup metadata (creation date, git info, etc.)

Tips:
  • Create backups BEFORE making major changes
  • Store important backups on external storage
  • Run cleanup periodically to save disk space
  • Always verify restore worked before deleting backups

EOF
        ;;
esac
