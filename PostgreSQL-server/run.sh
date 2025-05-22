#!/bin/sh

# Путь к файлу с опциями, смонтированному HA
CONFIG=/data/options.json

DB_NAME=$(jq --raw-output '.database' $CONFIG)
DB_USER=$(jq --raw-output '.username' $CONFIG)
DB_PASS=$(jq --raw-output '.password' $CONFIG)

export PGDATA="/var/lib/postgresql/data"

# Инициализация кластера, если ещё не инициализирован
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[INFO] Инициализация PostgreSQL в $PGDATA"
  su-exec postgres initdb
fi

# Запуск сервера
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres postgres &

# Даем время на старт
sleep 5

# Создаем базу, если её нет
if ! su-exec postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  echo "[INFO] Создание базы $DB_NAME"
  su-exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\""
fi

# Создаем пользователя, если его нет
if ! su-exec postgres psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  echo "[INFO] Создание пользователя $DB_USER"
  su-exec postgres psql -U postgres -c "CREATE USER \"$DB_USER\" WITH ENCRYPTED PASSWORD '$DB_PASS'"
fi

# Выдаем права
echo "[INFO] Выдаем привилегии на базу $DB_NAME пользователю $DB_USER"
su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\""

# Ожидание дочерних процессов
wait
