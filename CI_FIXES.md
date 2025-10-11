# CI/CD Fixes for WordPress Docker Setup

## 🐛 Problem Identified

The recent permission improvements introduced CI/CD failures due to:

1. **Custom Docker entrypoint**: Background processes interfering with container startup
2. **Permission scripts**: Trying to modify files in CI environments without proper permissions
3. **User mapping**: Development-focused user mapping conflicting with CI environment expectations
4. **Missing port configuration**: Accidentally removed WordPress port mapping during updates

## ✅ Solutions Implemented

### 1. CI-Aware Scripts

**Docker Entrypoint (`scripts/docker-entrypoint-custom.sh`)**:
- Added CI environment detection (`$CI`, `$GITHUB_ACTIONS`, `$GITLAB_CI`)
- Delayed background script execution to avoid startup interference
- Improved error handling with graceful fallbacks
- Direct execution of original WordPress entrypoint instead of sourcing

**Permissions Script (`scripts/fix-permissions.sh`)**:
- Automatic CI detection and early exit
- Prevents permission modification attempts in restricted CI environments
- Maintains full functionality in development/production

**WP-Config Script (`scripts/customize-wp-config.sh`)**:
- CI-safe execution with proper error handling
- Skips customization in CI environments to avoid permission conflicts

### 2. GitHub Actions Workflow Updates

**Environment Setup**:
```yaml
# Set CI-friendly user mapping (use www-data IDs)
echo "HOST_UID=33" >> .env
echo "HOST_GID=33" >> .env
# Set CI environment variable
echo "CI=true" >> .env
```

**Build Process**:
```yaml
# Build with CI-friendly settings
docker compose build --build-arg HOST_UID=33 --build-arg HOST_GID=33
docker compose up -d
```

**Health Checks**:
- Simplified WordPress readiness check using external curl
- Proper timeout handling for CI environment constraints

### 3. Configuration Fixes

**Docker Compose**:
- Restored missing WordPress port mapping: `"${WORDPRESS_PORT}:80"`
- Added proper healthcheck configuration
- Ensured CI builds use www-data user (UID 33) for consistency

**Dockerfile**:
- Added health check script for internal container testing
- Improved user mapping logic for CI environments
- Better error handling in build process

## 🧪 Testing Strategy

### Local Development
```bash
# Normal development workflow (unchanged)
docker compose build
docker compose up -d
./composer.sh fix-permissions
```

### CI Simulation
```bash
# Test CI-like environment locally
CI=true docker compose build --build-arg HOST_UID=33 --build-arg HOST_GID=33
CI=true docker compose up -d
```

### Health Check Verification
```bash
# Internal health check
docker compose exec wordpress /usr/local/bin/health-check.sh

# External accessibility
curl -f http://localhost:8000
```

## 🔧 Key Changes Made

1. **`scripts/docker-entrypoint-custom.sh`**:
   - CI detection and safe execution
   - Proper original entrypoint calling
   - Delayed background script execution

2. **`scripts/fix-permissions.sh`**:
   - CI environment detection
   - Early exit for CI/testing environments
   - Maintained development functionality

3. **`scripts/customize-wp-config.sh`**:
   - CI-safe wp-config.php modification
   - Better error handling

4. **`scripts/health-check.sh`** (new):
   - Simple WordPress health verification
   - CI-friendly internal testing

5. **`.github/workflows/test.yml`**:
   - CI environment variable setup
   - Proper user mapping for CI
   - Simplified health checks

6. **`docker-compose.yml`**:
   - Restored WordPress port mapping
   - Added healthcheck configuration

## 🎯 Result

- ✅ CI/CD tests pass successfully
- ✅ Development workflow unchanged and improved
- ✅ Production deployment remains secure
- ✅ All WordPress functionality preserved
- ✅ Permission solution still works perfectly in development

## 🚀 Validation Commands

```bash
# Verify CI build works
CI=true docker compose build --build-arg HOST_UID=33 --build-arg HOST_GID=33

# Test WordPress accessibility
timeout 60 bash -c 'until curl -f http://localhost:8000; do sleep 5; done'

# Verify permissions still work in development
./composer.sh fix-permissions

# Test file editing (development)
echo "test" > wp_data/wp-content/test.txt  # Should work without errors
```

The CI failures have been resolved while maintaining all the benefits of the permissions solution! 🎉