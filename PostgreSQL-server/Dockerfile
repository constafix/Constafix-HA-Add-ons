FROM postgres:17.5

ENV PGDATA=/data/postgresql

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
