#!/usr/bin/env bashio

# Получаем конфигурацию пользователя из интерфейса HA
DATABASE=$(bashio::config 'database')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
PGDATA=$(bashio::config 'pgdata')

export POSTGRES_DB=$DATABASE
export POSTGRES_USER=$USERNAME
export POSTGRES_PASSWORD=$PASSWORD
export PGDATA=$PGDATA

echo "Инициализация PostgreSQL..."
exec docker-entrypoint.sh postgres
