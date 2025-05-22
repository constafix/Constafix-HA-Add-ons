#!/usr/bin/env bashio

DATABASE=$(bashio::config 'database')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
PGDATA=$(bashio::config 'pgdata')

export POSTGRES_DB=$DATABASE
export POSTGRES_USER=$USERNAME
export POSTGRES_PASSWORD=$PASSWORD
export PGDATA=$PGDATA

exec docker-entrypoint.sh postgres