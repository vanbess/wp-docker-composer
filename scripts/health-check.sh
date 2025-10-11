#!/bin/bash

# Simple health check script for CI environments
# This verifies that WordPress can start without waiting for customizations

set -e

# Wait for WordPress to respond on port 80 (internal)
echo "Checking WordPress health..."

max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:80 >/dev/null 2>&1; then
        echo "✅ WordPress is responding successfully!"
        exit 0
    fi
    
    echo "Attempt $attempt/$max_attempts: WordPress not ready yet..."
    sleep 2
    attempt=$((attempt + 1))
done

echo "❌ WordPress failed to respond after $max_attempts attempts"
exit 1