FROM ubuntu

EXPOSE 80
EXPOSE 2880

RUN apt-get update -y
RUN apt-get install -y tar
RUN apt-get install -y perl
RUN apt-get install -y apache2
RUN apt-get install -y default-jre

RUN mkdir dictionaries
RUN mkdir downloads
WORKDIR /downloads
COPY ./files/wsc_app* /downloads
RUN tar -xvf wsc_app*
RUN rm wsc_app*

ARG VERSION
COPY ./files/config.ini /downloads/WSC_$VERSION
WORKDIR /downloads/WSC_$VERSION

RUN perl automated_install.pl config.ini

COPY ./files/configureFiles.pl /opt/WSC/AppServer
COPY ./files/startService.sh /opt/WSC/AppServer
RUN chmod +x /opt/WSC/AppServer/startService.sh

ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
