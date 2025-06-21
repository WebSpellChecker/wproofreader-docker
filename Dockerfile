FROM ubuntu:24.04

ARG WEB_SERVER_PORT=8080
ARG WEB_SERVER_SSL_PORT=8443

ENV WPR_WEB_SERVER_PORT=${WEB_SERVER_PORT}
ENV WPR_WEB_SERVER_SSL_PORT=${WEB_SERVER_SSL_PORT}

EXPOSE $WEB_SERVER_PORT
EXPOSE $WEB_SERVER_SSL_PORT
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive

ARG FILES_DIR=./files
ARG DEPLOYMENT_DIR=/home
ARG DICTIONARIES_DIR=/dictionaries
ARG CUSTOM_DICTIONARIES_DIR=$DICTIONARIES_DIR/CustomDictionaries
ARG USER_DICTIONARIES_DIR=$DICTIONARIES_DIR/UserDictionaries
ARG STYLE_GUIDE_DIR=$DICTIONARIES_DIR/StyleGuide
ARG CERT_DIR=/certificate
ARG CERT_KEY_NAME=key.pem
ARG CERT_FILE_NAME=cert.pem
ARG APP_ROOT_DIR=$DEPLOYMENT_DIR/WSC
ARG APP_SERVER_DIR=/opt/WebSpellChecker/AppServer
ARG APP_NAME_MASK=wsc_app*tar.gz
ARG USER_NAME=wsc
ARG PATH_TO_SERVICE_FILES_DIRECTORY=/var/lib
ARG USER_ID=2000
ARG GROUP_ID=2000

ENV WPR_APP_SERVER_DIR=${APP_SERVER_DIR}

ENV WPR_AUTO_INSTALL=TRUE

# Application installation parameters
# Protocol of the NGINX web server (1 - HTTPS, 2 - HTTP)
ARG PROTOCOL=2
# Web port outside the container. If value isn't specified (e.g. empty), the default value will be used (443 for HTTPS and 80 for HTTP).
ARG WEB_PORT
ARG DOMAIN_NAME=localhost
ARG VIRTUAL_DIR=wscservice
# Specify license ticket ID to activate the license during the image build. For example, LICENSE_TICKET_ID = 6u*************ZO
ARG LICENSE_TICKET_ID
ARG PRODUCTS=4
ARG LANGUAGES=en_US,en_GB,en_CA,en_AU
ARG AI_MODELS=1,2
ARG INSTALL_SAMPLES=1

# Proxy server settings
# If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 
ARG ENABLE_PROXY=0
ARG PROXY_HOST
ARG PROXY_PORT
ARG PROXY_USER_NAME
ARG PROXY_PASSWORD

# Access Key for Custom Dictionary and Style Guide API
ARG ACCESS_KEY

ENV WPR_CONFIG_USE_ENV=true
ENV WPR_FILE_OWNER=${USER_ID}:${GROUP_ID}
ENV WPR_PRODUCTS=${PRODUCTS}
ENV WPR_LANGUAGES=${LANGUAGES}
ENV WPR_AI_MODELS=${AI_MODELS}
ENV WPR_INSTALL_SAMPLES=${INSTALL_SAMPLES}
ENV WPR_PROTOCOL=${PROTOCOL}
ENV WPR_DOMAIN_NAME=${DOMAIN_NAME}
ENV WPR_WEB_PORT=${WEB_PORT}
ENV WPR_VIRTUAL_DIR=${VIRTUAL_DIR}
ENV WPR_WEB_SERVER_TYPE=2
ENV WPR_LICENSE_TICKET_ID=${LICENSE_TICKET_ID}
ENV WPR_PATH_TO_SERVICE_FILES_DIRECTORY=${PATH_TO_SERVICE_FILES_DIRECTORY}
ENV WPR_RESTART_WEB_SERVER=1
ENV WPR_CERT_DIR=${CERT_DIR}
ENV WPR_CERT_KEY_NAME=${CERT_KEY_NAME}
ENV WPR_CERT_FILE_NAME=${CERT_FILE_NAME}
ENV WPR_DICTIONARIES_DIR=${DICTIONARIES_DIR}
ENV WPR_CUSTOM_DICTIONARIES_DIR=${CUSTOM_DICTIONARIES_DIR}
ENV WPR_USER_DICTIONARIES_DIR=${USER_DICTIONARIES_DIR}
ENV WPR_STYLE_GUIDE_DIR=${STYLE_GUIDE_DIR}
ENV WPR_SIZE=0

ENV WPR_ENABLE_PROXY=${ENABLE_PROXY}
ENV WPR_PROXY_HOST=${PROXY_HOST}
ENV WPR_PROXY_PORT=${PROXY_PORT}
ENV WPR_PROXY_USER_NAME=${PROXY_USER_NAME}
ENV WPR_PROXY_PASSWORD=${PROXY_PASSWORD}

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

ENV WPR_ACCESS_KEY=${ACCESS_KEY}

RUN apt-get update && \
    apt-get upgrade -y perl && \
    apt-get install -y --no-install-recommends nginx default-jre wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/nginx/sites-enabled/default /var/www/html/* && \
    rm -rf /var/log/nginx/* && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN groupadd --gid ${GROUP_ID} $USER_NAME && useradd --no-log-init --uid ${USER_ID} --gid ${GROUP_ID} $USER_NAME

RUN mkdir -p $CUSTOM_DICTIONARIES_DIR \
             $USER_DICTIONARIES_DIR \
             $PATH_TO_SERVICE_FILES_DIRECTORY/WebSpellChecker \
             /var/run/nginx

COPY $FILES_DIR/$APP_NAME_MASK $DEPLOYMENT_DIR/
RUN PACKAGE_FILE=$(ls -1t $DEPLOYMENT_DIR/$APP_NAME_MASK 2>/dev/null | head -n 1) && \
    [ -z "$PACKAGE_FILE" ] && exit 1 || \
    echo "Using package file: $PACKAGE_FILE" && \
    tar -xvf $PACKAGE_FILE -C $DEPLOYMENT_DIR/ && \
    perl $APP_ROOT_DIR*/automated_install.pl || exit 1 && \
    rm -rf $APP_ROOT_DIR* $DEPLOYMENT_DIR/$APP_NAME_MASK && \
    mkdir -p $APP_SERVER_DIR/Logs && \
    cp -r $APP_SERVER_DIR/Logs $APP_SERVER_DIR/Build_Logs && \
    rm -rf $APP_SERVER_DIR/Logs/* && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Main.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Child-0.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Child-1.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Action.log && \
    chown -R ${USER_ID}:${GROUP_ID} $PATH_TO_SERVICE_FILES_DIRECTORY/WebSpellChecker $DICTIONARIES_DIR $APP_SERVER_DIR

COPY $FILES_DIR/certificate/$CERT_KEY_NAME $CERT_DIR/$CERT_KEY_NAME
COPY $FILES_DIR/certificate/$CERT_FILE_NAME $CERT_DIR/$CERT_FILE_NAME
COPY $FILES_DIR/configure* $APP_SERVER_DIR/
COPY $FILES_DIR/startService.sh $APP_SERVER_DIR
RUN chown ${USER_ID}:${GROUP_ID} $APP_SERVER_DIR/startService.sh && \
    chown ${USER_ID}:${GROUP_ID} $APP_SERVER_DIR/configureFiles.pl && \
    chown ${USER_ID}:${GROUP_ID} $APP_SERVER_DIR/configureWebServer.pl && \
    chmod +x $APP_SERVER_DIR/startService.sh

RUN chown -R ${USER_ID}:${GROUP_ID} /var/log/nginx \
        /usr/sbin/nginx \
        /var/lib/nginx \
        /var/run/nginx \
        /etc/nginx

RUN apt-get remove -y wget && apt-get autoremove -y

USER $USER_NAME

WORKDIR $APP_SERVER_DIR

ENTRYPOINT sh ${APP_SERVER_DIR}/startService.sh
