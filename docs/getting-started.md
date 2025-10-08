# Getting Started Guide

This guide will help you set up your WordPress development environment using Docker and Composer.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (20.10 or later) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (2.0 or later) - Usually included with Docker Desktop
- **Git** - [Install Git](https://git-scm.com/downloads)

### Verify Installation
```bash
docker --version
docker-compose --version
git --version
```

## Step 1: Clone the Repository

```bash
git clone https://github.com/your-username/wp-docker-composer.git
cd wp-docker-composer
```

## Step 2: Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit the configuration (use your preferred editor)
nano .env
# or
code .env
```

### Important Settings to Change

1. **Database Passwords**: Change the default passwords
   ```bash
   MYSQL_ROOT_PASSWORD=your_secure_root_password
   MYSQL_PASSWORD=your_secure_wp_password
   ```

2. **WordPress Admin**: Set your admin credentials
   ```bash
   WP_ADMIN_USER=yourusername
   WP_ADMIN_PASSWORD=your_secure_admin_password
   WP_ADMIN_EMAIL=your-email@example.com
   ```

3. **Ports**: Adjust if you have conflicts
   ```bash
   WORDPRESS_PORT=8000        # WordPress site
   PHPMYADMIN_PORT=8080       # Database admin
   MYSQL_PORT=3366           # Database port
   ```

## Step 3: Start the Environment

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

You should see all services running:
- `db` (MariaDB)
- `wordpress` 
- `phpmyadmin`

## Step 4: Install Dependencies

```bash
# Install WordPress plugins and themes via Composer
./composer.sh install
```

This will install:
- Akismet (anti-spam)
- Contact Form 7 (contact forms)
- Classic Editor
- Query Monitor (development tool)
- Twenty Twenty-Four theme

## Step 5: Access Your Site

Open your browser and navigate to:

- **WordPress Site**: http://localhost:8000
- **phpMyAdmin**: http://localhost:8080
  - Username: `wpuser` (or your MYSQL_USER)
  - Password: (your MYSQL_PASSWORD)

## Step 6: Complete WordPress Setup

1. Follow the WordPress installation wizard
2. Or use WP-CLI for automated setup:
   ```bash
   ./composer.sh wp core install \
     --url=http://localhost:8000 \
     --title="My WordPress Site" \
     --admin_user=admin \
     --admin_password=your_password \
     --admin_email=your-email@example.com
   ```

## Next Steps

### Install Additional Plugins
```bash
# Search for plugins
./composer.sh plugin search security

# Install specific plugins
./composer.sh plugin install wordfence
./composer.sh plugin install yoast-seo
```

### Install Themes
```bash
# Install popular themes
./composer.sh theme install astra
./composer.sh theme install generatepress
```

### Development Tools
```bash
# Activate development plugins
./composer.sh plugin activate query-monitor

# Check WordPress status
./composer.sh wp core version
./composer.sh wp plugin list
```

## Troubleshooting

### Port Conflicts
If you get port conflicts, edit `.env` and change the ports:
```bash
WORDPRESS_PORT=8001
PHPMYADMIN_PORT=8081
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

### Container Issues
```bash
# Check logs
docker-compose logs wordpress
docker-compose logs db

# Restart services
docker-compose restart

# Full reset
docker-compose down -v
docker-compose up -d
```

### Permission Issues
```bash
# Fix WordPress file permissions
sudo chown -R www-data:www-data wp_data/
sudo chmod -R 755 wp_data/
```

### Database Connection Issues
```bash
# Run diagnostics
./composer.sh doctor

# Test database connection
./composer.sh wp db check
```

## Development Workflow

### Daily Development
```bash
# Start environment
docker-compose up -d

# Install new plugin
./composer.sh plugin install new-plugin

# Check for updates
./composer.sh outdated

# Work on your code...

# Stop environment (optional)
docker-compose stop
```

### Version Control
```bash
# Pin plugin versions for stability
./composer.sh plugin install wordfence 7.10.0

# Update all to latest
./composer.sh update

# Downgrade if needed
./composer.sh plugin downgrade wordfence 7.9.0
```

## Need Help?

- 📖 Check the [full documentation](../README.md)
- 🔍 Run diagnostics: `./composer.sh doctor`
- 🐛 [Report issues](https://github.com/your-username/wp-docker-composer/issues)
- 💬 [Join discussions](https://github.com/your-username/wp-docker-composer/discussions)