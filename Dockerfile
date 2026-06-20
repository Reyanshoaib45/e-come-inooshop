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

# Copy everything
COPY . .

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Build frontend
RUN npm install && npm run build

# Remove installer routes AND regenerate autoloader
RUN sed -i '/install/d' routes/web.php 2>/dev/null || true \
    && sed -i '/install/d' routes/*.php 2>/dev/null || true \
    && rm -rf innopacks/install 2>/dev/null || true \
    && rm -rf vendor/innopacks/install 2>/dev/null || true \
    && composer dump-autoload --optimize --no-interaction

# Create storage + install flag
RUN mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs \
    && touch storage/installed \
    && touch database/database.sqlite \
    && chmod -R 775 storage bootstrap/cache database \
    && chmod 664 database/database.sqlite

# Cache configs
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

EXPOSE 8080

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]