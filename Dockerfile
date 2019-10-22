FROM ubuntu

EXPOSE 80
EXPOSE 2880

RUN apt-get update -y
RUN apt-get install -y tar
RUN apt-get install -y perl
RUN apt-get install -y apache2
RUN apt-get install -y default-jre

ARG DeploymentDir=downloads
ARG DictionariesDir=dictionaries
ARG FilesDir=./files
ARG AppServerDir=/opt/WSC/AppServer

RUN mkdir $DeploymentDir
RUN mkdir $DictionariesDir

WORKDIR /$DeploymentDir
COPY $FilesDir/wsc_app* /$DeploymentDir
RUN tar -xvf wsc_app*
RUN rm wsc_app*

ARG VERSION
COPY ./files/config.ini /downloads/WSC_$VERSION

WORKDIR /downloads/WSC_$VERSION
RUN perl automated_install.pl config.ini

COPY $FilesDir/configureFiles.pl $AppServerDir
COPY $FilesDir/startService.sh $AppServerDir
RUN chmod +x $AppServerDir/startService.sh

ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
