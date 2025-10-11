#!/bin/bash

# Custom Docker entrypoint for WordPress with configuration customization
# This script runs the original WordPress entrypoint and then customizes wp-config.php

set -e

# Source the original WordPress entrypoint
source /usr/local/bin/docker-entrypoint.sh

# Function to run our customizations
run_customizations() {
    echo "Running WordPress customizations..."
    
    # Wait a bit for WordPress to fully initialize
    sleep 5
    
    # Run permissions setup first
    if [ -x "/usr/local/bin/fix-permissions.sh" ]; then
        echo "Setting up WordPress permissions..."
        /usr/local/bin/fix-permissions.sh auto
    fi
    
    # Run wp-config customization in the background
    if [ -x "/usr/local/bin/customize-wp-config.sh" ]; then
        echo "Running wp-config.php customization..."
        /usr/local/bin/customize-wp-config.sh &
    fi
    
    echo "Customizations started"
}

# If this is the main Apache process (PID 1), run customizations
if [ $$ -eq 1 ] && [ "$1" = "apache2-foreground" ]; then
    # Start customizations in background
    run_customizations &
fi

# Execute the original command
exec "$@"