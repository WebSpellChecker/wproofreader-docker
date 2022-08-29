FROM ubuntu:22.04

ARG WEB_SERVER_PORT=8080
ARG WEB_SERVER_SSL_PORT=8443

ENV WEB_SERVER_PORT=${WEB_SERVER_PORT}
ENV WEB_SERVER_SSL_PORT=${WEB_SERVER_SSL_PORT}

EXPOSE $WEB_SERVER_PORT
EXPOSE $WEB_SERVER_SSL_PORT
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive

ARG FilesDir=./files
ARG DeploymentDir=/home
ARG DictionariesDir=/dictionaries
ARG CustomDictionariesDir=$DictionariesDir/CustomDictionaries
ARG UserDictionariesDir=$DictionariesDir/UserDictionaries
ARG CertDir=/certificate
ARG CertKeyName=key.pem
ARG CertFileName=cert.pem
ARG AppRootName=WSC
ARG AppRootDir=$DeploymentDir/$AppRootName
ARG AppServerDir=/opt/$AppRootName/AppServer
ARG AppNameMask=wsc_app*
ARG UserName=wsc
ARG LicenseDir=/var/lib/wsc/license
# Sets a user ID for the default user in the container. 
ARG USER_ID=2000
# Sets a user group ID for the default user in the container.
ARG GROUP_ID=2000

ENV WSC_AUTO_INSTALL=TRUE

# Application installation parameters
# Protocol of the NGINX web server (1 - HTTPS, 2 - HTTP)
ARG PROTOCOL=2
# Web port outside the container. If value isn't specified (e.g. empty), the default value will be used (443 for HTTPS and 80 for HTTP).
ARG WEB_PORT
ARG DOMAIN_NAME=localhost
ARG VIRTUAL_DIR=wscservice
# Change to 1 to activate the license during the image build. 
ARG ACTIVATE_LICENSE=0
# Specify license ticket ID if ACTIVATE_LICENSE is set to 1. For example, LICENSE_TICKET_ID = 6u*************ZO
ARG LICENSE_TICKET_ID
ARG PRODUCTS=4
ARG LANGUAGES_TO_INSTALL=1,2
ARG INSTALL_SAMPLES=1

# Proxy server settings
# If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 
ARG ENABLE_PROXY=0
ARG PROXY_HOST
ARG PROXY_PORT
ARG PROXY_USER_NAME
ARG PROXY_PASSWORD

ENV FILE_OWNER=${USER_ID}:${GROUP_ID}
ENV PRODUCTS=${PRODUCTS}
ENV LANGUAGES_TO_INSTALL=${LANGUAGES_TO_INSTALL}
ENV INSTALL_SAMPLES=${INSTALL_SAMPLES}
ENV PROTOCOL=${PROTOCOL}
ENV DOMAIN_NAME=${DOMAIN_NAME}
ENV WEB_PORT=${WEB_PORT}
ENV VIRTUAL_DIR=${VIRTUAL_DIR}
ENV WEB_SERVER_TYPE=2
ENV ACTIVATE_LICENSE=${ACTIVATE_LICENSE}
ENV LICENSE_TICKET_ID=${LICENSE_TICKET_ID}
ENV RESTART_WEB_SERVER=1

ENV ENABLE_PROXY=${ENABLE_PROXY}
ENV PROXY_HOST=${PROXY_HOST}
ENV PROXY_PORT=${PROXY_PORT}
ENV PROXY_USER_NAME=${PROXY_USER_NAME}
ENV PROXY_PASSWORD=${PROXY_PASSWORD}

RUN apt-get update -y &&\
    apt-get install -y nginx default-jre wget vim nano mc &&\
    apt-get upgrade -y perl &&\
    apt-get clean

RUN	mkdir -p $CustomDictionariesDir $UserDictionariesDir $LicenseDir /var/run/nginx

COPY $FilesDir/certificate $CertDir

COPY $FilesDir/$AppNameMask $DeploymentDir/

RUN tar -xvf $DeploymentDir/$AppNameMask -C $DeploymentDir/ &&\
    rm $DeploymentDir/$AppNameMask &&\
    perl $AppRootDir*/automated_install.pl &&\
    rm -rf $AppRootDir* &&\
    groupadd -g ${GROUP_ID} $UserName && useradd -u ${USER_ID} -g ${GROUP_ID} $UserName &&\
    chown -R ${USER_ID}:${GROUP_ID} $LicenseDir $DictionariesDir /opt/WSC /var/log/nginx /usr/sbin/nginx /var/lib/nginx /var/run/nginx /etc/nginx

COPY $FilesDir/configure* $AppServerDir
COPY $FilesDir/startService.sh $AppServerDir

RUN chmod +x $AppServerDir/startService.sh &&\
    rm -f /etc/nginx/sites-enabled/default

RUN rm -rf $AppServerDir/Logs &&\
    mkdir -p $AppServerDir/Logs &&\
    ln -s /dev/stdout $AppServerDir/Logs/Main.log &&\
    ln -s /dev/stdout $AppServerDir/Logs/Child-0.log &&\
    ln -s /dev/stdout $AppServerDir/Logs/Child-1.log &&\
    ln -s /dev/stdout $AppServerDir/Logs/Action.log &&\
    chown -R ${USER_ID}:${GROUP_ID} $AppServerDir/Logs

USER $UserName

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
