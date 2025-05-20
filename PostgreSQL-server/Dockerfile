FROM postgres:15

# Переменная среды по умолчанию
ENV PGDATA=/var/lib/postgresql/data

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
