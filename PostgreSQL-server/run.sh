#!/usr/bin/with-contenv bashio

DB_NAME=$(bashio::config 'database')
DB_USER=$(bashio::config 'username')
DB_PASS=$(bashio::config 'password')

export PGDATA="/data/postgresql"

# Инициализируем базу, если она не существует
if [ ! -d "$PGDATA" ]; then
    echo "[INFO] Инициализация PostgreSQL в $PGDATA"
    su-exec postgres:postgres initdb -D "$PGDATA"
fi

# Запускаем PostgreSQL в фоне
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres:postgres pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -w start

# Создаем пользователя и базу, если нужно
if ! su-exec postgres:postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    echo "[INFO] Создание пользователя $DB_USER"
    su-exec postgres:postgres createuser "$DB_USER"
fi

if ! su-exec postgres:postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "[INFO] Создание базы данных $DB_NAME"
    su-exec postgres:postgres createdb -O "$DB_USER" "$DB_NAME"
fi

# Установка пароля
su-exec postgres:postgres psql -c "ALTER USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"

# Ожидание
echo "[INFO] PostgreSQL работает. Ждём..."
tail -f /dev/null
