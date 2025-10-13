#!/bin/bash

# Script to set full read and write permissions for wp_data directory
# This script sets appropriate permissions for WordPress files and directories

WP_DATA_DIR="/home/werner/wp-docker-123card/wp_data"

echo "Setting permissions for WordPress files and directories in: $WP_DATA_DIR"

# Check if the directory exists
if [ ! -d "$WP_DATA_DIR" ]; then
    echo "Error: Directory $WP_DATA_DIR does not exist!"
    exit 1
fi

# Navigate to the wp_data directory
cd "$WP_DATA_DIR" || exit 1

echo "Setting directory permissions to 775 (rwxrwxr-x) for full access..."
# Set directories to 775 (owner: read/write/execute, group: read/write/execute, others: read/execute)
find . -type d -exec chmod 775 {} \;

echo "Setting file permissions to 664 (rw-rw-r--) for full read/write access..."
# Set files to 664 (owner: read/write, group: read/write, others: read)
find . -type f -exec chmod 664 {} \;

echo "Setting special permissions for log files and writable files..."
# Make sure log files are fully writable
if [ -f "wp-content/debug.log" ]; then
    chmod 666 wp-content/debug.log
fi

# Find and set all .log files to be writable
find . -name "*.log" -exec chmod 666 {} \;

echo "Setting permissions for wp-content and subdirectories..."
# Set wp-content and all subdirectories to be fully writable for development
if [ -d "wp-content" ]; then
    chmod -R 775 wp-content
    # Make all files in wp-content writable
    find wp-content -type f -exec chmod 664 {} \;
    # Make log files and cache files fully writable
    find wp-content -name "*.log" -exec chmod 666 {} \;
    find wp-content -name "cache" -type d -exec chmod 777 {} \;
    find wp-content -path "*/cache/*" -exec chmod 666 {} \;
fi

echo "Setting ownership to www-data:werner..."
# Change ownership to www-data:werner (as shown in your file listing)
sudo chown -R www-data:werner .

echo "Permissions set successfully!"
echo ""
echo "Summary of permissions applied (Development Environment):"
echo "- Directories: 775 (rwxrwxr-x) - full read/write/execute for owner and group"
echo "- Files: 664 (rw-rw-r--) - full read/write for owner and group"
echo "- Log files: 666 (rw-rw-rw-) - full read/write for everyone"
echo "- Cache directories: 777 (rwxrwxrwx) - full access for cache operations"
echo "- Ownership: www-data:werner"
echo ""
echo "You should now be able to edit, save, and clear files like debug.log"
echo "To verify permissions, run: ls -la $WP_DATA_DIR"