#!/bin/sh
cd `dirname $0`
appserver_path=`pwd`
export LD_LIBRARY_PATH=${appserver_path}/lib
perl configureFiles.pl $2
./AppServerX -activateLicense $1 -y
service apache2 start
./AppServerX
