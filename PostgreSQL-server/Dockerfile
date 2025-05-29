# Используем чистый PostgreSQL-образ
FROM postgres:17.5-alpine

# Устанавливаем утилиты для чтения JSON и смены пользователя
RUN apk add --no-cache jq su-exec

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Путь к хранилищу данных PostgreSQL (по умолчанию в образе)
ENV PGDATA=/data

CMD ["/run.sh"]
