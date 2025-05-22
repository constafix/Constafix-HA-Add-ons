FROM postgres:16-alpine

# Установка необходимых утилит
RUN apk add --no-cache su-exec jq

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Задаём рабочую директорию PostgreSQL
ENV PGDATA=/var/lib/postgresql/data

CMD [ "/run.sh" ]
