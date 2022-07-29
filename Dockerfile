FROM ubuntu

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
ARG USER_ID=2000
ARG GROUP_ID=2000

ENV PROTOCOL=
ENV HOST_NAME=
ENV LICENSE_TICKET_ID=

COPY $FilesDir/* $DeploymentDir/

RUN	mkdir -p $CustomDictionariesDir && mkdir -p $UserDictionariesDir &&\
	mkdir $CertDir &&\
	mv $DeploymentDir/$CertKeyName $CertDir/$CertKeyName &&\
	mv $DeploymentDir/$CertFileName $CertDir/$CertFileName &&\
	apt-get update -y &&\
	apt-get install -y nginx default-jre wget &&\
	apt-get upgrade -y perl &&\
	tar -xvf $DeploymentDir/$AppNameMask -C $DeploymentDir/ &&\
	rm $DeploymentDir/$AppNameMask &&\
	mv $AppRootDir* $AppRootDir &&\
	mv $DeploymentDir/config.ini $AppRootDir/ &&\
	mkdir /var/run/nginx &&\
	perl $AppRootDir/automated_install.pl $AppRootDir/config.ini &&\
	mv $DeploymentDir/configureWebServer.pl $AppServerDir &&\
	mv $DeploymentDir/configureFiles.pl $AppServerDir &&\
	mv $DeploymentDir/startService.sh $AppServerDir &&\
	chmod +x $AppServerDir/startService.sh &&\
	rm -rf /$DeploymentDir &&\
	mkdir -p $LicenseDir &&\
	rm /etc/nginx/sites-enabled/default &&\
	groupadd -g ${GROUP_ID} $UserName && useradd -u ${USER_ID} -g ${GROUP_ID} $UserName &&\
	chown -R ${USER_ID}:${GROUP_ID} $LicenseDir $DictionariesDir /opt/WSC /var/log/nginx /usr/sbin/nginx /var/lib/nginx /var/run/nginx /etc/nginx

USER $UserName

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
