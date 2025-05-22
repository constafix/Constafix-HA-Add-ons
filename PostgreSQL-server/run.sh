#!/bin/sh

CONFIG_PATH=/data/options.json

DB_NAME=$(jq --raw-output '.database' $CONFIG_PATH)
DB_USER=$(jq --raw-output '.username' $CONFIG_PATH)
DB_PASS=$(jq --raw-output '.password' $CONFIG_PATH)

export PGDATA="/var/lib/postgresql/data"

# Инициализация — PostgreSQL делает это автоматически, если папка пуста

echo "[INFO] Запуск PostgreSQL..."
exec su-exec postgres postgres
