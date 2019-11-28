#!/bin/sh
# change the name of the directory containing a script
cd `dirname $0`
# assign the current path to a variable where AppServer is located
appserver_path=`pwd`
# export the libraries required for the service start
export LD_LIBRARY_PATH=${appserver_path}/lib
# run script to configure samples and shared dictionaries using the host name
perl configureFiles.pl $2
# activate a license automatically
./AppServerX -activateLicense $1 -y
#service apache2 start #start Apache HTTP Server
service apache2 start
# start AppServer service
./AppServerX
