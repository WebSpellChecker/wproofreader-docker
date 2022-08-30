#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# export the libraries required for the service start
export LD_LIBRARY_PATH="$(pwd)/lib"

# activate a license automatically
LicenseFile="${LicenseDir}/license.xml"
if ! [ -f "${LicenseFile}" ]; then
   ./AppServerX -activateLicense ${license_ticket_id} -y
fi

#start NGINX for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
