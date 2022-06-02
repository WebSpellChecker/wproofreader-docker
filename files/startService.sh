#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# assign the current path to a variable
appserver_path=`pwd`

# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib

# run script to configure samples and shared dictionaries using the host name
perl configureWebServer.pl $1
perl configureFiles.pl $3

# activate a license automatically
LicenseFile=/var/lib/wsc/license/license.xml
if ! [ -f "$LicenseFile" ]; then
   ./AppServerX -activateLicense $2 -y
fi

#start Nginx HTTP Server for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
