#!/bin/sh

CONFIG=/data/options.json

DB_NAME=$(jq --raw-output '.database' $CONFIG)
DB_USER=$(jq --raw-output '.username' $CONFIG)
DB_PASS=$(jq --raw-output '.password' $CONFIG)

export PGDATA="/var/lib/postgresql/data"

# Инициализация кластера
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[INFO] Инициализация PostgreSQL в $PGDATA"
  su-exec postgres initdb

  echo "[INFO] Настройка postgresql.conf"
  echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"

  echo "[INFO] Настройка pg_hba.conf"
  cat <<EOF > "$PGDATA/pg_hba.conf"
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    $DB_NAME        $DB_USER        0.0.0.0/0               trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF
fi

# Запуск PostgreSQL
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres postgres &

sleep 5

# Создание БД
if ! su-exec postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  echo "[INFO] Создание базы $DB_NAME"
  su-exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\""
fi

# Создание пользователя
if ! su-exec postgres psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  echo "[INFO] Создание пользователя $DB_USER"
  su-exec postgres psql -U postgres -c "CREATE USER \"$DB_USER\" WITH ENCRYPTED PASSWORD '$DB_PASS'"
fi

# Выдача прав
echo "[INFO] Выдаем привилегии на базу $DB_NAME пользователю $DB_USER"
su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\""

# Ждём завершения
wait
