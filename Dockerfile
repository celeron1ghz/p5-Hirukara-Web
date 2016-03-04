FROM debian:latest
MAINTAINER celeron1ghz <celeron1ghz@gmail.com>
WORKDIR /root/Hirukara-Web

RUN apt-get update \
    && apt-get -y install build-essential git wget libssl-dev sqlite3 libmysqlclient-dev wkhtmltopdf \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
    && wget https://cpanmin.us/ -O - | perl - App::cpanminus Carton \
    && git clone https://github.com/celeron1ghz/p5-Hirukara-Web ~/Hirukara-Web \
    && carton install && rm -Rf ~/.cpanm

EXPOSE 2525
CMD carton exec plackup \
    -s Starlet    \
    -a script/hirukara-server \
    -E production \
    --port 2525   \
    --max-workers 1
