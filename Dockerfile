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
ARG protocol=2
# Web port outside the container. If value isn't specified (e.g. empty), the default value will be used (443 for HTTPS and 80 for HTTP).
ARG web_port
ARG domain_name=localhost
ARG virtual_dir=wscservice
# Change to 1 to activate the license during the image build. 
ARG activate_license=0
# Specify license ticket ID if activate_license is set to 1. For example, license_ticket_id = 6u*************ZO
ARG license_ticket_id
ARG products=4
ARG languages_to_install=1,2
ARG install_samples=1

# Proxy server settings
# If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 
ARG enable_proxy=0
ARG proxy_host
ARG proxy_port
ARG proxy_user_name
ARG proxy_password

ENV file_owner=${USER_ID}:${GROUP_ID}
ENV products=${products}
ENV languages_to_install=${languages_to_install}
ENV install_samples=${install_samples}
ENV protocol=${protocol}
ENV domain_name=${domain_name}
ENV web_port=${web_port}
ENV virtual_dir=${virtual_dir}
ENV web_server_type=2
ENV activate_license=${activate_license}
ENV license_ticket_id=${license_ticket_id}
ENV restart_web_server=1

ENV enable_proxy=${enable_proxy}
ENV proxy_host=${proxy_host}
ENV proxy_port=${proxy_port}
ENV proxy_user_name=${proxy_user_name}
ENV proxy_password=${proxy_password}

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
