#!/usr/bin/with-contenv bashio

DB_NAME=$(bashio::config 'database')
DB_USER=$(bashio::config 'username')
DB_PASS=$(bashio::config 'password')

export PGDATA="/var/lib/postgresql/data"

# Инициализация БД, если не существует
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[INFO] Инициализация PostgreSQL в $PGDATA"
    su-exec postgres initdb
fi

# Запуск PostgreSQL в фоне
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres postgres &

# Ожидание запуска
sleep 5

# Создание БД и пользователя
su-exec postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    su-exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\""

su-exec postgres psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER'" | grep -q 1 || \
    su-exec postgres psql -U postgres -c "CREATE USER \"$DB_USER\" WITH ENCRYPTED PASSWORD '$DB_PASS'"

su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\""

wait
