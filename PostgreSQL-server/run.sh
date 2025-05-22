#!/bin/sh

CONFIG_PATH=/data/options.json

DB_NAME=$(jq --raw-output '.database' $CONFIG_PATH)
DB_USER=$(jq --raw-output '.username' $CONFIG_PATH)
DB_PASS=$(jq --raw-output '.password' $CONFIG_PATH)

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
