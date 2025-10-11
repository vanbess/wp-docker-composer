#!/bin/bash

# Script to customize wp-config.php based on environment variables
# This script reads .env variables and configures debug settings appropriately

set -e

WP_CONFIG_FILE="/var/www/html/wp-config.php"

# Function to add or update a define in wp-config.php
update_wp_config_define() {
    local define_name="$1"
    local define_value="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        echo "wp-config.php not found, skipping configuration"
        return
    fi
    
    # Escape special characters for sed
    local escaped_value=$(echo "$define_value" | sed 's/[[\.*^$()+?{|]/\\&/g')
    
    # Check if the define already exists
    if grep -q "define.*'$define_name'" "$file"; then
        # Update existing define
        sed -i "s/define.*'$define_name'.*$/define('$define_name', $escaped_value);/" "$file"
        echo "Updated $define_name to $define_value"
    else
        # Add new define before the "That's all" comment
        sed -i "/\/\* That's all, stop editing/i define('$define_name', $escaped_value);" "$file"
        echo "Added $define_name with value $define_value"
    fi
}

# Wait for wp-config.php to be created by WordPress
echo "Waiting for wp-config.php to be created..."
timeout=60
while [ ! -f "$WP_CONFIG_FILE" ] && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
done

if [ ! -f "$WP_CONFIG_FILE" ]; then
    echo "wp-config.php not found after waiting, will create basic debug configuration"
    exit 0
fi

echo "Customizing wp-config.php debug settings..."

# Check if WORDPRESS_DEBUG is set to true
if [ "${WORDPRESS_DEBUG:-false}" = "true" ]; then
    echo "WordPress debug mode is enabled, configuring debug settings..."
    
    # Set WP_DEBUG to true
    update_wp_config_define "WP_DEBUG" "true" "$WP_CONFIG_FILE"
    
    # Set WP_DEBUG_DISPLAY to false (don't display errors on frontend)
    update_wp_config_define "WP_DEBUG_DISPLAY" "false" "$WP_CONFIG_FILE"
    
    # Set WP_DEBUG_LOG to true (log errors to file)
    update_wp_config_define "WP_DEBUG_LOG" "true" "$WP_CONFIG_FILE"
    
    # Enable script debugging
    update_wp_config_define "SCRIPT_DEBUG" "true" "$WP_CONFIG_FILE"
    
    # Set log file location
    update_wp_config_define "WP_DEBUG_LOG_FILE" "'/var/www/html/wp-content/debug.log'" "$WP_CONFIG_FILE"
    
    echo "Debug configuration completed - errors will be logged to wp-content/debug.log"
else
    echo "WordPress debug mode is disabled, setting safe production values..."
    
    # Disable all debug features
    update_wp_config_define "WP_DEBUG" "false" "$WP_CONFIG_FILE"
    update_wp_config_define "WP_DEBUG_DISPLAY" "false" "$WP_CONFIG_FILE"
    update_wp_config_define "WP_DEBUG_LOG" "false" "$WP_CONFIG_FILE"
    update_wp_config_define "SCRIPT_DEBUG" "false" "$WP_CONFIG_FILE"
fi

# Add some additional useful configurations
echo "Adding additional WordPress optimizations..."

# Memory limit (also set in PHP, but good to have in wp-config too)
update_wp_config_define "WP_MEMORY_LIMIT" "'512M'" "$WP_CONFIG_FILE"

# Increase max execution time for WordPress operations
update_wp_config_define "WP_MAX_EXECUTION_TIME" "300" "$WP_CONFIG_FILE"

# Enable automatic updates for minor versions
update_wp_config_define "WP_AUTO_UPDATE_CORE" "true" "$WP_CONFIG_FILE"

# Disable file editing from admin
update_wp_config_define "DISALLOW_FILE_EDIT" "true" "$WP_CONFIG_FILE"

# Set proper file permissions
update_wp_config_define "FS_CHMOD_DIR" "0755" "$WP_CONFIG_FILE"
update_wp_config_define "FS_CHMOD_FILE" "0644" "$WP_CONFIG_FILE"

echo "wp-config.php customization completed successfully!"