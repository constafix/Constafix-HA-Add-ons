ARG BUILD_FROM
FROM $BUILD_FROM

# Установка нужных утилит
RUN apk add --no-cache curl jq su-exec

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
