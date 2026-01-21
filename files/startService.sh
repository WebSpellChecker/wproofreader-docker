#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# export the libraries required for the service start
export LD_LIBRARY_PATH="$(pwd)/lib"
export MARIADB_PLUGIN_DIR="$(pwd)/lib"

ConfigureFlag="wsc_start_configured"
if [ ! -e "$(pwd)/${ConfigureFlag}" ]; then

# run script to configure web server files
perl configureWebServer.pl
# run script to configure samples and shared dictionaries
perl configureFiles.pl

touch "${ConfigureFlag}"

fi

# activate a license automatically
LicenseFile="${WPR_WSC_SERVICE_FILES_PATH}/license/license.xml"
if ! [ -f "${LicenseFile}" ]; then
   ./AppServerX -activateLicense ${WPR_LICENSE_TICKET_ID} -y
fi

#start NGINX for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
