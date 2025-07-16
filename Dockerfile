# Use the official PHP-FPM image as the base
FROM public.ecr.aws/docker/library/php:fpm

# Define a user variable
ARG user=www-data

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip unzip libzip-dev \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=public.ecr.aws/composer/composer:latest-bin /composer /usr/bin/composer

# Create a system user for running Composer and Artisan commands
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Copy Nginx configuration and entrypoint script
COPY ./docker/default.conf /etc/nginx/sites-enabled/default
COPY ./docker/entrypoint.sh /etc/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /etc/entrypoint.sh

# Set the working directory
WORKDIR /var/www

COPY --chown=www-data:www-data . /var/www

# Install PHP dependencies
RUN composer install --no-progress --optimize-autoloader --no-dev

RUN chown -R www-data:www-data /var/www

# Run npm as www-data
RUN su www-data -s /bin/sh -c "npm ci && npm run build"

RUN chown -R www-data:www-data /var/www/storage /var/www/public && \
    chmod -R 775 /var/www/storage

# Expose port 80
EXPOSE 80

# Define the entrypoint
ENTRYPOINT ["/etc/entrypoint.sh"]

