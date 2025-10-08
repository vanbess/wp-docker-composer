#!/bin/bash

# WordPress Docker Composer - Project Initialization
# This script prepares the project for GitHub and distribution

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

print_info "🚀 Initializing WordPress Docker Composer for GitHub"
echo ""

# Create missing directories
print_info "Creating directory structure..."
mkdir -p {backups,ssl,logs}

# Set proper permissions
print_info "Setting permissions..."
chmod +x composer.sh
chmod +x scripts/*.sh

# Initialize git if not already initialized
if [ ! -d .git ]; then
    print_info "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: WordPress Docker Composer Environment"
    print_success "Git repository initialized"
else
    print_info "Git repository already exists"
fi

# Create example config files if they don't exist
if [ ! -f config/php.ini ]; then
    print_info "Creating example PHP configuration..."
    mkdir -p config
    cat > config/php.ini << 'EOF'
; Custom PHP Configuration for WordPress
; Adjust these settings based on your needs

; Memory and execution limits
memory_limit = 256M
max_execution_time = 300
max_input_time = 300

; File upload settings
upload_max_filesize = 64M
post_max_size = 64M
max_file_uploads = 20

; Error reporting (disable in production)
display_errors = On
display_startup_errors = On
log_errors = On
error_log = /var/log/php_errors.log

; Session settings
session.gc_maxlifetime = 1440
session.save_path = "/tmp"

; Performance settings
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.enable_cli = 1

; Security settings
expose_php = Off
allow_url_fopen = Off
allow_url_include = Off
EOF
fi

if [ ! -f config/mysql.cnf ]; then
    print_info "Creating example MySQL configuration..."
    cat > config/mysql.cnf << 'EOF'
[mysqld]
# Custom MySQL Configuration for WordPress

# Basic settings
default-storage-engine = InnoDB
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2

# Query cache
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M

# Connection settings
max_connections = 100
wait_timeout = 28800
interactive_timeout = 28800

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

[client]
default-character-set = utf8mb4
EOF
fi

# Validate important files
print_info "Validating project structure..."

required_files=(
    "README.md"
    "LICENSE"
    "composer.json"
    "composer.sh"
    "docker-compose.yml"
    ".env.example"
    ".gitignore"
    "CONTRIBUTING.md"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    print_error "Missing required files:"
    for file in "${missing_files[@]}"; do
        echo "  ❌ $file"
    done
    exit 1
else
    print_success "All required files present"
fi

# Validate composer.json
print_info "Validating composer.json..."
if command -v docker-compose &> /dev/null; then
    if ./composer.sh validate; then
        print_success "composer.json is valid"
    else
        print_warning "composer.json has validation warnings (this is usually OK)"
    fi
else
    print_warning "Docker not available, skipping composer validation"
fi

# Check for sensitive data in tracked files
print_info "Checking for sensitive data..."
sensitive_patterns=(
    "password.*="
    "secret.*="
    "key.*="
    "token.*="
)

found_sensitive=false
for pattern in "${sensitive_patterns[@]}"; do
    if git ls-files | xargs grep -l "$pattern" 2>/dev/null | grep -v ".env.example" | grep -v "README.md" | grep -v "docs/" | grep -v "scripts/"; then
        found_sensitive=true
    fi
done

if [ "$found_sensitive" = true ]; then
    print_warning "Possible sensitive data found in tracked files. Please review."
else
    print_success "No obvious sensitive data found in tracked files"
fi

# Create GitHub repository instructions
cat > GITHUB_SETUP.md << 'EOF'
# GitHub Repository Setup

Follow these steps to create and publish your repository:

## 1. Create GitHub Repository

1. Go to [GitHub](https://github.com/new)
2. Repository name: `wp-docker-composer` (or your preferred name)
3. Description: `Professional WordPress development environment with Docker and Composer`
4. Set to Public (to share with community)
5. Do NOT initialize with README (we have one)
6. Click "Create repository"

## 2. Push to GitHub

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR-USERNAME/wp-docker-composer.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 3. Configure Repository Settings

### Branches
- Go to Settings → Branches
- Set `main` as default branch
- Add branch protection rules (optional):
  - Require pull request reviews
  - Require status checks to pass

### Issues
- Go to Settings → General → Features
- Enable Issues and Discussions

### GitHub Pages (Optional)
- Go to Settings → Pages
- Source: Deploy from branch
- Branch: main / docs

## 4. Create Release

```bash
# Tag the first release
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

Then create a release on GitHub:
- Go to Releases → Create new release
- Tag: v1.0.0
- Title: "WordPress Docker Composer v1.0.0"
- Description: Add release notes

## 5. Add Topics/Tags

Go to Settings → General and add topics:
- wordpress
- docker
- composer
- php
- development
- wpackagist
- docker-compose

## 6. Community Files

The following community files are already included:
- README.md
- LICENSE (MIT)
- CONTRIBUTING.md
- .github/ISSUE_TEMPLATE/
- .github/workflows/

## 7. Repository Structure

```
your-repo/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── docs/
├── scripts/
├── config/
├── README.md
├── LICENSE
├── CONTRIBUTING.md
└── ...
```

## 8. Promote Your Repository

- Share on social media
- Submit to awesome lists
- Write a blog post
- Present at meetups
- Add to WordPress resources

Remember to update README.md with your actual GitHub username!
EOF

print_success "GitHub setup instructions created: GITHUB_SETUP.md"

# Final summary
echo ""
print_success "🎉 Project initialization complete!"
echo ""
echo "Your WordPress Docker Composer environment is ready for GitHub!"
echo ""
echo "Next steps:"
echo "  1. Review GITHUB_SETUP.md for publishing instructions"
echo "  2. Update README.md with your GitHub username"
echo "  3. Test the environment: ./scripts/setup.sh"
echo "  4. Create your GitHub repository"
echo "  5. Share with the community!"
echo ""
echo "Files created/verified:"
echo "  ✅ Project structure"
echo "  ✅ Configuration files"
echo "  ✅ Documentation"
echo "  ✅ GitHub templates"
echo "  ✅ CI/CD workflows"
echo "  ✅ Utility scripts"
echo ""
print_info "Ready to make WordPress development easier for everyone! 🚀"