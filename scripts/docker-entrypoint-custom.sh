#!/bin/bash

# Custom Docker entrypoint for WordPress with configuration customization
# This script runs the original WordPress entrypoint and then customizes wp-config.php

set -e

# Function to run our customizations in the background
run_customizations() {
    echo "Running WordPress customizations..."
    
    # Wait for WordPress to be ready
    sleep 10
    
    # Only run customizations if this is a web server process
    if [ -f "/var/www/html/index.php" ]; then
        # Run permissions setup first (only if not in CI)
        if [ -x "/usr/local/bin/fix-permissions.sh" ] && [ -z "$CI" ]; then
            echo "Setting up WordPress permissions..."
            /usr/local/bin/fix-permissions.sh auto 2>/dev/null || echo "Permissions setup skipped"
        fi
        
        # Run wp-config customization in the background
        if [ -x "/usr/local/bin/customize-wp-config.sh" ]; then
            echo "Running wp-config.php customization..."
            /usr/local/bin/customize-wp-config.sh 2>/dev/null || echo "wp-config customization skipped"
        fi
    fi
    
    echo "Customizations completed"
}

# If this is the main Apache process (PID 1) and we're starting the web server
if [ $$ -eq 1 ] && [ "$1" = "apache2-foreground" ]; then
    # Start customizations in background after a delay
    (sleep 15 && run_customizations) &
fi

# Execute the original WordPress entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"