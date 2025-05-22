ARG BUILD_FROM
FROM $BUILD_FROM

# Установка зависимостей и bashio
RUN apk add --no-cache bash curl jq su-exec \
    && curl -sSL https://raw.githubusercontent.com/hassio-addons/bashio/master/install.sh | bash

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]