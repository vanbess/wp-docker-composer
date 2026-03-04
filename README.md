# WordPress Docker Composer Environment

A modern, professional WordPress development environment using Docker, Composer, and WPackagist for streamlined plugin and theme management.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Composer](https://img.shields.io/badge/Composer-885630?style=for-the-badge&logo=composer&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [Common Issues & Troubleshooting](#️-common-issues--troubleshooting)
- [Features](#-features)
- [Architecture](#️-architecture)
- [Automatic Permission Management](#-automatic-permission-management)
- [Plugin & Theme Management](#-plugin--theme-management)
- [Development Tools](#️-development-tools)
- [Error Filtering & Debug Management](#-error-filtering--debug-management)
- [Must-Use Plugins](#-must-use-plugins)
- [Backup & Restore](#-backup--restore)
- [WP-CLI Commands](#wp-cli-commands)
- [Popular Packages](#popular-packages)
- [Environment Variables](#environment-variables)
- [Advanced Troubleshooting](#advanced-troubleshooting)

## � Quick Start

```bash
# Clone the repository
git clone https://github.com/vanbess/wp-docker-composer.git
cd wp-docker-composer

# Copy environment file and customize
cp .env.example .env

# Build containers (required for first-time setup)
docker compose build

# Initialize the environment (automatic setup)
./init-wordpress.sh

# Or start manually
docker compose up -d
./composer.sh install

# Access your site
open http://localhost:8111
```

## ⚠️ Common Issues & Troubleshooting

### First-Time Setup Issues

#### Permission Script Not Found Error

If you see an error like:

```bash
OCI runtime exec failed: exec failed: unable to start container process: exec: "/usr/local/bin/fix-permissions.sh": stat /usr/local/bin/fix-permissions.sh: no such file or directory: unknown
```

**Solution:**

```bash
# Rebuild the WordPress container
docker compose build --no-cache wordpress

# Recreate the container with the new image
docker compose down wordpress
docker compose up -d wordpress

# Test that it's working
./composer.sh install
```

#### WP-CLI Commands Hanging

If plugin/theme removal commands hang at the "Running WP-CLI command with timeout" step:

**Solution:**

```bash
# Force stop any hanging containers
docker compose --profile tools down

# Try the force-remove option instead
./composer.sh plugin force-remove plugin-name
```

#### Git Ownership Warnings

If you see warnings like:

```bash
The repository at "/app" does not have the correct ownership and git refuses to use it:
fatal: detected dubious ownership in repository at '/app'
```

This is automatically resolved in the latest version. If you still see this warning, ensure your containers are up to date:

**Solution:**

```bash
# Rebuild composer service
docker compose build composer

# Fix file ownership if needed
sudo chown -R $USER:$USER composer.* vendor/
```

#### Container Build Issues

If this is your first time running the project or you've pulled recent updates:

**Solution:**

```bash
# Always run this for first-time setup or after pulling updates
docker compose build

# Then proceed with normal startup
docker compose up -d
./composer.sh install
```

### Quick Fixes

#### File Permission Issues

If you can't update plugins/themes through WordPress admin:

```bash
# Fix file permissions
./composer.sh fix-permissions

# Permissions are also auto-fixed after Composer operations
```

#### Reset Everything

```bash
# Stop containers and remove volumes
docker compose down -v

# Remove vendor directory
rm -rf vendor/

# Rebuild containers from scratch
docker compose build --no-cache

# Start fresh
docker compose up -d
./composer.sh install
```

## ✨ Features

- **🐳 Docker-based**: Isolated, reproducible development environment
- **📦 Composer Integration**: Professional dependency management with WPackagist
- **🛠️ Management Script**: Easy-to-use CLI for plugin/theme operations
- **🔧 Auto-Permissions**: Automatic file permission fixes for Docker environments
- **🔄 Version Control**: Pin, upgrade, downgrade plugins and themes with ease
- **⚡ Fast Setup**: Get running in under 5 minutes with automatic initialization
- **🛡️ Robust Error Handling**: Timeout protection and graceful fallbacks
- **🔍 Diagnostics**: Built-in health checks and troubleshooting
- **📧 Local Email Capture**: Mailpit inbox for safe WordPress email testing
- **📚 Comprehensive Documentation**: Detailed guides and examples
- **✅ Works Out of the Box**: No manual permission fixes needed (after initial container build)

## 🏗️ Architecture

### Services

- **WordPress** (6.8 + PHP 8.3 + Apache)
- **MariaDB** (10.11) - Fast, reliable database
- **phpMyAdmin** - Database management interface
- **Mailpit** - Local SMTP capture and web inbox for outgoing emails
- **Composer** - Dependency management
- **WP-CLI** - WordPress command-line tools

### Email Testing

WordPress outbound mail is routed to the local Mailpit SMTP service.

```bash
# Open the captured inbox UI by visiting this URL in your browser:
# http://localhost:8025

# Send a test email from WordPress
./composer.sh wp eval 'wp_mail("dev@example.test", "Mail test", "Email transport is working.")'
```

If the message appears in Mailpit, your WordPress instance is successfully sending email.

### Directory Structure

```bash
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

## 🛠️ Development Tools

### Permission Management Script

For development environments, use the enhanced permission script that provides full read/write access:

```bash
# Set development-friendly permissions
./scripts/set-dev-permissions.sh
```

**Features:**

- ✅ Full read/write permissions (775/664) for development work
- ✅ Special handling for log files (666) and cache directories (777)
- ✅ Proper ownership (www-data:local-user via group permissions)
- ✅ You can edit, save, and clear debug.log and other files

**vs Standard Permissions:**

- Standard: `scripts/fix-permissions.sh` (production-ready, more restrictive)
- Development: `scripts/set-dev-permissions.sh` (full access for dev work)

### Deploy Must-Use Plugins

Deploy essential mu-plugins for enhanced debugging and error handling:

```bash
# Deploy all mu-plugins to WordPress
./scripts/deploy-mu-plugins.sh
```

This automatically copies and configures:

## � Backup & Restore

Create and restore full backups of your WordPress installation, including database, files, and configuration. Perfect for recovering from breaking changes.

### Creating Backups

```bash
# Create a backup (includes database, WordPress files, and configuration)
./scripts/backup.sh create

# List all available backups
./scripts/backup.sh list
```

**What's Included:**

- Database (all tables, triggers, routines)
- WordPress files (wp_data directory)
- Configuration files (.env, composer.json, docker-compose.yml)
- Backup metadata (creation date, git branch/commit, hostname)

### Restoring from Backup

```bash
# List available backups to find the right one
./scripts/backup.sh list

# Restore from a specific backup
./scripts/backup.sh restore backups/myproject_20241025_120000.tar.gz
```

⚠️ **Warning:** Restoring will overwrite your current WordPress installation and database. Always verify you have the correct backup before proceeding.

### Backup Management

```bash
# Clean up backups older than 30 days (frees disk space)
./scripts/backup.sh cleanup 30

# Clean up backups older than 7 days
./scripts/backup.sh cleanup 7

# Show full help and examples
./scripts/backup.sh help
```

**Best Practices:**

- Create backups **before making major changes** (plugin/theme updates, permissions changes, etc.)
- Run cleanup periodically to manage disk space
- Keep important backups on external storage for safety
- Always verify a restore worked on a test environment first

## �🚫 Error Filtering & Debug Management

The repository includes a sophisticated error filtering system to prevent debug log spam while maintaining visibility into real issues.

### Features

- **🔄 Duplicate Prevention**: Same error messages logged only once per 24 hours
- **⚙️ Configurable Filtering**: Filter notices, warnings, and deprecated messages  
- **🎯 Pattern Matching**: Blacklist/whitelist specific error patterns
- **🧹 Automatic Cleanup**: Removes old cache entries automatically
- **📊 Statistics**: View filtering stats via WP-CLI

### Quick Setup

```bash
# Deploy the error filter system
./scripts/deploy-mu-plugins.sh

# Clear debug log to start fresh
echo "" > wp_data/wp-content/debug.log

# Set proper permissions
./scripts/set-dev-permissions.sh
```

### Configuration

Customize filtering behavior in `mu-plugins/error-filter-config.php`:

```php
# Cache duration (24 hours default)
define('ERROR_FILTER_CACHE_DURATION', 24 * 60 * 60);

# Enable/disable filtering by type
define('ERROR_FILTER_NOTICES', true);      # Filter notices
define('ERROR_FILTER_WARNINGS', true);     # Filter warnings  
define('ERROR_FILTER_DEPRECATED', true);   # Filter deprecated

# Custom patterns (regex)
$ERROR_FILTER_BLACKLIST = array(
    '/Function _load_textdomain_just_in_time was called.*incorrectly/',
    '/Translation loading for the.*domain was triggered too early/',
);
```

### Monitoring

```bash
# View filter statistics
docker compose exec wordpress wp error-filter-stats

# Check cache status
ls -la wp_data/wp-content/debug-cache.json

# Monitor debug log in real-time
tail -f wp_data/wp-content/debug.log

## 📦 Must-Use Plugins

Must-Use Plugins (mu-plugins) are automatically loaded WordPress plugins that cannot be deactivated through the admin interface. Perfect for essential functionality.

### Available MU-Plugins

| Plugin | Description | Auto-Deploy |
|--------|-------------|-------------|
| **Custom Error Filter** | Prevents debug log spam by filtering duplicate notices/warnings | ✅ |
| **Error Filter Config** | Configuration file for customizing error filtering behavior | ✅ |

### Repository Structure

```bash
mu-plugins/
├── custom-error-filter.php     # Main error handler
├── error-filter-config.php     # Configuration settings  
├── README.md                   # Detailed documentation
└── [your-plugin].php           # Add custom mu-plugins here

```

### Adding Custom MU-Plugins

1. **Add your plugin** to the `mu-plugins/` directory
2. **Deploy to WordPress**: `./scripts/deploy-mu-plugins.sh`
3. **Set permissions**: `./scripts/set-dev-permissions.sh`
4. **Commit to repository** for team sharing

### Key Benefits

- **🔒 Always Active**: Cannot be accidentally deactivated
- **⚡ Early Loading**: Loaded before regular plugins and themes
- **👥 Team Consistency**: Shared via repository across environments
- **🛠️ Developer Tools**: Perfect for debugging and development utilities

### Usage Examples

```bash
# Deploy all mu-plugins
./scripts/deploy-mu-plugins.sh

# Add custom mu-plugin
cp my-custom-plugin.php mu-plugins/
./scripts/deploy-mu-plugins.sh

# View deployed plugins
ls -la wp_data/wp-content/mu-plugins/
```

**Note**: MU-plugins are loaded alphabetically by filename. Prefix with numbers for load order control (e.g., `01-critical.php`, `02-utilities.php`).

```bash
- Custom Error Filter (prevents debug log spam)
- Error Filter Configuration (customizable settings)

## 📋 WP-CLI Commands

You can run any WP-CLI command using:
```bash
./composer.sh wp <command>

# Examples:
./composer.sh wp core version
./composer.sh wp user list
./composer.sh wp option get siteurl
./composer.sh wp db check
```

## Popular Packages

### Popular Plugins Available via WPackagist

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

### Popular Themes Available via WPackagist

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
- Mailpit ports (`MAILPIT_SMTP_PORT`, `MAILPIT_WEB_PORT`)
- Admin user details

## Advanced Troubleshooting

### View Logs

```bash
# WordPress logs
docker compose logs wordpress

# Database logs
docker compose logs db

# All logs
docker compose logs
```

### Access Container Shell

```bash
# WordPress container
docker compose exec wordpress bash

# Database container
docker compose exec db bash
```

### File Structure Reference

```bash
wp-docker-composer/
├── docker-compose.yml     # Docker services configuration
├── composer.json          # Composer dependencies
├── composer.sh           # Helper script for Composer operations
├── .env                  # Environment variables
├── wp_data/              # WordPress files
├── db_data/              # Database files
├── config/               # Configuration files
└── vendor/               # Composer packages (auto-generated)
```

---

**Need help?** Check the troubleshooting sections above or open an issue on GitHub.
