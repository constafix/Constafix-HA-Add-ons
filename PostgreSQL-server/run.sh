set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_PREFIX="[custom_postgres]"
LOG_INDENT="  "

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log_info() {
  echo -e "${BLUE}$(timestamp)${NC} ${LOG_PREFIX} ${GREEN}[INFO]${NC}${LOG_INDENT}$1"
}

log_warn() {
  echo -e "${BLUE}$(timestamp)${NC} ${LOG_PREFIX} ${YELLOW}[WARN]${NC}${LOG_INDENT}$1"
}

log_error() {
  echo -e "${BLUE}$(timestamp)${NC} ${LOG_PREFIX} ${RED}[ERROR]${NC}${LOG_INDENT}$1" >&2
}

exit_with_error() {
  log_error "$1"
  exit 1
}

CONFIG=/data/options.json
export PGDATA="/data/data/postgres"

trap 'exit_with_error "Скрипт прерван с ошибкой на строке $LINENO"' ERR

read_config() {
  log_info "Чтение конфигурации из $CONFIG..."
  DB_NAME=$(jq --raw-output '.database' "$CONFIG") || exit_with_error "Ошибка чтения database из конфига"
  DB_USER=$(jq --raw-output '.username' "$CONFIG") || exit_with_error "Ошибка чтения username из конфига"
  DB_PASS=$(jq --raw-output '.password' "$CONFIG") || exit_with_error "Ошибка чтения password из конфига"
  PG_SUPERPASS=$(jq --raw-output '.postgres_password' "$CONFIG") || exit_with_error "Ошибка чтения postgres_password из конфига"
  log_info "Конфигурация: database='$DB_NAME', username='$DB_USER', (пароли скрыты)"
}

check_data_directory() {
  log_info "Проверка наличия и прав папки данных $PGDATA..."

  if [ ! -d "$PGDATA" ]; then
    log_warn "Папка данных $PGDATA не существует. Пытаюсь создать..."
    mkdir -p "$PGDATA" || exit_with_error "Не удалось создать папку данных $PGDATA"
    log_info "Папка $PGDATA успешно создана."
  else
    log_info "Папка данных $PGDATA существует."
  fi

  ls -ld "$PGDATA" || log_warn "Не удалось получить подробности папки $PGDATA"

  # Проверим права
  if [ ! -w "$PGDATA" ]; then
    log_warn "Папка $PGDATA недоступна для записи!"
  else
    log_info "Права на запись в папку $PGDATA установлены."
  fi

  # 👇 Важно! Передаём права пользователю postgres
  chown -R postgres:postgres "$PGDATA" || exit_with_error "Не удалось сменить владельца $PGDATA на postgres"
}

init_db() {
  log_info "Инициализация PostgreSQL в $PGDATA"

  PWFILE=/tmp/postgres_pwfile

  echo "$PG_SUPERPASS" > "$PWFILE" || exit_with_error "Не удалось записать пароль в $PWFILE"
  chmod 600 "$PWFILE" || exit_with_error "Не удалось установить права 600 на $PWFILE"
  chown postgres:postgres "$PWFILE" || exit_with_error "Не удалось изменить владельца $PWFILE"

  log_info "Запускаем initdb..."
  su-exec postgres initdb --auth=scram-sha-256 --pwfile="$PWFILE" || exit_with_error "Ошибка при инициализации базы данных"

  rm -f "$PWFILE"

  log_info "Содержимое $PGDATA после initdb:"
  ls -l "$PGDATA" || log_warn "Не удалось отобразить содержимое $PGDATA"
}

configure_conf_files() {
  if [ ! -f "$PGDATA/postgresql.conf" ]; then
    exit_with_error "Файл postgresql.conf не найден в $PGDATA!"
  fi

  log_info "Настройка файла postgresql.conf"
  sed -i "/^listen_addresses/c\listen_addresses = '*'" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось настроить listen_addresses"
  sed -i "/^password_encryption/c\password_encryption = 'scram-sha-256'" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось настроить password_encryption"

  if ! grep -q "^host all all 0.0.0.0/0 scram-sha-256" "$PGDATA/pg_hba.conf"; then
    log_info "Добавляем правило в pg_hba.conf для SCRAM аутентификации"
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf" || exit_with_error "Не удалось обновить pg_hba.conf"
  else
    log_info "Правило для SCRAM аутентификации уже существует в pg_hba.conf"
  fi
}

enable_full_logging() {
  log_info "Включаем полное логирование PostgreSQL"

  sed -i "/^log_connections/c\log_connections = on" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось включить log_connections"
  sed -i "/^log_disconnections/c\log_disconnections = on" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось включить log_disconnections"
  sed -i "/^logging_collector/c\logging_collector = on" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось включить logging_collector"
  sed -i "/^log_destination/c\log_destination = 'stderr'" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось настроить log_destination"
  sed -i "/^log_line_prefix/c\log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось настроить log_line_prefix"
  sed -i "/^log_statement/c\log_statement = 'all'" "$PGDATA/postgresql.conf" || exit_with_error "Не удалось включить log_statement"
}

start_postgres() {
  log_info "Запуск PostgreSQL..."

  export PGPASSWORD="$PG_SUPERPASS"

  su-exec postgres postgres &

  log_info "Ожидание запуска PostgreSQL (максимум 30 секунд)..."
  timeout=30
  while [ $timeout -gt 0 ]; do
    if su-exec postgres pg_isready -q; then
      log_info "PostgreSQL готов к подключениям"
      return 0
    fi
    sleep 1
    timeout=$((timeout - 1))
  done

  exit_with_error "PostgreSQL не запустился вовремя"
}

create_db_and_user() {
  log_info "Проверка существования базы данных '$DB_NAME'..."
  if ! su-exec postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    log_info "Создаем базу данных '$DB_NAME'"
    su-exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\"" || exit_with_error "Не удалось создать базу данных '$DB_NAME'"
  else
    log_info "База данных '$DB_NAME' уже существует"
  fi

  log_info "Проверка существования пользователя '$DB_USER'..."
  if ! su-exec postgres psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    log_info "Создаем пользователя '$DB_USER'"
    su-exec postgres psql -U postgres -c "CREATE ROLE \"$DB_USER\" WITH LOGIN PASSWORD '$DB_PASS'" || exit_with_error "Не удалось создать пользователя '$DB_USER'"
  else
    log_info "Пользователь '$DB_USER' уже существует"
  fi

  log_info "Выдаем все привилегии пользователю '$DB_USER' на базу '$DB_NAME'"
  su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\"" || exit_with_error "Не удалось выдать привилегии"
}

main() {
  read_config

  check_data_directory

  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    log_info "Файл PG_VERSION не найден — инициализируем БД заново"
    init_db
  else
    log_info "PostgreSQL уже инициализирован (файл PG_VERSION найден)"
  fi

  configure_conf_files

  enable_full_logging

  start_postgres
  create_db_and_user

  log_info "Скрипт завершён успешно. PostgreSQL готов к работе."
  wait
}

main