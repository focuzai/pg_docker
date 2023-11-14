FROM postgres:14.7
LABEL MAINTAINER Harrison Chumpitaz <hchumpitaz92@gmail.com>

USER root
RUN localedef -i es_ES -c -f UTF-8 -A /usr/share/locale/locale.alias es_ES.UTF-8

ENV LANG es_ES.utf8

# COPY postgresql.conf /var/lib/postgresql/data/
# COPY postgresql.conf.sample /usr/share/postgresql/
COPY init.sql /docker-entrypoint-initdb.d/