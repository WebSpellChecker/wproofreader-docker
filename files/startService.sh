#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# assign the current path to a variable
appserver_path=`pwd`

# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib

# run script to configure samples and shared dictionaries using the host name
perl configureFiles.pl $2

# activate a license automatically
LicenseFile=/var/lib/wsc/license/license.xml
if ! [ -f "$LicenseFile" ]; then
   ./AppServerX -activateLicense $1 -y
fi

#start Apache HTTP Server for Ubuntu or Centos
service apache2 start
httpd -k start

# start AppServer service
./AppServerX
