FROM ubuntu:24.04

ARG WPR_WEB_SERVER_PORT=8080
ARG WPR_WEB_SERVER_SSL_PORT=8443

ENV WPR_WEB_SERVER_PORT=${WPR_WEB_SERVER_PORT}
ENV WPR_WEB_SERVER_SSL_PORT=${WPR_WEB_SERVER_SSL_PORT}

EXPOSE $WPR_WEB_SERVER_PORT
EXPOSE $WPR_WEB_SERVER_SSL_PORT
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive

ARG WPR_FILES_DIR=./files
ARG WPR_DEPLOYMENT_DIR=/home
ARG WPR_DICTIONARIES_DIR=/dictionaries
ARG WPR_CUSTOM_DICTIONARIES_DIR=$WPR_DICTIONARIES_DIR/CustomDictionaries
ARG WPR_USER_DICTIONARIES_DIR=$WPR_DICTIONARIES_DIR/UserDictionaries
ARG WPR_STYLE_GUIDE_DIR=$WPR_DICTIONARIES_DIR/StyleGuide
ARG WPR_CERT_DIR=/certificate
ARG WPR_CERT_KEY_NAME=key.pem
ARG WPR_CERT_FILE_NAME=cert.pem
ARG WPR_APP_ROOT_DIR=$WPR_DEPLOYMENT_DIR/WSC
ARG WPR_APP_SERVER_DIR=/opt/WebSpellChecker/AppServer
ARG WPR_APP_NAME_MASK=wsc_app*tar.gz
ARG WPR_USER_NAME=wsc
ARG WPR_PATH_TO_SERVICE_FILES_DIRECTORY=/var/lib
ARG WPR_USER_ID=2000
ARG WPR_GROUP_ID=2000

ENV WPR_APP_SERVER_DIR=${WPR_APP_SERVER_DIR}

ENV WPR_AUTO_INSTALL=TRUE

# Application installation parameters
# Protocol of the NGINX web server (1 - HTTPS, 2 - HTTP)
ARG WPR_PROTOCOL=2
# Web port outside the container. If value isn't specified (e.g. empty), the default value will be used (443 for HTTPS and 80 for HTTP).
ARG WPR_WEB_PORT
ARG WPR_DOMAIN_NAME=localhost
ARG WPR_VIRTUAL_DIR=wscservice
# Specify license ticket ID to activate the license during the image build. For example, WPR_LICENSE_TICKET_ID = 6u*************ZO
ARG WPR_LICENSE_TICKET_ID
ARG WPR_PRODUCTS=4
ARG WPR_LANGUAGES=en_US,en_GB,en_CA,en_AU
ARG WPR_AI_MODELS=1,2
ARG WPR_INSTALL_SAMPLES=1

# Proxy server settings
# If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 
ARG WPR_ENABLE_PROXY=0
ARG WPR_PROXY_HOST
ARG WPR_PROXY_PORT
ARG WPR_PROXY_USER_NAME
ARG WPR_PROXY_PASSWORD

# Access Key for Custom Dictionary and Style Guide API
ARG WPR_ACCESS_KEY

ENV WPR_CONFIG_USE_ENV=true
ENV WPR_FILE_OWNER=${WPR_USER_ID}:${WPR_GROUP_ID}
ENV WPR_PRODUCTS=${WPR_PRODUCTS}
ENV WPR_LANGUAGES=${WPR_LANGUAGES}
ENV WPR_AI_MODELS=${WPR_AI_MODELS}
ENV WPR_INSTALL_SAMPLES=${WPR_INSTALL_SAMPLES}
ENV WPR_PROTOCOL=${WPR_PROTOCOL}
ENV WPR_DOMAIN_NAME=${WPR_DOMAIN_NAME}
ENV WPR_WEB_PORT=${WPR_WEB_PORT}
ENV WPR_VIRTUAL_DIR=${WPR_VIRTUAL_DIR}
ENV WPR_WEB_SERVER_TYPE=2
ENV WPR_LICENSE_TICKET_ID=${WPR_LICENSE_TICKET_ID}
ENV WPR_PATH_TO_SERVICE_FILES_DIRECTORY=${WPR_PATH_TO_SERVICE_FILES_DIRECTORY}
ENV WPR_RESTART_WEB_SERVER=1
ENV WPR_CERT_DIR=${WPR_CERT_DIR}
ENV WPR_CERT_KEY_NAME=${WPR_CERT_KEY_NAME}
ENV WPR_CERT_FILE_NAME=${WPR_CERT_FILE_NAME}
ENV WPR_DICTIONARIES_DIR=${WPR_DICTIONARIES_DIR}
ENV WPR_CUSTOM_DICTIONARIES_DIR=${WPR_CUSTOM_DICTIONARIES_DIR}
ENV WPR_USER_DICTIONARIES_DIR=${WPR_USER_DICTIONARIES_DIR}
ENV WPR_STYLE_GUIDE_DIR=${WPR_STYLE_GUIDE_DIR}

#The log size must be set to 0 for Docker.
ENV WPR_SIZE=0

ENV WPR_ENABLE_PROXY=${WPR_ENABLE_PROXY}
ENV WPR_PROXY_HOST=${WPR_PROXY_HOST}
ENV WPR_PROXY_PORT=${WPR_PROXY_PORT}
ENV WPR_PROXY_USER_NAME=${WPR_PROXY_USER_NAME}
ENV WPR_PROXY_PASSWORD=${WPR_PROXY_PASSWORD}

# Database for collecting statistics
ENV WPR_ENABLE_DATABASE_PROVIDER=false
ENV WPR_DATABASE_HOST=''
ENV WPR_DATABASE_PORT=3306
ENV WPR_DATABASE_SCHEMA=''
ENV WPR_DATABASE_USER=''
ENV WPR_DATABASE_PASSWORD=''
ENV WPR_ENABLE_REQUEST_STATISTIC=false
ENV WPR_REQUEST_STATISTIC_DATA_TYPE=DATABASE
ENV WPR_ENABLE_USER_ACTION_STATISTIC=false
ENV WPR_ENABLE_REQUEST_VALIDATION=false

ENV WPR_ACCESS_KEY=${WPR_ACCESS_KEY}

RUN apt-get update && \
    apt-get upgrade -y perl && \
    apt-get install -y --no-install-recommends nginx default-jre wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/nginx/sites-enabled/default /var/www/html/* && \
    rm -rf /var/log/nginx/* && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN groupadd --gid ${WPR_GROUP_ID} $WPR_USER_NAME && useradd --no-log-init --uid ${WPR_USER_ID} --gid ${WPR_GROUP_ID} $WPR_USER_NAME

RUN mkdir -p $WPR_CUSTOM_DICTIONARIES_DIR \
             $WPR_USER_DICTIONARIES_DIR \
             $WPR_PATH_TO_SERVICE_FILES_DIRECTORY/WebSpellChecker \
             /var/run/nginx

COPY $WPR_FILES_DIR/$WPR_APP_NAME_MASK $WPR_DEPLOYMENT_DIR/
RUN PACKAGE_FILE=$(ls -1t $WPR_DEPLOYMENT_DIR/$WPR_APP_NAME_MASK 2>/dev/null | head -n 1) && \
    [ -z "$PACKAGE_FILE" ] && exit 1 || \
    echo "Using package file: $PACKAGE_FILE" && \
    tar -xvf $PACKAGE_FILE -C $WPR_DEPLOYMENT_DIR/ && \
    perl $WPR_APP_ROOT_DIR*/automated_install.pl || exit 1 && \
    rm -rf $WPR_APP_ROOT_DIR* $WPR_DEPLOYMENT_DIR/$WPR_APP_NAME_MASK && \
    mkdir -p $WPR_APP_SERVER_DIR/Logs && \
    cp -r $WPR_APP_SERVER_DIR/Logs $WPR_APP_SERVER_DIR/Build_Logs && \
    rm -rf $WPR_APP_SERVER_DIR/Logs/* && \
    ln -s /dev/stdout $WPR_APP_SERVER_DIR/Logs/Main.log && \
    ln -s /dev/stdout $WPR_APP_SERVER_DIR/Logs/Child-0.log && \
    ln -s /dev/stdout $WPR_APP_SERVER_DIR/Logs/Child-1.log && \
    ln -s /dev/stdout $WPR_APP_SERVER_DIR/Logs/Action.log && \
    chown -R ${WPR_USER_ID}:${WPR_GROUP_ID} $WPR_PATH_TO_SERVICE_FILES_DIRECTORY/WebSpellChecker $WPR_DICTIONARIES_DIR $WPR_APP_SERVER_DIR

COPY $WPR_FILES_DIR/certificate/$WPR_CERT_KEY_NAME $WPR_CERT_DIR/$WPR_CERT_KEY_NAME
COPY $WPR_FILES_DIR/certificate/$WPR_CERT_FILE_NAME $WPR_CERT_DIR/$WPR_CERT_FILE_NAME
COPY $WPR_FILES_DIR/configure* $WPR_APP_SERVER_DIR/
COPY $WPR_FILES_DIR/startService.sh $WPR_APP_SERVER_DIR
RUN chown ${WPR_USER_ID}:${WPR_GROUP_ID} $WPR_APP_SERVER_DIR/startService.sh && \
    chown ${WPR_USER_ID}:${WPR_GROUP_ID} $WPR_APP_SERVER_DIR/configureFiles.pl && \
    chown ${WPR_USER_ID}:${WPR_GROUP_ID} $WPR_APP_SERVER_DIR/configureWebServer.pl && \
    chmod +x $WPR_APP_SERVER_DIR/startService.sh

RUN chown -R ${WPR_USER_ID}:${WPR_GROUP_ID} /var/log/nginx \
        /usr/sbin/nginx \
        /var/lib/nginx \
        /var/run/nginx \
        /etc/nginx

RUN apt-get remove -y wget && apt-get autoremove -y

USER $WPR_USER_NAME

WORKDIR $WPR_APP_SERVER_DIR

ENTRYPOINT ["sh", "-c", "${WPR_APP_SERVER_DIR}/startService.sh"]
