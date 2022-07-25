#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# assign the current path to a variable
appserver_path=`pwd`

# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib

pr=${PROTOCOL}
dm=${DOMAIN}
lic=${LICENSE}

if [ -z $pr ]
then
	pr="http"
fi

if [ $pr != 'https' ] && [ $pr != 'http' ]
then
	echo "Unknown protocol passed: $pr. Please use http or https."; exit 1;
fi

# run script to configure samples and shared dictionaries using the host name
perl configureWebServer.pl $pr
perl configureFiles.pl $dm

# activate a license automatically
LicenseFile=/var/lib/wsc/license/license.xml
if ! [ -f "$LicenseFile" ]; then
   ./AppServerX -activateLicense $lic -y
fi

#start Nginx HTTP Server for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
