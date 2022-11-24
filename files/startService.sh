#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# export the libraries required for the service start
export LD_LIBRARY_PATH="$(pwd)/lib"

# run script to configure web server files
perl configureWebServer.pl
# run script to configure samples and shared dictionaries
perl configureFiles.pl

# activate a license automatically
LicenseFile="${SERVICE_DIR}/wsc/license/license.xml"
if ! [ -f "${LicenseFile}" ]; then
   ./AppServerX -activateLicense ${LICENSE_TICKET_ID} -y
fi

#start NGINX for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
