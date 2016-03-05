FROM alpine:latest
MAINTAINER celeron1ghz <celeron1ghz@gmail.com>
WORKDIR /root/Hirukara-Web

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update --virtual=build-tools alpine-sdk git wget openssl-dev perl \
    && apk add --update mariadb-dev wkhtmltopdf \
    && wget https://raw.githubusercontent.com/tokuhirom/Perl-Build/master/perl-build -O - | perl - 5.20.1 /opt/perl-5.20/ \
    && wget https://cpanmin.us/ -O - | /opt/perl-5.20/bin/perl - App::cpanminus Carton \
    && git clone https://github.com/celeron1ghz/p5-Hirukara-Web ~/Hirukara-Web \
    && /opt/perl-5.20/bin/perl /opt/perl-5.20/bin/carton install \
    && rm -Rf ~/.cpanm \
    && apk del build-tools \
    && rm /usr/lib/libmysqld* \
    && rm /usr/bin/mysql*

EXPOSE 2525
CMD /opt/perl-5.20/bin/carton exec plackup \
    -s Starlet    \
    -a script/hirukara-server \
    -E production \
    --port 2525   \
    --max-workers 1
