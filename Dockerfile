FROM ubuntu

EXPOSE 80
EXPOSE 2880

RUN apt-get update -y
RUN apt-get install -y apache2
RUN apt-get install -y default-jre

ARG DeploymentDir=downloads
ARG DictionariesDir=dictionaries
ARG FilesDir=./files
ARG AppRootFolder=WSC
ARG AppServerDir=/opt/$AppRootFolder/AppServer
ARG AppNameMask=wsc_app*

RUN mkdir $DeploymentDir
RUN mkdir $DictionariesDir

WORKDIR /$DeploymentDir
COPY $FilesDir/$AppNameMask /$DeploymentDir
RUN tar -xvf $AppNameMask
RUN rm $AppNameMask
RUN mv $AppRootFolder* $AppRootFolder

COPY $FilesDir/config.ini /$DeploymentDir/$AppRootFolder
WORKDIR /downloads/$AppRootFolder
RUN perl automated_install.pl config.ini

COPY $FilesDir/configureFiles.pl $AppServerDir
COPY $FilesDir/startService.sh $AppServerDir
RUN chmod +x $AppServerDir/startService.sh

ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
