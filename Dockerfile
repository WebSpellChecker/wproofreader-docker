# the latest stable Ubuntu package
FROM ubuntu
# the web server port address
EXPOSE 80
EXPOSE 443
# AppServer port address
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
# install the latest stable version of Apache HTTP Server
RUN apt-get install -y apache2
# install the latest stable version of Java Runtime Environment (JRE). It is required for the grammar engine.
RUN apt-get install -y default-jre

# define a constant with the name of the directory where to extract the package files
ARG DeploymentDir=downloads
# define a constant with the name of the directory which will be used for shared dictionaries inside the container
ARG DictionariesDir=dictionaries
ARG FilesDir=./files
ARG AppRootFolder=WSC
ARG AppServerDir=/opt/$AppRootFolder/AppServer
# defined a constant with the name of the application without its version
ARG AppNameMask=wsc_app*
ARG ssl=false
ARG CertDir=certificate

# create a directory for deployment
RUN mkdir $DeploymentDir
# create a directory for shared dictionaries
RUN mkdir $DictionariesDir
#create a directory for an SSL certificate files
RUN mkdir $CertDir

# change the working directory to the deployment directory
WORKDIR /$DeploymentDir
# copy the installation package to the deployment directory
COPY $FilesDir/$AppNameMask /$DeploymentDir
# extract the package contents from the archive
RUN tar -xvf $AppNameMask
# delete the package achieve
RUN rm $AppNameMask
# rename WSC_x.x.x into WSC
RUN mv $AppRootFolder* $AppRootFolder

#enable SSL if needed
COPY $FilesDir/$CertDir/ /$CertDir
COPY $FilesDir/enableSSL.pl /$DeploymentDir
RUN if [ "$ssl" = "true" ]; then perl enableSSL.pl;  fi

# copy  the config.ini file to the application root directory
COPY $FilesDir/config.ini $FilesDir/configSSL.ini /$DeploymentDir/$AppRootFolder/
# change the working directory to the application root directory
WORKDIR /downloads/$AppRootFolder
# run the automated installation using the config.ini file
RUN if [ "$ssl" = "true" ]; then perl automated_install.pl configSSL.ini; else perl automated_install.pl config.ini; fi

# copy the configureFiles.pl file to the directory with the application
COPY $FilesDir/configureFiles.pl $AppServerDir
# copy the startService.sh file to the directory with the application
COPY $FilesDir/startService.sh $AppServerDir
# grant permissions to launch the file for any user
RUN chmod +x $AppServerDir/startService.sh

WORKDIR /opt/$AppRootFolder
RUN rm -rf /$DeploymentDir

# start the required services for the application when launching the container
ENTRYPOINT ["/opt/WSC/AppServer/startService.sh"]
