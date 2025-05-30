#!/bin/sh

set -euo pipefail

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Префикс для логов
LOG_PREFIX="[custom_postgres]"
LOG_INDENT="  "

# Переменные
CONFIG=/data/options.json
export PGDATA="/data/data/postgres"
timeout=30

# Функции логирования
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
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

# Очистка при завершении
cleanup() {
    log_info "Получен сигнал завершения. Останавливаем PostgreSQL..."
    su-exec postgres pg_ctl -D "$PGDATA" -m fast stop
}

# Обработка сигналов
trap cleanup SIGTERM SIGINT
trap 'exit_with_error "Скрипт прерван с ошибкой на строке $LINENO"' ERR

# Чтение конфигурации
read_config() {
    log_info "Чтение конфигурации из $CONFIG..."
    DB_NAME=$(jq --raw-output '.database' "$CONFIG") || exit_with_error "Ошибка чтения database из конфига"
    DB_USER=$(jq --raw-output '.username' "$CONFIG") || exit_with_error "Ошибка чтения username из конфига"
    DB_PASS=$(jq --raw-output '.password' "$CONFIG") || exit_with_error "Ошибка чтения password из конфига"
    PG_SUPERPASS=$(jq --raw-output '.postgres_password' "$CONFIG") || exit_with_error "Ошибка чтения postgres_password из конфига"

    # Проверка длины паролей
    if [ ${#DB_PASS} -lt 8 ]; then
        exit_with_error "Пароль пользователя должен содержать минимум 8 символов"
    fi
    if [ ${#PG_SUPERPASS} -lt 8 ]; then
        exit_with_error "Пароль суперпользователя должен содержать минимум 8 символов"
    fi

    log_info "Конфигурация: database='$DB_NAME', username='$DB_USER', (пароли скрыты)"
}

# Проверка директории данных
check_data_directory() {
    log_info "Проверка наличия и прав папки данных $PGDATA..."
    log_info "Абсолютный путь к папке данных: $(realpath $PGDATA)"

    if [ ! -d "$PGDATA" ]; then
        log_warn "Папка данных $PGDATA не существует. Пытаюсь создать..."
        mkdir -p "$PGDATA" || exit_with_error "Не удалось создать папку данных $PGDATA"
        log_info "Папка $PGDATA успешно создана."
    else
        log_info "Папка данных $PGDATA существует."
    fi

    ls -ld "$PGDATA" || log_warn "Не удалось получить подробности папки $PGDATA"

    # Проверка прав на запись
    if [ ! -w "$PGDATA" ]; then
        exit_with_error "Папка $PGDATA недоступна для записи!"
    else
        log_info "Права на запись в папку $PGDATA установлены."
    fi

    # Установка владельца
    chown -R postgres:postgres "$PGDATA" || exit_with_error "Не удалось изменить владельца папки $PGDATA"

    # Проверка наличия PG_VERSION
    if [ -f "$PGDATA/PG_VERSION" ]; then
        log_info "Файл PG_VERSION найден. База данных уже инициализирована."
        return 0
    fi

    # Проверка на пустоту папки
    if [ "$(ls -A "$PGDATA")" ]; then
        exit_with_error "Папка $PGDATA не пуста, но файл PG_VERSION отсутствует. Проверьте содержимое папки."
    fi
}

# Инициализация базы данных
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

# Настройка конфигурационных файлов
configure_conf_files() {
    if [ ! -f "$PGDATA/postgresql.conf" ]; then
        exit_with_error "Файл postgresql.conf не найден в $PGDATA!"
    fi

    log_info "Настройка postgresql.conf..."
    cat >> "$PGDATA/postgresql.conf" <<EOF
listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB
EOF

    log_info "Настройка pg_hba.conf..."
    cat > "$PGDATA/pg_hba.conf" <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32           scram-sha-256
host    all             all             ::1/128                 scram-sha-256
host    all             all             0.0.0.0/0              scram-sha-256
EOF
}

# Включение полного логирования
enable_full_logging() {
    log_info "Включение расширенного логирования..."
    cat >> "$PGDATA/postgresql.conf" <<EOF
log_destination = 'stderr'
logging_collector = off
log_min_messages = warning
log_min_error_statement = error
log_min_duration_statement = 1000
EOF
}

# Запуск PostgreSQL
start_postgres() {
    log_info "Запуск PostgreSQL..."
    su-exec postgres pg_ctl -D "$PGDATA" -w start

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

# Создание базы данных и пользователя
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
        log_info "Обновляем пароль пользователя '$DB_USER'"
        su-exec postgres psql -U postgres -c "ALTER USER \"$DB_USER\" WITH PASSWORD '$DB_PASS'" || exit_with_error "Не удалось обновить пароль пользователя '$DB_USER'"
    fi

    log_info "Выдаем все привилегии пользователю '$DB_USER' на базу '$DB_NAME'"
    su-exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\"" || exit_with_error "Не удалось выдать привилегии"
}

# Основная функция
main() {
    log_info "Запуск PostgreSQL Server аддона..."
    log_info "Версия PostgreSQL: $(postgres --version)"
    
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