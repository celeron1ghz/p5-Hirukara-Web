FROM debian:latest
MAINTAINER celeron1ghz <celeron1ghz@gmail.com>

RUN apt-get update \
    && apt-get -y install wkhtmltopdf \
    && apt-get -y install git \
    && apt-get -y install wget \
    && apt-get -y install build-essential \
    && apt-get -y install libssl-dev \
    && apt-get -y install sqlite3 \
    && apt-get -y install memcached \
    && apt-get clean

RUN wget https://cpanmin.us/ -O cpanm \
    && perl ./cpanm \
    && perl ./cpanm Carton \
    && rm   ./cpanm

RUN git clone git://github.com/celeron1ghz/p5-Hirukara-Web ~/p5-Hirukara-Web

## app init
WORKDIR /root/p5-Hirukara-Web
RUN sqlite3 db/development.db < sql/sqlite.sql

ADD cpanfile /root/p5-Hirukara-Web/cpanfile
RUN carton install

ADD config/development.pl /root/p5-Hirukara-Web/config/development.pl

## running server
EXPOSE 2525
CMD memcached -d; carton exec plackup -s Starlet -a script/hirukara-server --port 2525
