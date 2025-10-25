# AI Coding Agent Instructions for wp-docker-composer

## Project Overview

**wp-docker-composer** is a professional WordPress development environment using Docker, Composer, and WPackagist for streamlined plugin/theme management. The project solves two critical problems: (1) reproducible local development, and (2) automated file permission management in Docker.

**Key insight**: This is a *platform/devops-focused* project, not a WordPress plugin project. It provides infrastructure and tooling—success depends on understanding Docker services, permission models, and the `composer.sh` CLI orchestration layer.

---

## Documentation Policy

**Minimize documentation bloat.** Only update/create documentation when:
- ✅ Core README.md needs factual updates about features, setup, or commands
- ✅ CONTRIBUTING.md needs workflow clarifications for developers
- ✅ Existing docs become inaccurate due to code changes
- ✅ User explicitly requests documentation for a feature

**Never create:**
- ❌ New supplementary `.md` files for features (integrate into README instead)
- ❌ Inline code comments explaining obvious logic
- ❌ Separate "guides" or "tutorials" unless repo already has a `docs/` pattern
- ❌ Changelog or release notes files (use git history)

**When uncertain**: Assume "no docs needed" unless there's a clear reason.

---

## Architecture Essentials

### Service Architecture (docker-compose.yml)

- **wordpress** (PHP 8.3-Apache): Custom Dockerfile with pre-installed extensions (gd, intl, ftp, opcache, etc.)
- **db** (MariaDB 10.11): Persistent DB with custom `mysql.cnf`
- **composer**: Isolated container running `composer:latest` with user mapping via HOST_UID/HOST_GID
- **wpcli** & **phpmyadmin**: Optional tools on `profiles: [tools]`

**Critical pattern**: Services marked with `profiles: [tools]` are only started explicitly with `docker compose --profile tools`.

### Permission Architecture: The Shared Group Model

This is the *core innovation* of the project—understand it deeply:

1. **Problem**: Traditional Docker gives you either (a) WordPress-writable files or (b) host-editable files, never both
2. **Solution**: Create a shared `wpdev` group (GID 1001) that both `www-data` and the host user join
3. **Implementation** (`scripts/fix-permissions.sh`):
   - Sets `wp-content` dirs to `775` with group ownership
   - Sets `wp-content` files to `664` 
   - Applies sticky bit (`g+s`) so new files inherit group
   - wp-config.php and core WP files remain restrictive (644)

**When working with permissions**: Always think in terms of this group model. It's not just about chmod—it's about ownership and group inheritance.

### Directory Structure and Purpose

```
wp_data/                    # WordPress installation (volume-mounted)
├── wp-config.php          # Auto-generated from wp-config-docker.php
├── wp-content/            # Shared group (775/664) - both users can edit
│   ├── plugins/           # Auto-installed by Composer
│   ├── themes/            # Auto-installed by Composer
│   ├── mu-plugins/        # Deployed by scripts/deploy-mu-plugins.sh
│   ├── uploads/           # WordPress media (extra permissive 775)
│   └── debug.log          # Managed by custom-error-filter MU-plugin
└── [core WP files]        # Restrictive 644 (www-data only)

mu-plugins/                 # Source MU-plugins (in repo root)
├── custom-error-filter.php # Deduplicates debug logs
└── error-filter-config.php # Configuration for error filter

scripts/                    # Utility scripts
├── fix-permissions.sh     # Container-side permission setup
├── deploy-mu-plugins.sh   # Copies mu-plugins to WordPress
├── set-dev-permissions.sh # Dev-mode permissive setup
└── [others]
```

---

## Critical Developer Workflows

### Workflow 1: First-Time Setup

```bash
cp .env.example .env
# Edit .env with your ports, credentials
docker compose build          # Must happen first
./init-wordpress.sh          # One command that does everything
```

**Why this order matters**: `docker compose build` injects the permission scripts into the image. Skipping this causes "script not found" errors.

### Workflow 2: Plugin/Theme Management (composer.sh)

The `composer.sh` script is the *primary interface*—it wraps `docker compose` with permission auto-fixing:

```bash
./composer.sh plugin install contact-form-7       # Shorthand
./composer.sh plugin install contact-form-7 5.8.3 # With version
./composer.sh theme install twentytwentyfour
./composer.sh plugin remove contact-form-7        # Safe (tries deactivation)
./composer.sh plugin force-remove contact-form-7  # Force (skips deactivation)
./composer.sh fix-permissions                     # Manual permission fix
```

**Key design pattern in composer.sh**:
1. `ensure_ready()` — Checks if containers are running, starts if needed
2. `run_composer()` — Detects CI environment, uses appropriate Docker command
3. Auto-calls `auto_fix_permissions()` after operations that modify files (install, update, require, remove)

### Workflow 3: Permission Troubleshooting

If plugins can't be uploaded or edited:

```bash
./composer.sh fix-permissions  # Uses container-side fix-permissions.sh
```

For development, more permissive setup:
```bash
./scripts/set-dev-permissions.sh  # 775 for everything except core WP
```

**When to use which**:
- Default after Composer operations: `auto_fix_permissions()` (conservative, production-safe)
- Manual dev setup: `set-dev-permissions.sh` (permissive, dev-friendly)

### Workflow 4: Must-Use Plugins Deployment

MU-plugins are automatically loaded and can't be deactivated—used for infrastructure concerns:

```bash
./scripts/deploy-mu-plugins.sh  # Copies mu-plugins/*.php to wp-content/mu-plugins/
```

**Pattern**: MU-plugins are for *platform-level* concerns (error filtering, debugging helpers), not user-facing features.

---

## Project-Specific Conventions

### Environment Variables (.env)

- **HOST_UID/HOST_GID**: Must match your host user for permission sharing. Auto-detected by `init-wordpress.sh`
- **MYSQL_* credentials**: Change from defaults (these are intentionally weak as placeholders)
- **WORDPRESS_DEBUG**: Set to `true` in dev, `false` in production
- **Composer timeout**: Default 600s (10 mins) for slow networks

### Error Filtering (mu-plugins/custom-error-filter.php)

This MU-plugin prevents debug log spam by caching error message hashes:

```php
// Configuration in error-filter-config.php
define('ERROR_FILTER_CACHE_DURATION', 24 * 60 * 60);  // 24 hours
define('ERROR_FILTER_NOTICES', true);                  // Filter notices
define('ERROR_FILTER_DEPRECATED', true);              // Filter deprecated
```

**Why this matters**: Without this, debug.log fills with duplicate "translation loading called too early" warnings. The cache-based deduplication prevents noise while preserving first-occurrence details.

### Composer Configuration (composer.json)

- **Only repository**: WPackagist (`https://wpackagist.org`)
- **Installer paths**: Plugins → `wp_data/wp-content/plugins/{$name}/`, Themes → `wp_data/wp-content/themes/{$name}/`
- **Allowed plugins**: Only `composer/installers` (strict allow-plugins)
- **PHP requirement**: `>=8.0`

**Pattern**: No custom code in composer.json—only package declarations and Composer's own configuration.

### Dockerfile Approach

- Builds on `wordpress:6.8-php8.3-apache`
- Pre-installs many PHP extensions (gd, intl, soap, ftp, bcmath, etc.)
- Injects permission scripts at build time (not runtime)
- Accepts `HOST_UID` and `HOST_GID` build args for user mapping

**When updating PHP extensions**: Modify Dockerfile, rebuild with `docker compose build --no-cache`.

---

## Integration Points and Dependencies

### External Dependencies

- **WPackagist API**: Used by Composer to resolve plugin/theme versions
- **Docker Hub**: Images: `wordpress:6.8-php8.3-apache`, `mariadb:10.11`, `composer:latest`
- **GitHub Actions** (CI): Detects via `$GITHUB_ACTIONS` env var in `composer.sh`

### Cross-Component Communication

- **WordPress ↔ Database**: Via `db` service hostname (Docker DNS)
- **Composer ↔ WordPress**: Via mounted volumes (not network)
- **Host ↔ WordPress**: Via volume mount `./wp_data:/var/www/html`
- **WP-CLI ↔ WordPress**: Same volume mount, separate service

**Key insight**: All file sharing is volume-based (not network)—permissions must be right on the host filesystem.

### CI/CD Considerations

The `composer.sh` script detects CI environments:

```bash
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$GITLAB_CI" ]; then
    # Use direct `docker run composer` instead of `docker compose exec`
    # Avoids permission issues in CI
fi
```

---

## Common Patterns and Anti-Patterns

### ✅ DO

- **Always run `docker compose build` after pulling updates** — Ensures permission scripts are in image
- **Auto-fix permissions after Composer operations** — Handled by `composer.sh`, don't skip
- **Use `./composer.sh plugin install` over manual `docker compose exec composer require`** — The wrapper handles permissions
- **Keep error filter config in a separate file** — Easier to customize without touching core plugin
- **Test permission-heavy changes in dev mode first** — Use `set-dev-permissions.sh` to debug

### ❌ DON'T

- **Don't manually edit wp-config.php** — It's generated from `wp-config-docker.php`
- **Don't skip the initial `docker compose build`** — Permission scripts won't be available
- **Don't directly `chown` wp_data to root** — Breaks the shared group model
- **Don't mix `docker compose exec composer` with `./composer.sh`** — Inconsistent permission handling
- **Don't assume permissions work across docker-compose restarts** — Always rebuild if you change HOST_UID/HOST_GID

---

## Files to Reference When Working on Features

| Task | Key Files |
|------|-----------|
| **Add new permission rules** | `scripts/fix-permissions.sh`, `Dockerfile` |
| **Extend composer.sh functionality** | `composer.sh` (ensure_ready, run_composer patterns) |
| **Add new MU-plugin** | `mu-plugins/*.php`, `scripts/deploy-mu-plugins.sh` |
| **Change PHP extensions** | `Dockerfile`, rebuild with `docker compose build --no-cache` |
| **Debug CI/CD issues** | Look for `$CI`, `$GITHUB_ACTIONS` in `composer.sh` |
| **Update database config** | `config/mysql.cnf`, `docker-compose.yml` |

---

## Debugging Strategies

1. **Container won't start**: Check `docker compose logs wordpress`, likely permission script not found (rebuild needed)
2. **Permission errors on file upload**: Run `./composer.sh fix-permissions`, verify `wp-content` group ownership
3. **Composer timeout**: Check `COMPOSER_PROCESS_TIMEOUT` in `.env`, increase if needed
4. **WP-CLI hanging**: Use `./composer.sh plugin force-remove` (has 10s timeout)
5. **Git ownership errors**: Resolved automatically in recent versions; if persistent, rebuild composer service

---

## Documentation References

- **README.md**: High-level features, quick start, common issues
- **PERMISSIONS_SOLUTION.md**: Deep dive into the shared group permission model
- **VERSION_CONSTRAINTS.md**: Composer version syntax (^, ~, ranges)
- **CONTRIBUTING.md**: Development guidelines and testing checklist
- **mu-plugins/README.md**: Error filter configuration details

