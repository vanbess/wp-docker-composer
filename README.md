# WordPress Docker Composer Environment

A modern, professional WordPress development environment using Docker, Composer, and WPackagist for streamlined plugin and theme management.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Composer](https://img.shields.io/badge/Composer-885630?style=for-the-badge&logo=composer&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/vanbess/wp-docker-composer.git
cd wp-docker-composer

# Copy environment file and customize
cp .env.example .env

# Initialize the environment (automatic setup)
./init-wordpress.sh

# Or start manually
docker-compose up -d
./composer.sh install

# Access your site
open http://localhost:8000
```

## ✨ Features

- **🐳 Docker-based**: Isolated, reproducible development environment
- **📦 Composer Integration**: Professional dependency management with WPackagist
- **🛠️ Management Script**: Easy-to-use CLI for plugin/theme operations
- **� Auto-Permissions**: Automatic file permission fixes for Docker environments
- **�🔄 Version Control**: Pin, upgrade, downgrade plugins and themes with ease
- **⚡ Fast Setup**: Get running in under 5 minutes with automatic initialization
- **🛡️ Robust Error Handling**: Timeout protection and graceful fallbacks
- **🔍 Diagnostics**: Built-in health checks and troubleshooting
- **📚 Comprehensive Documentation**: Detailed guides and examples
- **✅ Works Out of the Box**: No manual permission fixes needed

## 🏗️ Architecture

### Services
- **WordPress** (6.8 + PHP 8.3 + Apache)
- **MariaDB** (10.11) - Fast, reliable database
- **phpMyAdmin** - Database management interface
- **Composer** - Dependency management
- **WP-CLI** - WordPress command-line tools

### Directory Structure
```
wp-docker-composer/
├── docker-compose.yml          # Docker services configuration
├── composer.json              # Composer dependencies
├── composer.sh                # Management CLI script
├── init-wordpress.sh           # One-command initialization script
├── .env.example               # Environment template
├── wp_data/                   # WordPress installation
├── db_data/                   # Database files
├── config/                    # Configuration files
│   ├── php.ini               # PHP configuration
│   └── mysql.cnf             # MySQL configuration
├── docs/                     # Documentation
└── scripts/                  # Utility scripts
```

## 🔧 Automatic Permission Management

One of the biggest pain points in Docker WordPress setups is file permissions. This environment **handles permissions automatically**:

### What Gets Fixed Automatically
- **File Ownership**: All WordPress files owned by `www-data` (the web server user)
- **Directory Permissions**: Set to `755` (readable/executable by all, writable by owner)
- **File Permissions**: Set to `644` (readable by all, writable by owner)
- **Uploads Directory**: Fully writable for media uploads and plugin files
- **wp-config.php**: Properly secured but updatable

### When Permissions Are Fixed
- **Automatically**: After every Composer operation (install, require, remove, etc.)
- **On Startup**: When using `./composer.sh start` or `./init-wordpress.sh`
- **On Demand**: Run `./composer.sh fix-permissions` anytime

### Manual Permission Fixes
```bash
# Fix all WordPress file permissions
./composer.sh fix-permissions

# Start containers and auto-fix permissions
./composer.sh start

# Ensure everything is ready (containers + permissions)
./composer.sh ready
```

## 📦 Plugin & Theme Management

### Install Plugins
```bash
# Install a plugin from WPackagist
./composer.sh plugin install contact-form-7
./composer.sh plugin install yoast-seo
./composer.sh plugin install akismet

# Or use the full composer require command
./composer.sh require wpackagist-plugin/contact-form-7
```

### Install Themes
```bash
# Install a theme from WPackagist
./composer.sh theme install twentytwentyfour
./composer.sh theme install astra

# Or use the full composer require command
./composer.sh require wpackagist-theme/twentytwentyfour
```

### Activate/Deactivate Plugins and Themes
```bash
# Activate a plugin
./composer.sh plugin activate contact-form-7

# Deactivate a plugin
./composer.sh plugin deactivate contact-form-7

# Activate a theme
./composer.sh theme activate twentytwentyfour

# List all plugins
./composer.sh plugin list

# List all themes
./composer.sh theme list
```

### Update Dependencies
```bash
# Update all packages
./composer.sh update

# Check for outdated packages
./composer.sh outdated
```

### Remove Plugins/Themes
```bash
# Safe removal (recommended) - tries to deactivate first, has fallbacks
./composer.sh plugin remove contact-form-7

# Force removal - skips deactivation, removes immediately
./composer.sh plugin force-remove contact-form-7

# Remove a theme
./composer.sh theme remove twentytwentyfour
```

### Troubleshooting and Diagnostics
```bash
# Run comprehensive diagnostics
./composer.sh doctor

# Check container status, validate composer.json, show installed packages, etc.
```

**Note:** The safe removal method includes:
1. **Timeout protection**: WP-CLI commands timeout after 10 seconds
2. **Graceful fallbacks**: If deactivation fails, continues with removal
3. **Manual cleanup**: If Composer fails, attempts manual directory removal
4. **Error handling**: Clear feedback on each step

### Version Management
```bash
# Check available versions
./composer.sh plugin version wordfence
./composer.sh theme version twentytwentyfour

# Install specific version
./composer.sh plugin install wordfence 7.10.0
./composer.sh theme install twentytwentyfour 1.2.0

# Downgrade to specific version
./composer.sh plugin downgrade wordfence 7.9.0
./composer.sh theme downgrade twentytwentyfour 1.1.0

# Upgrade to latest version
./composer.sh plugin upgrade wordfence
./composer.sh theme upgrade twentytwentyfour

# Check current installed versions
./composer.sh show

# Check for outdated packages
./composer.sh outdated

# Get package information
./composer.sh info wpackagist-plugin/wordfence

# Check why a package is installed
./composer.sh why composer/installers
```

### Advanced Management
```bash
# Search for plugins/themes
./composer.sh plugin search security
./composer.sh theme search blog

# Check plugin/theme status
./composer.sh plugin status wordfence
./composer.sh theme status twentytwentyfour

# Validate composer.json
./composer.sh validate

# Clean and reinstall all dependencies
./composer.sh clean
```

## WP-CLI Commands

You can run any WP-CLI command using:
```bash
./composer.sh wp <command>

# Examples:
./composer.sh wp core version
./composer.sh wp user list
./composer.sh wp option get siteurl
./composer.sh wp db check
```

## Popular Plugins Available via WPackagist

- `contact-form-7` - Contact forms
- `yoast-seo` - SEO optimization
- `akismet` - Anti-spam
- `wordfence` - Security
- `jetpack` - All-in-one toolkit
- `elementor` - Page builder
- `woocommerce` - E-commerce
- `classic-editor` - Classic WordPress editor
- `duplicate-post` - Duplicate posts/pages
- `wp-super-cache` - Caching

## Popular Themes Available via WPackagist

- `twentytwentyfour` - Latest default theme
- `twentytwentythree` - Previous default theme
- `astra` - Lightweight theme
- `generatepress` - Fast theme
- `oceanwp` - Multi-purpose theme

## Environment Variables

Edit `.env` file to customize:
- Database credentials
- WordPress debug settings
- Port numbers
- Admin user details

## File Structure

```
wp-docker-paxi/
├── docker-compose.yml     # Docker services configuration
├── composer.json          # Composer dependencies
├── composer.sh           # Helper script for Composer operations
├── .env                  # Environment variables
├── wp_data/              # WordPress files
├── db_data/              # Database files
├── config/               # Configuration files
└── vendor/               # Composer packages (auto-generated)
```

## Troubleshooting

### File Permission Issues
If you can't update plugins/themes through WordPress admin:
```bash
# Fix file permissions
./composer.sh fix-permissions

# Permissions are also auto-fixed after Composer operations
```

### Reset Everything
```bash
# Stop containers and remove volumes
docker-compose down -v

# Remove vendor directory
rm -rf vendor/

# Start fresh
docker-compose up -d
./composer.sh install
```

### View Logs
```bash
# WordPress logs
docker-compose logs wordpress

# Database logs
docker-compose logs db

# All logs
docker-compose logs
```

### Access Container Shell
```bash
# WordPress container
docker-compose exec wordpress bash

# Database container
docker-compose exec db bash
```