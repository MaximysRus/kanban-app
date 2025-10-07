#!/bin/bash
set -e

echo "=== Инициализация контейнера ==="

if [ ! -f .env ]; then
    echo "Создание .env из .env.example..."
    cp .env.example .env

    {
        echo ""
        echo "# ====== Docker environment variables ======"
        [ -n "$APP_ENV" ] && echo "APP_ENV=${APP_ENV}"
        [ -n "$APP_DEBUG" ] && echo "APP_DEBUG=${APP_DEBUG}"
        [ -n "$APP_URL" ] && echo "APP_URL=${APP_URL}"
        [ -n "$DB_CONNECTION" ] && echo "DB_CONNECTION=${DB_CONNECTION}"
        [ -n "$DB_HOST" ] && echo "DB_HOST=${DB_HOST}"
        [ -n "$DB_PORT" ] && echo "DB_PORT=${DB_PORT}"
        [ -n "$DB_DATABASE" ] && echo "DB_DATABASE=${DB_DATABASE}"
        [ -n "$DB_USERNAME" ] && echo "DB_USERNAME=${DB_USERNAME}"
        [ -n "$DB_PASSWORD" ] && echo "DB_PASSWORD=${DB_PASSWORD}"
        [ -n "$DB_SSL" ] && echo "DB_SSL=${DB_SSL}"
        [ -n "$REDIS_HOST" ] && echo "REDIS_HOST=${REDIS_HOST}"
    } >> .env

    echo ".env создан!"
else
    echo ".env уже существует — пропускаем создание."
fi

if grep -q '^APP_KEY=' .env; then
    CURRENT_KEY=$(grep '^APP_KEY=' .env | cut -d '=' -f2-)
else
    CURRENT_KEY=""
fi

if [ -z "$CURRENT_KEY" ]; then
    echo "Генерация нового APP_KEY..."
    php artisan key:generate --force
else
    echo "APP_KEY уже существует."
fi

echo "Ожидание подключения к MySQL..."

# ↓ ДОБАВЬ --ssl-mode=DISABLED ↓
until mysql -h "${DB_HOST:-database}" -u "${DB_USERNAME:-root}" -p"${DB_PASSWORD:-123}" --ssl=false -e "SELECT 1" 2>&1; do
    error_output=$?
    echo "❌ MySQL недоступен (код ошибки: $error_output), ждем 5 секунд..."
    sleep 5
done

echo "✅ MySQL подключен!"

echo "Выполнение миграций..."
php artisan migrate --force

echo "Выполнение сидов..."
php artisan db:seed --force

echo "✅ Инициализация завершена!"
exec "$@"