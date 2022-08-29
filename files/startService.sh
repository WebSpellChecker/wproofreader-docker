#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# assign the current path to a variable
appserver_path=`pwd`

# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib

# run script to configure web server files
perl configureWebServer.pl
# run script to configure samples and shared dictionaries
perl configureFiles.pl

lic=${LICENSE_TICKET_ID}

# activate a license automatically
LicenseFile=/var/lib/wsc/license/license.xml
if ! [ -f "$LicenseFile" ]; then
   ./AppServerX -activateLicense $lic -y
fi

#start NGINX for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
