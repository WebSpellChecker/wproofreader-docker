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

ENV WSC_AUTO_INSTALL=TRUE

ARG file_owner=33:33
ARG products=4
ARG languages_to_install=0
ARG install_samples=1
ARG protocol=2
ARG domain_name=localhost
ARG web_port
ARG virtual_dir=wscservice
ARG web_server_type=2
ARG activate_license=0
ARG license_ticket_id
ARG restart_web_server=1
ARG enable_proxy=0
ARG proxy_host
ARG proxy_port
ARG proxy_user_name
ARG proxy_password

ENV file_owner=${file_owner}
ENV products=${products}
ENV languages_to_install=${languages_to_install}
ENV install_samples=${install_samples}
ENV protocol=${protocol}
ENV domain_name=${domain_name}
ENV web_port=${web_port}
ENV virtual_dir=${virtual_dir}
ENV web_server_type=${web_server_type}
ENV activate_license=${activate_license}
ENV license_ticket_id=${license_ticket_id}
ENV restart_web_server=${restart_web_server}
ENV enable_proxy=${enable_proxy}
ENV proxy_host=${proxy_host}
ENV proxy_port=${proxy_port}
ENV proxy_user_name=${proxy_user_name}
ENV proxy_password=${proxy_password}

COPY $FilesDir/* $DeploymentDir/

RUN	mkdir -p $CustomDictionariesDir &&\
	mkdir -p $UserDictionariesDir &&\
	mkdir $CertDir &&\
	mv $DeploymentDir/$CertKeyName $CertDir/$CertKeyName &&\
	mv $DeploymentDir/$CertFileName $CertDir/$CertFileName &&\
	apt-get update -y &&\
	apt-get install -y nginx default-jre wget &&\
	apt-get upgrade -y perl &&\
	tar -xvf $DeploymentDir/$AppNameMask -C $DeploymentDir/ &&\
	rm $DeploymentDir/$AppNameMask &&\
	mv $AppRootDir* $AppRootDir &&\
	mkdir /var/run/nginx &&\
	perl $AppRootDir/automated_install.pl &&\
	mv $DeploymentDir/configureWebServer.pl $AppServerDir &&\
	mv $DeploymentDir/configureFiles.pl $AppServerDir &&\
	mv $DeploymentDir/startService.sh $AppServerDir &&\
	chmod +x $AppServerDir/startService.sh &&\
	rm -rf /$DeploymentDir &&\
	mkdir -p $LicenseDir &&\
	rm -f /etc/nginx/sites-enabled/default &&\
	groupadd -g ${GROUP_ID} $UserName && useradd -u ${USER_ID} -g ${GROUP_ID} $UserName &&\
	chown -R ${USER_ID}:${GROUP_ID} $LicenseDir $DictionariesDir /opt/WSC /var/log/nginx /usr/sbin/nginx /var/lib/nginx /var/run/nginx /etc/nginx

USER $UserName

WORKDIR /opt/$AppRootName
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
