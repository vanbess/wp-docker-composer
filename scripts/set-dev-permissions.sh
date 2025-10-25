#!/bin/bash

# Script to set full read, write, and delete permissions for wp_data directory
# This script provides maximum access permissions for development/editing scenarios

# Detect the wp_data directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_DATA_DIR="${SCRIPT_DIR}/../wp_data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[DEV PERMISSIONS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DEV PERMISSIONS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DEV PERMISSIONS]${NC} $1"
}

log_error() {
    echo -e "${RED}[DEV PERMISSIONS]${NC} $1"
}

log_info "Setting FULL ACCESS permissions for WordPress files and directories"
log_info "Target directory: $WP_DATA_DIR"

# Check if the directory exists
if [ ! -d "$WP_DATA_DIR" ]; then
    log_error "Directory $WP_DATA_DIR does not exist!"
    exit 1
fi

# Navigate to the wp_data directory
cd "$WP_DATA_DIR" || exit 1

log_info "Setting directory permissions to 777 (rwxrwxrwx) - full access..."
# Set all directories to 777 (owner, group, others: read/write/execute)
# This allows deletion, modification, and creation of files
find . -type d -exec chmod 777 {} \; 2>/dev/null || log_warning "Some directories could not be modified"

log_info "Setting file permissions to 666 (rw-rw-rw-) - full read/write access..."
# Set all files to 666 (owner, group, others: read/write)
# This allows reading and modifying all files
find . -type f -exec chmod 666 {} \; 2>/dev/null || log_warning "Some files could not be modified"

log_success "Full access permissions applied successfully!"
echo ""
echo "Summary of permissions applied:"
echo "  • Directories: 777 (rwxrwxrwx) - Everyone can read/write/execute/delete"
echo "  • Files: 666 (rw-rw-rw-) - Everyone can read/write"
echo ""
echo "Features enabled:"
echo "  ✓ Full read access to all files"
echo "  ✓ Full write access to all files"
echo "  ✓ Delete capability for all files and directories"
echo "  ✓ Create new files and directories"
echo "  ✓ Modify wp-config.php and debug.log"
echo ""
echo "Verification:"
log_info "Sample file permissions:"
ls -la "$WP_DATA_DIR" | head -10
log_info "To verify all permissions, run: find $WP_DATA_DIR -type f -printf '%m %p\n' | head -20"
echo ""
log_success "Development environment is ready for full file access!"