#!/usr/bin/with-contenv bashio

# Получаем параметры из конфигурации
DB_NAME=$(bashio::config 'database')
DB_USER=$(bashio::config 'username')
DB_PASS=$(bashio::config 'password')

export PGDATA="/data/postgresql"

# Создание каталога и установка прав
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"

# Инициализация базы данных, если необходимо
if [ ! -d "$PGDATA/base" ]; then
    echo "[INFO] Инициализация PostgreSQL в $PGDATA"
    su-exec postgres:postgres initdb -D "$PGDATA"
fi

# Запуск PostgreSQL
echo "[INFO] Запуск PostgreSQL..."
exec su-exec postgres:postgres postgres -D "$PGDATA"
