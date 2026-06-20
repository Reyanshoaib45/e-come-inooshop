#!/bin/bash
set -e

cd /app

# 1. Ensure storage directories exist
mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
chmod -R 775 storage bootstrap/cache

# 2. Create install flag (SKIPS THE WIZARD)
touch storage/installed

# 3. Ensure SQLite DB exists (if using SQLite)
if [ "$DB_CONNECTION" = "sqlite" ] || [ -z "$DB_CONNECTION" ]; then
    if [ ! -f database/database.sqlite ]; then
        touch database/database.sqlite
        chmod 664 database/database.sqlite
    fi
fi

# 4. Run migrations (safe — only applies new ones, never drops data)
php artisan migrate --force

# 5. Re-create install flag (ensure it persists)
touch storage/installed

# 6. Cache configs for performance
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 7. Start server
echo "Starting InnoShop on port 8080..."
exec php -S 0.0.0.0:8080 -t public