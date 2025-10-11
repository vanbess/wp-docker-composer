# Custom WordPress Docker image with all essential PHP extensions
FROM wordpress:6.8-php8.3-apache

# Accept build arguments for user mapping
ARG HOST_UID=1000
ARG HOST_GID=1000

# Install system dependencies and PHP extensions that WordPress needs
RUN apt-get update && apt-get install -y \
    # System dependencies
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt-dev \
    libonig-dev \
    libmagickwand-dev \
    libmemcached-dev \
    unzip \
    wget \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        # Core extensions WordPress needs
        gd \
        mysqli \
        pdo_mysql \
        zip \
        intl \
        xml \
        xsl \
        soap \
        mbstring \
        bcmath \
        exif \
        # FTP support (includes ftpsockets functionality)
        ftp \
        # Additional useful extensions
        opcache \
        calendar \
        gettext

# Install PECL extensions
RUN pecl install imagick redis \
    && docker-php-ext-enable imagick redis

# Enable Apache modules that WordPress commonly uses
RUN a2enmod rewrite expires headers deflate

# Create a shared group for WordPress file access
RUN groupadd -g 1001 wpdev \
    && usermod -a -G wpdev www-data

# Create host user in container with same UID/GID and add to wpdev group
RUN if [ ${HOST_UID:-1000} -ne 33 ]; then \
        groupmod -g ${HOST_GID} wpdev 2>/dev/null || groupadd -g ${HOST_GID} wpdev; \
        useradd -u ${HOST_UID} -g ${HOST_GID} -m -s /bin/bash hostuser 2>/dev/null || usermod -u ${HOST_UID} -g ${HOST_GID} hostuser; \
        usermod -a -G wpdev hostuser; \
        usermod -a -G wpdev www-data; \
    fi

# Copy custom PHP configuration
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy wp-config customization script
COPY scripts/customize-wp-config.sh /usr/local/bin/customize-wp-config.sh
RUN chmod +x /usr/local/bin/customize-wp-config.sh

# Copy permissions management script
COPY scripts/fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod +x /usr/local/bin/fix-permissions.sh

# Create entrypoint script that runs customizations before starting WordPress
COPY scripts/docker-entrypoint-custom.sh /usr/local/bin/docker-entrypoint-custom.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"]