#!/bin/bash

# WordPress Docker Environment Initialization Script
# This script sets up a WordPress Docker environment with proper permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_info "🚀 Initializing WordPress Docker Environment..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please create one from .env.example"
    exit 1
fi

# Start containers
print_info "Starting Docker containers..."
docker compose up -d

# Wait for containers to be ready
print_info "Waiting for containers to be fully ready..."
sleep 10

# Wait for WordPress to respond
print_info "Waiting for WordPress to be accessible..."
for i in {1..30}; do
    if docker compose exec -T wordpress curl -f http://localhost >/dev/null 2>&1; then
        print_success "WordPress is responding!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "WordPress may not be fully ready yet, continuing anyway..."
    fi
    sleep 2
done

# Fix permissions using our composer script
print_info "Setting up proper file permissions..."
./composer.sh fix-permissions

# Install Composer dependencies if composer.json exists
if [ -f "composer.json" ]; then
    print_info "Installing Composer dependencies..."
    ./composer.sh install
fi

print_success "🎉 WordPress Docker environment is ready!"
print_info ""
print_info "📋 What's been set up:"
print_info "  ✓ Docker containers started and healthy"
print_info "  ✓ File permissions configured for www-data"
print_info "  ✓ WordPress uploads directory ready"
print_info "  ✓ Composer dependencies installed"
print_info ""
print_info "🔗 Access your site:"
WORDPRESS_PORT=$(grep WORDPRESS_PORT .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
print_info "  WordPress: http://localhost:${WORDPRESS_PORT:-8080}"
MYSQL_PORT=$(grep MYSQL_PORT .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
print_info "  phpMyAdmin: http://localhost:$((${MYSQL_PORT:-3306} + 1000))"
print_info ""
print_info "🛠️  Useful commands:"
print_info "  ./composer.sh plugin install <plugin-name>     - Install WordPress plugins"
print_info "  ./composer.sh theme install <theme-name>       - Install WordPress themes"
print_info "  ./composer.sh fix-permissions                  - Fix file permissions"
print_info "  ./composer.sh wp <command>                     - Run WP-CLI commands"
print_info "  ./composer.sh doctor                           - Check system health"
print_info ""
print_success "Happy WordPressing! 🎯"