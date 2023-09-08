FROM ubuntu:22.04

ARG WEB_SERVER_PORT=8080
ARG WEB_SERVER_SSL_PORT=8443

ENV WEB_SERVER_PORT=${WEB_SERVER_PORT}
ENV WEB_SERVER_SSL_PORT=${WEB_SERVER_SSL_PORT}

EXPOSE $WEB_SERVER_PORT
EXPOSE $WEB_SERVER_SSL_PORT
EXPOSE 2880

ENV DEBIAN_FRONTEND=noninteractive

ARG FILES_DIR=./files
ARG DEPLOYMENT_DIR=/home
ARG DICTIONARIES_DIR=/dictionaries
ARG CUSTOM_DICTIONARIES_DIR=$DICTIONARIES_DIR/CustomDictionaries
ARG USER_DICTIONARIES_DIR=$DICTIONARIES_DIR/UserDictionaries
ARG CERT_DIR=/certificate
ARG CERT_KEY_NAME=key.pem
ARG CERT_FILE_NAME=cert.pem
ARG APP_ROOT_DIR=$DEPLOYMENT_DIR/WSC
ARG APP_SERVER_DIR=/opt/WebSpellChecker/AppServer
ARG APP_NAME_MASK=wsc_app*tar.gz
ARG USER_NAME=wsc
ARG SERVICE_FILES_DIR=/var/lib
ARG USER_ID=2000
ARG GROUP_ID=2000

ENV APP_SERVER_DIR=${APP_SERVER_DIR}

ENV WSC_AUTO_INSTALL=TRUE

# Application installation parameters
# Protocol of the NGINX web server (1 - HTTPS, 2 - HTTP)
ARG PROTOCOL=2
# Web port outside the container. If value isn't specified (e.g. empty), the default value will be used (443 for HTTPS and 80 for HTTP).
ARG WEB_PORT
ARG DOMAIN_NAME=localhost
ARG VIRTUAL_DIR=wscservice
# Change to 1 to activate the license during the image build. 
ARG ACTIVATE_LICENSE=0
# Specify license ticket ID if ACTIVATE_LICENSE is set to 1. For example, LICENSE_TICKET_ID = 6u*************ZO
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

ENV FILE_OWNER=${USER_ID}:${GROUP_ID}
ENV PRODUCTS=${PRODUCTS}
ENV LANGUAGES=${LANGUAGES}
ENV AI_MODELS=${AI_MODELS}
ENV INSTALL_SAMPLES=${INSTALL_SAMPLES}
ENV PROTOCOL=${PROTOCOL}
ENV DOMAIN_NAME=${DOMAIN_NAME}
ENV WEB_PORT=${WEB_PORT}
ENV VIRTUAL_DIR=${VIRTUAL_DIR}
ENV WEB_SERVER_TYPE=2
ENV ACTIVATE_LICENSE=${ACTIVATE_LICENSE}
ENV LICENSE_TICKET_ID=${LICENSE_TICKET_ID}
ENV SERVICE_FILES_DIR=${SERVICE_FILES_DIR}
ENV RESTART_WEB_SERVER=1
ENV CERT_DIR=${CERT_DIR}
ENV CERT_KEY_NAME=${CERT_KEY_NAME}
ENV CERT_FILE_NAME=${CERT_FILE_NAME}
ENV DICTIONARIES_DIR=${DICTIONARIES_DIR}
ENV CUSTOM_DICTIONARIES_DIR=${CUSTOM_DICTIONARIES_DIR}
ENV USER_DICTIONARIES_DIR=${USER_DICTIONARIES_DIR}

ENV ENABLE_PROXY=${ENABLE_PROXY}
ENV PROXY_HOST=${PROXY_HOST}
ENV PROXY_PORT=${PROXY_PORT}
ENV PROXY_USER_NAME=${PROXY_USER_NAME}
ENV PROXY_PASSWORD=${PROXY_PASSWORD}

# Database for collecting statistics
ENV ENABLE_DATABASE=false
ENV DATABASE_HOST=''
ENV DATABASE_PORT=3306
ENV DATABASE_SCHEMA=''
ENV DATABASE_USER=''
ENV DATABASE_PASSWORD=''
ENV ENABLE_REQUEST_STATISTIC=false
ENV ENABLE_USER_ACTION_STATISTIC=false
ENV ENABLE_REQUEST_VALIDATION=false

RUN apt-get update && \
    apt-get upgrade -y perl && \
    apt-get install -y --no-install-recommends nginx default-jre wget && \
    apt-get clean && apt-get upgrade -y openssl && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /etc/nginx/sites-enabled/default /var/www/html/* && \
    rm -rf /var/log/nginx/* && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN groupadd --gid ${GROUP_ID} $USER_NAME && useradd --no-log-init --uid ${USER_ID} --gid ${GROUP_ID} $USER_NAME

RUN mkdir -p $CUSTOM_DICTIONARIES_DIR \
             $USER_DICTIONARIES_DIR \
             $SERVICE_FILES_DIR/WebSpellChecker \
             /var/run/nginx

COPY $FILES_DIR/$APP_NAME_MASK $DEPLOYMENT_DIR/
RUN PACKAGE_FILE=$(ls -1t $DEPLOYMENT_DIR/$APP_NAME_MASK 2>/dev/null | head -n 1) && \
    [ -z "$PACKAGE_FILE" ] && echo "Error. Docker image build failed: No valid application package detected." && exit 1 || \
    echo "Using package file: $PACKAGE_FILE" && \
    tar -xvf $PACKAGE_FILE -C $DEPLOYMENT_DIR/ && \
    perl $APP_ROOT_DIR*/automated_install.pl && \
    rm -rf $APP_ROOT_DIR* $DEPLOYMENT_DIR/$APP_NAME_MASK && \
    [ -d "${APP_SERVER_DIR}/Logs" ] && tar -czvf "${APP_SERVER_DIR}"/Logs/img_build_logs.tar.gz ${APP_SERVER_DIR}/Logs/* --remove-files || \
    mkdir -p $APP_SERVER_DIR/Logs && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Main.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Child-0.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Child-1.log && \
    ln -s /dev/stdout $APP_SERVER_DIR/Logs/Action.log && \
    chown -R ${USER_ID}:${GROUP_ID} $SERVICE_FILES_DIR/WebSpellChecker $DICTIONARIES_DIR $APP_SERVER_DIR

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
