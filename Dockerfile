FROM ubuntu

ARG WebServerPort=8080
ARG WebServerSSLPort=8443

EXPOSE $WebServerPort
EXPOSE $WebServerSSLPort
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
ARG ssl=false
ARG UserName=wsc
ARG LicenseDir=/var/lib/wsc/license
ARG USER_ID=2000
ARG GROUP_ID=2000

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
	mv $DeploymentDir/configSSL.ini $AppRootDir/ &&\
	mkdir /var/run/nginx &&\
	if [ "$ssl" = "true" ]; then perl $AppRootDir/automated_install.pl $AppRootDir/configSSL.ini; else perl $AppRootDir/automated_install.pl $AppRootDir/config.ini; fi &&\
	perl $DeploymentDir/configureWebServer.pl $ssl $WebServerPort $WebServerSSLPort &&\
	mv $DeploymentDir/configureFiles.pl $AppServerDir &&\
	mv $DeploymentDir/startService.sh $AppServerDir &&\
	chmod +x $AppServerDir/startService.sh &&\
	rm -rf /$DeploymentDir &&\
	mkdir -p $LicenseDir &&\
	groupadd -g ${GROUP_ID} $UserName && useradd -u ${USER_ID} -g ${GROUP_ID} $UserName &&\
	chown -R ${USER_ID}:${GROUP_ID} $LicenseDir $DictionariesDir /opt/WSC /var/log/nginx /usr/sbin/nginx /var/lib/nginx /var/run/nginx

USER $UserName

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
