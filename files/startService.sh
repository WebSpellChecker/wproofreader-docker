#!/bin/sh
# change the working directory to the directory that contains the script
cd `dirname $0`

# export the libraries required for the service start
export LD_LIBRARY_PATH="$(pwd)/lib"
export MARIADB_PLUGIN_DIR="$(pwd)/lib"
export MARIADB_TLS_DISABLE_PEER_VERIFICATION=1

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

# Generate self-signed certificates if HTTPS is enabled and no certs are provided
if [ "$WPR_PROTOCOL" = "1" ]; then
    if [ ! -f "${WPR_CERT_DIR}/${WPR_CERT_FILE_NAME}" ] || [ ! -f "${WPR_CERT_DIR}/${WPR_CERT_KEY_NAME}" ]; then
        echo "$(date '+%m/%d/%y:%H:%M:%S.%3N')   No SSL certificates found. Generating self-signed certificate for CN=${WPR_DOMAIN_NAME:-localhost}..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "${WPR_CERT_DIR}/${WPR_CERT_KEY_NAME}" \
            -out "${WPR_CERT_DIR}/${WPR_CERT_FILE_NAME}" \
            -subj "/CN=${WPR_DOMAIN_NAME:-localhost}" 2>/dev/null
        echo "$(date '+%m/%d/%y:%H:%M:%S.%3N')   Self-signed certificate created: ${WPR_CERT_DIR}/${WPR_CERT_FILE_NAME}, ${WPR_CERT_DIR}/${WPR_CERT_KEY_NAME}"
        echo "$(date '+%m/%d/%y:%H:%M:%S.%3N')   For production, mount real certificates to ${WPR_CERT_DIR}/"
    fi
fi

#start NGINX for Ubuntu or Centos
nginx

# start AppServer service
./AppServerX
