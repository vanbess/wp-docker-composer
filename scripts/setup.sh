#!/bin/bash

# Quick setup script for new installations
# This script automates the initial setup process

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

print_info "🚀 WordPress Docker Composer Setup"
echo "This script will help you set up your WordPress development environment."
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Prerequisites check passed!"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_info "Creating .env file from template..."
    cp .env.example .env
    
    # Generate random passwords
    if command -v openssl &> /dev/null; then
        root_pass=$(openssl rand -base64 32)
        wp_pass=$(openssl rand -base64 32)
        admin_pass=$(openssl rand -base64 16)
        
        sed -i "s/change_this_secure_root_password/$root_pass/g" .env
        sed -i "s/change_this_secure_password/$wp_pass/g" .env
        sed -i "s/change_this_admin_password/$admin_pass/g" .env
        
        print_success "Generated secure random passwords"
    else
        print_warning "OpenSSL not found. Please manually edit .env file with secure passwords."
    fi
else
    print_info ".env file already exists, skipping creation."
fi

# Get user preferences
echo ""
print_info "Configuration options:"

read -p "Project name (default: wp-docker-composer): " project_name
project_name=${project_name:-wp-docker-composer}
sed -i "s/COMPOSE_PROJECT_NAME=.*/COMPOSE_PROJECT_NAME=$project_name/g" .env

read -p "WordPress port (default: 8000): " wp_port
wp_port=${wp_port:-8000}
sed -i "s/WORDPRESS_PORT=.*/WORDPRESS_PORT=$wp_port/g" .env

read -p "phpMyAdmin port (default: 8080): " pma_port
pma_port=${pma_port:-8080}
sed -i "s/PHPMYADMIN_PORT=.*/PHPMYADMIN_PORT=$pma_port/g" .env

read -p "Admin email: " admin_email
if [ ! -z "$admin_email" ]; then
    sed -i "s/WP_ADMIN_EMAIL=.*/WP_ADMIN_EMAIL=$admin_email/g" .env
fi

read -p "Site title (default: My WordPress Site): " site_title
site_title=${site_title:-My WordPress Site}
sed -i "s/WP_TITLE=.*/WP_TITLE=$site_title/g" .env

# Start services
echo ""
print_info "Starting Docker services..."
docker-compose up -d

# Wait for services
print_info "Waiting for services to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    if docker-compose ps | grep -q "Up.*healthy.*Up.*healthy"; then
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    print_warning "Services may still be starting. Check with: docker-compose ps"
else
    print_success "Services are ready!"
fi

# Install dependencies
print_info "Installing Composer dependencies..."
./composer.sh install

# Run diagnostics
print_info "Running system diagnostics..."
./composer.sh doctor

echo ""
print_success "🎉 Setup complete!"
echo ""
echo "Your WordPress site is available at:"
echo "  💻 WordPress: http://localhost:$wp_port"
echo "  🗄️  phpMyAdmin: http://localhost:$pma_port"
echo ""
echo "Next steps:"
echo "  1. Visit your WordPress site and complete the installation"
echo "  2. Install additional plugins: ./composer.sh plugin install plugin-name"
echo "  3. Install themes: ./composer.sh theme install theme-name"
echo "  4. Use WP-CLI: ./composer.sh wp --help"
echo ""
echo "For help: ./composer.sh help"
echo ""

# Optional: Open browser
if command -v xdg-open &> /dev/null; then
    read -p "Open WordPress site in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "http://localhost:$wp_port"
    fi
elif command -v open &> /dev/null; then
    read -p "Open WordPress site in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "http://localhost:$wp_port"
    fi
fi