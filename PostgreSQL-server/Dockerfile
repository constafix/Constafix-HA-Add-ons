ARG BUILD_FROM
FROM $BUILD_FROM

# Устанавливаем PostgreSQL
RUN apk add --no-cache postgresql postgresql-client su-exec

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
