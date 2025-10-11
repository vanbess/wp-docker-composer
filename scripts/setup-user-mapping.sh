#!/bin/bash

# Auto-detect and set user/group IDs for development
# This script updates the .env file with the current user's UID/GID

set -e

# Get current user's UID and GID
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# Path to .env file
ENV_FILE=".env"

echo "🔍 Detected user ID: $CURRENT_UID"
echo "🔍 Detected group ID: $CURRENT_GID"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    if [ -f ".env.example" ]; then
        echo "📋 Creating .env from .env.example..."
        cp .env.example .env
    else
        echo "❌ No .env or .env.example file found!"
        exit 1
    fi
fi

# Update or add HOST_UID and HOST_GID in .env file
if grep -q "^HOST_UID=" "$ENV_FILE"; then
    # Update existing HOST_UID
    sed -i "s/^HOST_UID=.*/HOST_UID=$CURRENT_UID/" "$ENV_FILE"
    echo "✅ Updated HOST_UID to $CURRENT_UID"
else
    # Add HOST_UID
    echo "HOST_UID=$CURRENT_UID" >> "$ENV_FILE"
    echo "✅ Added HOST_UID=$CURRENT_UID"
fi

if grep -q "^HOST_GID=" "$ENV_FILE"; then
    # Update existing HOST_GID
    sed -i "s/^HOST_GID=.*/HOST_GID=$CURRENT_GID/" "$ENV_FILE"
    echo "✅ Updated HOST_GID to $CURRENT_GID"
else
    # Add HOST_GID
    echo "HOST_GID=$CURRENT_GID" >> "$ENV_FILE"
    echo "✅ Added HOST_GID=$CURRENT_GID"
fi

echo ""
echo "🎉 User mapping configured successfully!"
echo "💡 Your containers will now map your host user for seamless file permissions."
echo ""
echo "Next steps:"
echo "  1. docker compose down    # Stop existing containers"
echo "  2. docker compose build   # Rebuild with user mapping"
echo "  3. docker compose up -d   # Start with new permissions"