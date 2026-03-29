FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow

LABEL maintainer="1C Home Server"
LABEL description="PostgreSQL 1C for 1C Enterprise"

ENV PGDATA=/var/lib/postgresql/data
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=template1c

RUN apt-get update && apt-get install -y \
    wget curl ca-certificates gnupg bzip2 sudo \
    tzdata locales \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen ru_RU.UTF-8
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

RUN useradd -m -s /bin/bash postgres && \
    echo "postgres:postgres" | chpasswd && \
    adduser postgres sudo

COPY postgresql_*.tar.bz2 /tmp/

WORKDIR /tmp
RUN tar -xjf postgresql_*.tar.bz2 && \
    apt-get update && apt-get install -y \
        libjson-perl ssl-cert ucf perl \
    && ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    dpkg -i postgresql-common_*.deb || true && \
    dpkg -i postgresql-client-common_*.deb || true && \
    dpkg -i libpq5_*.deb || true && \
    dpkg -i libpgtypes3_*.deb || true && \
    dpkg -i libecpg6_*.deb || true && \
    dpkg -i libecpg-compat3_*.deb || true && \
    dpkg -i postgresql-client-18_*.deb || true && \
    dpkg -i postgresql-18_*.deb || true && \
    apt-get install -f -y && \
    rm -rf /tmp/postgresql-*.tar.bz2 /tmp/*.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $PGDATA && \
    chown -R postgres:postgres $PGDATA

COPY entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && \
    chown postgres:postgres /docker-entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/docker-entrypoint.sh"]