# Must-Use Plugins (MU-Plugins)

This directory contains WordPress Must-Use Plugins that are automatically loaded and cannot be deactivated through the WordPress admin interface.

## 📦 Available Plugins

### 🚫 Custom Error Filter
**File**: `custom-error-filter.php`

Prevents debug log spam by filtering duplicate PHP notices, warnings, and deprecated messages. Each unique error is only logged once per 24 hours (configurable).

**Features**:
- ✅ Duplicate message prevention
- ✅ Configurable error type filtering  
- ✅ Pattern-based blacklist/whitelist
- ✅ Automatic cache cleanup
- ✅ WP-CLI integration for statistics

### ⚙️ Error Filter Configuration
**File**: `error-filter-config.php`

Configuration file for the Custom Error Filter. Modify settings here to customize filtering behavior.

**Configuration Options**:
- Cache duration (default: 24 hours)
- Error types to filter (notices, warnings, deprecated)
- Maximum cache entries
- Custom regex patterns for blacklist/whitelist
- Debug mode toggle

## 🚀 Deployment

### Automatic Deployment
Run the deployment script to copy mu-plugins to your WordPress installation:

```bash
./scripts/deploy-mu-plugins.sh
```

### Manual Deployment
```bash
# Copy files to WordPress mu-plugins directory
cp mu-plugins/*.php wp_data/wp-content/mu-plugins/

# Set proper permissions
./scripts/set-dev-permissions.sh
```

## 🔧 Configuration

### Error Filter Settings

Edit `error-filter-config.php` to customize:

```php
// Cache duration (seconds)
define('ERROR_FILTER_CACHE_DURATION', 24 * 60 * 60); // 24 hours

// Enable/disable filtering by error type
define('ERROR_FILTER_NOTICES', true);      // Filter notices
define('ERROR_FILTER_WARNINGS', true);     // Filter warnings  
define('ERROR_FILTER_DEPRECATED', true);   // Filter deprecated

// Custom patterns to always filter (regex)
$ERROR_FILTER_BLACKLIST = array(
    '/Function _load_textdomain_just_in_time was called.*incorrectly/',
    '/Translation loading for the.*domain was triggered too early/',
);

// Patterns to never filter (always log)
$ERROR_FILTER_WHITELIST = array(
    '/Fatal error/',
    '/Parse error/',
    '/Call to undefined function/',
);
```

## 📊 Monitoring

### View Filter Statistics (WP-CLI)
```bash
# Inside WordPress container
docker compose exec wordpress wp error-filter-stats
```

### Check Cache File
The error filter creates a cache file at `wp-content/debug-cache.json` to track logged messages.

## 🔍 Troubleshooting

### Error Filter Not Working
1. **Check file permissions**: MU-plugins need to be readable by the web server
2. **Verify file location**: Files must be in `wp-content/mu-plugins/` (not subdirectories)
3. **Check WordPress debug settings**: Ensure `WP_DEBUG_LOG` is enabled
4. **Review cache file**: Check if `wp-content/debug-cache.json` is being created and updated

### Debug Mode
Enable debug mode in `error-filter-config.php`:
```php
define('ERROR_FILTER_DEBUG', true);
```

This will log filter activity for troubleshooting.

## 📁 File Structure
```
mu-plugins/
├── custom-error-filter.php     # Main error handler
├── error-filter-config.php     # Configuration settings
└── README.md                   # This documentation
```

## 🔄 Updates

When updating the repository:
1. Modify files in the `mu-plugins/` directory
2. Run `./scripts/deploy-mu-plugins.sh` to deploy changes
3. Test in your development environment
4. Commit changes to the repository

## ⚠️ Important Notes

- **Must-Use Plugins** are loaded before regular plugins and themes
- They **cannot be deactivated** through the WordPress admin
- They are loaded in **alphabetical order** by filename
- Use them for **critical functionality** that should always be active
- Changes require **file-level modifications** (no admin interface)