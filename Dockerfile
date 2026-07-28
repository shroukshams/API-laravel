FROM php:8.3-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libzip-dev \
    postgresql-dev \
    oniguruma-dev \
    g++ \
    make \
    autoconf \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql pdo_pgsql zip bcmath exif pcntl opcache intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Optimize Laravel
RUN php artisan optimize

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]

# --- Development Stage ---
FROM base AS development

RUN apk add --no-cache nodejs npm

# Install development PHP dependencies
RUN composer install --no-interaction --prefer-dist

# Install Node.js dependencies
RUN npm install && npm run build

# Expose port 8000 for Laravel development server
EXPOSE 8000

CMD ["php", "artisan", "serve", "--host", "0.0.0.0"]
