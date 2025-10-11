# Custom WordPress Docker image with all essential PHP extensions
FROM wordpress:6.8-php8.3-apache

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

# Copy custom PHP configuration
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy wp-config customization script
COPY scripts/customize-wp-config.sh /usr/local/bin/customize-wp-config.sh
RUN chmod +x /usr/local/bin/customize-wp-config.sh

# Create entrypoint script that runs customizations before starting WordPress
COPY scripts/docker-entrypoint-custom.sh /usr/local/bin/docker-entrypoint-custom.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"]