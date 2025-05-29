#!/bin/sh

CONFIG=/data/options.json

DB_NAME=$(jq --raw-output '.database' $CONFIG)
DB_USER=$(jq --raw-output '.username' $CONFIG)
DB_PASS=$(jq --raw-output '.password' $CONFIG)

export PGDATA="/var/lib/postgresql/data"

# Инициализация, если БД ещё нет
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[INFO] Инициализация PostgreSQL в $PGDATA"
  su-exec postgres initdb --auth=scram-sha-256
fi

# Включаем прослушку всех интерфейсов и scram-аутентификацию
echo "[INFO] Настройка postgresql.conf"
# Чтобы не дублировать параметры при повторных перезапусках, лучше заменить или добавить только если нет
grep -q "^listen_addresses" "$PGDATA/postgresql.conf" || echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
grep -q "^password_encryption" "$PGDATA/postgresql.conf" || echo "password_encryption = 'scram-sha-256'" >> "$PGDATA/postgresql.conf"

# Разрешаем доступ всем хостам по scram-sha-256 (лучше проверять и не дублировать)
if ! grep -q "^host all all 0.0.0.0/0 scram-sha-256" "$PGDATA/pg_hba.conf"; then
  echo "[INFO] Настройка pg_hba.conf"
  echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"
fi

# Запуск PostgreSQL
echo "[INFO] Запуск PostgreSQL..."
su-exec postgres postgres &

# Ожидание запуска сервера (максимум 30 секунд)
echo "[INFO] Ожидание запуска PostgreSQL..."
for i in $(seq 1 30); do
  if su-exec postgres pg_isready -q; then
    echo "[INFO] PostgreSQL готов к подключениям"
    break
  fi
  echo "  > Ожидание ($i)..."
  sleep 1
done

if ! su-exec postgres pg_isready -q; then
  echo "[ERROR] PostgreSQL не запустился вовремя"
  exit 1
fi

# Создание базы, если её нет
if ! su-exec postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  echo "[INFO] Создание базы $DB_NAME"
  su-exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\""
fi

# Создание пользователя, если его нет
if ! su-exec postgres psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  echo "[INFO] Создание пользователя $DB_USER"
  su-exec postgres psql -U postgres -c "CREATE ROLE \"$DB_USER\" WITH LOGIN PASSWORD '$DB_PASS'"
fi

# Выдача прав
echo "[INFO] Выдаем привилегии на базу $DB_NAME пользователю $DB_USER"
su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\""

wait
