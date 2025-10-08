# Version Constraints Guide

This guide explains how to specify version constraints when installing or updating plugins and themes with Composer.

## Version Constraint Syntax

### Exact Version
```bash
./composer.sh plugin install wordfence 7.10.0
# Installs exactly version 7.10.0
```

### Caret Operator (^) - Compatible Updates
```bash
./composer.sh plugin install wordfence ^7.10.0
# Allows updates to 7.10.1, 7.11.0, etc., but not 8.0.0
# Equivalent to >=7.10.0 <8.0.0
```

### Tilde Operator (~) - Approximate Version
```bash
./composer.sh plugin install wordfence ~7.10.0
# Allows updates to 7.10.1, 7.10.2, etc., but not 7.11.0
# Equivalent to >=7.10.0 <7.11.0
```

### Range
```bash
./composer.sh require wpackagist-plugin/wordfence ">=7.5.0 <8.0.0"
# Allows any version from 7.5.0 up to (but not including) 8.0.0
```

### Wildcard
```bash
./composer.sh plugin install wordfence 7.*
# Allows any 7.x version (7.0.0, 7.10.0, 7.99.99)
```

### Latest
```bash
./composer.sh plugin install wordfence "*"
# or simply
./composer.sh plugin install wordfence
# Installs the latest stable version
```

## Common Use Cases

### Development/Testing Environments
For development, you might want to pin to specific versions to ensure consistency:
```bash
./composer.sh plugin install contact-form-7 5.8.3
./composer.sh theme install twentytwentyfour 1.3
```

### Production Environments
For production, you might want to allow patch updates but not minor/major updates:
```bash
./composer.sh plugin install wordfence ~7.10.0    # Only 7.10.x updates
./composer.sh plugin install akismet ^5.3.0       # 5.3.x and 5.4.x updates, but not 6.x
```

### Staging Environments
For staging, you might want to test upcoming versions:
```bash
./composer.sh plugin install wordfence ^8.0.0     # Latest 8.x version
```

## Version Information Commands

### Check Available Versions
```bash
./composer.sh version wpackagist-plugin/wordfence
./composer.sh plugin version wordfence             # Shorthand
```

### Check Currently Installed Versions
```bash
./composer.sh show                                 # All packages
./composer.sh show | grep wordfence               # Specific package
```

### Check for Outdated Packages
```bash
./composer.sh outdated                            # Show packages that can be updated
```

## Version Management Workflow

### 1. Check Current Version
```bash
./composer.sh show | grep wordfence
```

### 2. Check Available Versions
```bash
./composer.sh plugin version wordfence
```

### 3. Upgrade to Latest
```bash
./composer.sh plugin upgrade wordfence
```

### 4. Downgrade to Specific Version
```bash
./composer.sh plugin downgrade wordfence 7.5.0
```

### 5. Pin to Specific Version Range
```bash
./composer.sh require wpackagist-plugin/wordfence "~7.10.0"
```

## Tips and Best Practices

### 1. Use Caret (^) for Most Cases
The caret operator is usually the best choice as it allows bug fixes and compatible updates:
```bash
./composer.sh plugin install wordfence ^7.10.0
```

### 2. Pin Critical Plugins in Production
For security or critical functionality plugins, consider pinning to exact versions:
```bash
./composer.sh plugin install wordfence 7.10.0
```

### 3. Test Before Upgrading
Always test plugin updates in a staging environment first:
```bash
# In staging
./composer.sh plugin upgrade wordfence

# Test thoroughly, then apply to production with specific version
./composer.sh plugin install wordfence 8.1.0
```

### 4. Keep Track of Updates
Regularly check for outdated packages:
```bash
./composer.sh outdated
```

### 5. Use Semantic Versioning Understanding
- **Major version** (8.0.0): Breaking changes
- **Minor version** (7.11.0): New features, backward compatible
- **Patch version** (7.10.1): Bug fixes, backward compatible

## Emergency Rollback

If an update breaks something, you can quickly rollback:

```bash
# Check what version you had
git log composer.lock  # If using git

# Or downgrade to a known good version
./composer.sh plugin downgrade wordfence 7.9.0

# Or remove and reinstall specific version
./composer.sh plugin remove wordfence
./composer.sh plugin install wordfence 7.9.0
```

## Version Constraints in composer.json

You can also manually edit `composer.json` to set version constraints:

```json
{
  "require": {
    "wpackagist-plugin/wordfence": "~7.10.0",
    "wpackagist-plugin/contact-form-7": "^5.8.0",
    "wpackagist-theme/twentytwentyfour": "1.3.*"
  }
}
```

Then run:
```bash
./composer.sh update
```

This allows for fine-grained control over which packages can be updated and by how much.