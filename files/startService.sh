#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# assign the current path to a variable
appserver_path=`pwd`

# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib

usage() { echo "Wrong parameters passed. Usage: sh $0 [-l <licenseid>] [-p <https|http>] [-d <domain>]"; exit 1; }

while getopts "l:p:d:" opt
do
    case $opt in
        l)
            license=${OPTARG};;
        p)
            protocol=${OPTARG};;
		d)
            domain=${OPTARG};;
        *)
            usage;;
    esac
done

if [ -z $protocol ]
then
	protocol="https"
fi

if [ $protocol != 'https' ] && [ $protocol != 'http' ]
then
	usage
fi

# run script to configure samples and shared dictionaries using the host name
perl configureWebServer.pl $protocol
perl configureFiles.pl $domain

# activate a license automatically
LicenseFile=/var/lib/wsc/license/license.xml
if ! [ -f "$LicenseFile" ]; then
   ./AppServerX -activateLicense $license -y
fi

#start Nginx HTTP Server for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
