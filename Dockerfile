FROM ubuntu

ARG ApachePort=8080
ARG ApacheSSLPort=8443

EXPOSE $ApachePort
EXPOSE $ApacheSSLPort
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive

ARG FilesDir=./files
ARG DeploymentDir=/home
ARG DictionariesDir=/dictionaries
ARG CertDir=/certificate
ARG CertKeyName=key.pem
ARG CertFileName=cert.pem
ARG AppRootName=WSC
ARG AppRootDir=$DeploymentDir/$AppRootName
ARG AppServerDir=/opt/$AppRootName/AppServer
ARG AppNameMask=wsc_app*
ARG ssl=false
ARG User=www-data
ARG LicenseDir=/var/lib/wsc/license

COPY $FilesDir/* $DeploymentDir/

RUN	mkdir $DictionariesDir &&\
	mkdir $CertDir &&\
	mv $DeploymentDir/$CertKeyName $CertDir/$CertKeyName &&\
	mv $DeploymentDir/$CertFileName $CertDir/$CertFileName &&\
	apt-get update -y &&\
	apt-get install -y apache2 default-jre wget &&\
	tar -xvf $DeploymentDir/$AppNameMask -C $DeploymentDir/ &&\
	rm $DeploymentDir/$AppNameMask &&\
	mv $AppRootDir* $AppRootDir &&\
	perl $DeploymentDir/configureApachePorts.pl $ApachePort $ApacheSSLPort &&\
	if [ "$ssl" = "true" ]; then perl $DeploymentDir/enableSSL.pl; fi &&\
	mv $DeploymentDir/config.ini $AppRootDir/ &&\
	mv $DeploymentDir/configSSL.ini $AppRootDir/ &&\
	if [ "$ssl" = "true" ]; then perl $AppRootDir/automated_install.pl $AppRootDir/configSSL.ini; else perl $AppRootDir/automated_install.pl $AppRootDir/config.ini; fi &&\
	mv $DeploymentDir/configureFiles.pl $AppServerDir &&\
	mv $DeploymentDir/startService.sh $AppServerDir &&\
	chmod +x $AppServerDir/startService.sh &&\
	rm -rf /$DeploymentDir &&\
	mkdir -p $LicenseDir &&\
	chown -R $User $LicenseDir /var/run/apache2 /var/log/apache2 /var/lock/apache2

USER $User

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
