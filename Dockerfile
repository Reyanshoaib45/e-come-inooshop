FROM php:8.3-cli

# Install system deps + SQLite
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev gnupg libsqlite3-dev sqlite3 \
    && docker-php-ext-install zip pcntl bcmath pdo pdo_sqlite

# Install Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy composer files first (layer caching)
COPY composer.json composer.lock ./
COPY innopacks ./innopacks

# Allow composer plugins as root + install
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy package files and install/build frontend
COPY package.json package-lock.json* ./
RUN npm install
COPY . .

# NUCLEAR OPTION: Remove installer routes to prevent redirect
RUN sed -i '/install/d' routes/web.php 2>/dev/null || true \
    && sed -i '/install/d' routes/*.php 2>/dev/null || true \
    && rm -rf innopacks/install 2>/dev/null || true \
    && rm -rf vendor/innopacks/install 2>/dev/null || true

# Build frontend
RUN npm run build

# Create storage directories + install flag
RUN mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs \
    && touch storage/installed \
    && touch database/database.sqlite \
    && chmod -R 775 storage bootstrap/cache database \
    && chmod 664 database/database.sqlite

# Cache configs at build
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

EXPOSE 8080

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]