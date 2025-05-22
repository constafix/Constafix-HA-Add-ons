ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8
ENV PGDATA=/var/lib/postgresql/data

# Установка зависимостей и bashio
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    su-exec \
    postgresql \
    postgresql-client \
    postgresql-contrib \
 && curl -sSL https://raw.githubusercontent.com/hassio-addons/bashio/master/install.sh | bash

# Создание директории для данных PostgreSQL
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
