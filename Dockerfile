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
ARG USER_ID=1000
ARG GROUP_ID=1000

COPY $FilesDir/* $DeploymentDir/

RUN	mkdir -p $CustomDictionariesDir &&\
	mkdir $CertDir &&\
	mv $DeploymentDir/$CertKeyName $CertDir/$CertKeyName &&\
	mv $DeploymentDir/$CertFileName $CertDir/$CertFileName &&\
	apt-get update -y &&\
	apt-get install -y apache2 default-jre wget &&\
	tar -xvf $DeploymentDir/$AppNameMask -C $DeploymentDir/ &&\
	rm $DeploymentDir/$AppNameMask &&\
	mv $AppRootDir* $AppRootDir &&\
	perl $DeploymentDir/configureApachePorts.pl $WebServerPort $WebServerSSLPort &&\
	if [ "$ssl" = "true" ]; then perl $DeploymentDir/enableSSL.pl; fi &&\
	mv $DeploymentDir/config.ini $AppRootDir/ &&\
	mv $DeploymentDir/configSSL.ini $AppRootDir/ &&\
	if [ "$ssl" = "true" ]; then perl $AppRootDir/automated_install.pl $AppRootDir/configSSL.ini; else perl $AppRootDir/automated_install.pl $AppRootDir/config.ini; fi &&\
	mv $DeploymentDir/configureFiles.pl $AppServerDir &&\
	mv $DeploymentDir/startService.sh $AppServerDir &&\
	chmod +x $AppServerDir/startService.sh &&\
	rm -rf /$DeploymentDir &&\
	mkdir -p $LicenseDir &&\
	groupadd -g ${GROUP_ID} $UserName && useradd -l -u ${USER_ID} -g $UserName $UserName &&\
	install -d -m 0755 -o $UserName -g $UserName /home/$UserName &&\
	chown -R ${USER_ID}:${GROUP_ID} $LicenseDir $DictionariesDir /opt/WSC /var/run/apache2 /var/log/apache2 /var/lock/apache2

USER $UserName

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
