FROM celeron1ghz/perl:5.20.1
MAINTAINER celeron1ghz

## installing wkhtmltopdf
RUN apt-get update && apt-get -y install wkhtmltopdf libssl-dev sqlite3

## application install
RUN git clone git://github.com/celeron1ghz/p5-Hirukara-Lite ~/p5-Hirukara-Lite

## application setup
WORKDIR /root/p5-Hirukara-Lite
ADD . /root/p5-Hirukara-Lite/
RUN /root/.plenv/shims/carton
RUN sqlite3 moge.db < CREATE.sql

## running server
EXPOSE 2525
CMD /root/.plenv/shims/carton exec plackup --port 2525
