#!/bin/bash
set -e

cd /app

# Ensure storage dirs
mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
chmod -R 775 storage bootstrap/cache

# CRITICAL: Create install flag (prevents wizard)
touch storage/installed

# Ensure SQLite DB exists
if [ ! -f database/database.sqlite ]; then
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    NEW_DB=true
else
    NEW_DB=false
fi

# Run migrations
php artisan migrate --force

# Seed admin if needed
if [ "$NEW_DB" = "true" ]; then
    php artisan db:seed --class=AdminSeeder --force 2>/dev/null || true
fi

# Re-create install flag
touch storage/installed

# Cache configs
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
echo "Starting InnoShop..."
exec php -S 0.0.0.0:8080 -t public