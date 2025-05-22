#!/bin/sh

# Чтение настроек из config.yaml, который HA превращает в /data/options.json
DB_NAME=$(jq --raw-output '.database' /data/options.json)
DB_USER=$(jq --raw-output '.username' /data/options.json)
DB_PASS=$(jq --raw-output '.password' /data/options.json)

export PGDATA="/var/lib/postgresql/data"

# Инициализация, если база ещё не инициализирована
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[INFO] Инициализация PostgreSQL в $PGDATA"
  initdb --username=postgres
fi

# Запуск PostgreSQL в фоне
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres postgres &

# Ждём, пока сервер запустится
sleep 5

# Создание пользователя и базы, если они ещё не созданы
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
  psql -U postgres -c "CREATE DATABASE \"$DB_NAME\""

psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER'" | grep -q 1 || \
  psql -U postgres -c "CREATE USER \"$DB_USER\" WITH ENCRYPTED PASSWORD '$DB_PASS'"

psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\""

# Ожидание завершения
wait
