# WordPress Docker Permissions Solution

## 🎯 Problem Solved

This solution eliminates the classic Docker permissions dilemma where:
- ❌ **WordPress-friendly permissions** → Can't edit files from host
- ❌ **Host-friendly permissions** → WordPress can't write files

## ✅ Our Solution: Shared Group Approach

### How It Works

1. **Shared Group**: Creates a `wpdev` group (GID 1000) that both users belong to
2. **User Mapping**: Maps your host user (UID 1000) into the container 
3. **Smart Permissions**: Uses 775/664 permissions with group write access
4. **Sticky Bit**: Ensures new files inherit the correct group

### Result: Both Happy! 🎉

- ✅ **WordPress/www-data** can read/write all files
- ✅ **Host user** can edit files directly with IDE/editor
- ✅ **Git operations** work seamlessly
- ✅ **File uploads** through WordPress admin work
- ✅ **Plugin/theme installation** through admin works

## 🔧 Technical Implementation

### Container Setup

The Dockerfile creates:
```bash
# Create shared group
groupadd -g 1001 wpdev
usermod -a -G wpdev www-data

# Map host user (if different from www-data)
useradd -u ${HOST_UID} -g ${HOST_GID} -m hostuser
usermod -a -G wpdev hostuser
```

### Permission Structure

```
wp-content/
├── Owner: www-data (WordPress needs this)
├── Group: wpdev (shared access)
├── Permissions: 775 (dirs) / 664 (files)
└── Sticky bit: Set (new files inherit group)
```

### Environment Variables

In `.env`:
```bash
HOST_UID=1000  # Your user ID
HOST_GID=1000  # Your group ID
```

## 🚀 Usage

### Automatic Setup

```bash
# Auto-detect and configure your user IDs
./scripts/setup-user-mapping.sh

# Build with user mapping
docker compose build

# Start containers
docker compose up -d
```

### Manual Permission Fix

```bash
# If needed, manually fix permissions
./composer.sh fix-permissions
```

## 🔒 Development vs Production

### Development Mode (`WORDPRESS_DEBUG=true`)
- More permissive permissions for easier development
- Group write access enabled
- Host user can freely edit files

### Production Mode (`WORDPRESS_DEBUG=false`)
- Security-focused permissions
- Restricted file access
- WordPress functionality preserved

## 🛠️ Commands

### Check Permissions
```bash
# View wp-content permissions
ls -la wp_data/wp-content/

# Check groups in container
docker compose exec wordpress groups www-data
```

### Fix Permissions
```bash
# Intelligent fix (auto-detects dev/prod)
docker compose exec wordpress /usr/local/bin/fix-permissions.sh auto

# Force development mode
docker compose exec wordpress /usr/local/bin/fix-permissions.sh dev

# Force production mode  
docker compose exec wordpress /usr/local/bin/fix-permissions.sh prod
```

### Test Write Access
```bash
# Test host user write
echo "test" > wp_data/wp-content/test.txt

# Test WordPress write
docker compose exec wordpress touch /var/www/html/wp-content/wp-test.txt

# Both should work without errors
```

## 📁 File Structure

```
wp_data/wp-content/
├── owner: www-data
├── group: wpdev (shared group or local user via Docker mapping)
├── permissions: drwxrwsr-x (775 with sticky bit)
└── files: -rw-rw-r-- (664)
```

## 🔍 Troubleshooting

### Permission Denied Errors

````
# Re-run permissions script
./composer.sh fix-permissions

# Or manually in container
docker compose exec wordpress /usr/local/bin/fix-permissions.sh dev
```

### User Mapping Issues

```bash
# Check your user ID
id

# Update .env with correct values
echo "HOST_UID=$(id -u)" >> .env
echo "HOST_GID=$(id -g)" >> .env

# Rebuild container
docker compose build --no-cache
```

### WordPress Can't Write

```bash
# Check if www-data is in wpdev group
docker compose exec wordpress groups www-data

# Should show: www-data wpdev

# If not, rebuild the container
docker compose build
```

## 🏆 Benefits

1. **Seamless Development**: Edit files directly with your IDE
2. **WordPress Functionality**: All admin features work (uploads, plugins, themes)
3. **Security**: Production mode maintains secure permissions  
4. **Git Friendly**: No permission conflicts with version control
5. **Cross-Platform**: Works on Linux, macOS, and Windows (WSL)

## ⚡ Quick Start

```bash
# 1. Clone/update repo with new files
git pull

# 2. Auto-configure user mapping
./scripts/setup-user-mapping.sh

# 3. Build and start
docker compose down
docker compose build
docker compose up -d

# 4. Verify permissions
./composer.sh fix-permissions

# 5. Test it works
echo "I can edit this!" > wp_data/wp-content/test.txt
```

You're all set! 🎉