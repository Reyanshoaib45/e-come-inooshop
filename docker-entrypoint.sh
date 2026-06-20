#!/bin/bash
set -e

cd /app

# Ensure storage dirs
mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
chmod -R 775 storage bootstrap/cache

# CRITICAL: Create install flag (prevents wizard)
touch storage/installed

# Ensure SQLite DB exists (on persistent volume ideally)
if [ ! -f database/database.sqlite ]; then
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    NEW_DB=true
else
    NEW_DB=false
fi

# Run migrations (safe — only new ones)
php artisan migrate --force

# Seed admin ONLY on first run
if [ "$NEW_DB" = "true" ]; then
    php artisan db:seed --class=AdminSeeder --force 2>/dev/null || true
fi

# Re-create install flag (ensure it persists)
touch storage/installed

# Cache configs
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
echo "Starting InnoShop on port 8080..."
exec php -S 0.0.0.0:8080 -t public