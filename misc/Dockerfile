FROM celeron1ghz/base:2.0
MAINTAINER celeron1ghz

## installing wkhtmltopdf
RUN apt-get update && apt-get -y install wkhtmltopdf

## application install
RUN git clone git://github.com/celeron1ghz/p5-Hirukara-Lite ~/p5-Hirukara-Lite

## application setup
WORKDIR /root/p5-Hirukara-Lite
ADD . /root/p5-Hirukara-Lite/
RUN carton
RUN sqlite3 moge.db < CREATE.sql

## running server
EXPOSE 2525
CMD carton exec plackup --port 2525
