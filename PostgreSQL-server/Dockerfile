FROM postgres:16-alpine

# Установка su-exec для запуска под другим пользователем
RUN apk add --no-cache su-exec

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]