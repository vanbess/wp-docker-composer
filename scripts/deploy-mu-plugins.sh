#!/bin/bash

# Deploy MU-Plugins Script
# Copies must-use plugins from the repository to the WordPress installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WP_DATA_DIR="$REPO_ROOT/wp_data"
MU_PLUGINS_SOURCE="$REPO_ROOT/mu-plugins"
MU_PLUGINS_DEST="$WP_DATA_DIR/wp-content/mu-plugins"

echo "Deploying Must-Use Plugins..."
echo "Source: $MU_PLUGINS_SOURCE"
echo "Destination: $MU_PLUGINS_DEST"

# Check if wp_data directory exists
if [ ! -d "$WP_DATA_DIR" ]; then
    echo "Error: WordPress data directory not found: $WP_DATA_DIR"
    echo "Please run the WordPress setup first."
    exit 1
fi

# Create mu-plugins directory if it doesn't exist
if [ ! -d "$MU_PLUGINS_DEST" ]; then
    echo "Creating mu-plugins directory..."
    mkdir -p "$MU_PLUGINS_DEST"
fi

# Copy all PHP files from repository mu-plugins to WordPress mu-plugins
if [ -d "$MU_PLUGINS_SOURCE" ]; then
    echo "Copying mu-plugins files..."
    cp -v "$MU_PLUGINS_SOURCE"/*.php "$MU_PLUGINS_DEST/" 2>/dev/null || {
        echo "No PHP files found in $MU_PLUGINS_SOURCE"
    }
    
    # Set proper permissions
    if command -v "$REPO_ROOT/scripts/set-dev-permissions.sh" &> /dev/null; then
        echo "Setting proper permissions..."
        "$REPO_ROOT/scripts/set-dev-permissions.sh"
    else
        echo "Setting basic permissions..."
        chmod 664 "$MU_PLUGINS_DEST"/*.php 2>/dev/null || true
        # Use www-data:www-data by default (or wpdev group if available)
        chown www-data:www-data "$MU_PLUGINS_DEST"/*.php 2>/dev/null || true
    fi
    
    echo "✅ Must-Use Plugins deployed successfully!"
    echo ""
    echo "Deployed plugins:"
    ls -la "$MU_PLUGINS_DEST"/*.php 2>/dev/null || echo "No plugins found"
else
    echo "❌ Source directory not found: $MU_PLUGINS_SOURCE"
    exit 1
fi

echo ""
echo "🔧 Available MU-Plugins:"
echo "- Custom Error Filter: Prevents debug log spam by filtering duplicate notices/warnings"
echo "- Error Filter Config: Configuration file for customizing error filtering behavior"
echo ""
echo "📝 Note: These plugins are automatically loaded by WordPress and cannot be deactivated from the admin."