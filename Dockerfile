FROM php:8.2-cli

# Install system deps + PHP extensions
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev \
    && docker-php-ext-install zip pcntl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Expose port
EXPOSE 8080

# Run Laravel
CMD php artisan serve --host=0.0.0.0 --port=8080
