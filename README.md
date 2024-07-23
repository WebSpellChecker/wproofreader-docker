# WebSpellChecker/WProofreader Docker

This repository provides Docker configurations to build a WebSpellChecker/WProofreader Server image using [Ubuntu Server 22.04](https://hub.docker.com/_/ubuntu) or [Red Hat Universal Base Image 9](https://hub.docker.com/r/redhat/ubi9). Use `Dockerfile` for Ubuntu or `Dockerfile.redhat` for Red Hat. 

Additionally, `Dockerfile.ubuntu-prebuilt` leverages a prebuilt Docker image with WProofreader Server pre-installed on Ubuntu, available on Docker Hub since v5.30.0. This public [Docker image with WebSpellChecker/WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) includes pre-configured languages and settings, and can be used for both evaluation and production with necessary modifications to fit your specific requirements.

All configurations use **NGINX** as a default web server for processing static files and service requests.

Before you begin, make sure you meet the [installation requirements](https://docs.webspellchecker.com/display/WebSpellCheckerServer55x/Installation+requirements).

## Create Docker image

For production, create a custom Docker image using either an installation package provided by the support team or a prebuilt Docker image.

The general procedure is as follows:

1. Clone [WProofreader Docker repo](https://github.com/WebSpellChecker/wproofreader-docker/releases). If you already have a package that you would like to use for the installation, make sure that the WProofreader Docker release version matches that of the package. The version is specified in its name: wsc_app_x64_**5.X.X**.x_xx.tar.gz. **NOTE!** Both the package and Dockerfile versions should match as certain configuration features require appropriate changes in the application itself.
If, on the other hand, you would like to use a prebuilt Docker image, choose the same version, as the app version you would like to have installed (e.g. latest).

2. If using an installation package, copy the file (e.g. `wsc_app_x64_5.x.x.x_xx.tar.gz`) to the `wproofreader-docker/files` directory. You can request an installation package via the [contact us form](https://webspellchecker.com/contact-us/). If using a prebuilt image, skip this step.

3. Tailor the installation by editing one of the Dockerfiles:
- For installations from a package, edit [Dockerfile](Dockerfile) or [Dockerfile.redhat](Dockerfile.redhat).
- For a prebuilt image from Docker Hub, edit [Dockerfile.ubuntu-prebuilt](Dockerfile.ubuntu-prebuilt):

```
ARG PROTOCOL=2
ARG WEB_PORT
ARG DOMAIN_NAME=localhost
ARG VIRTUAL_DIR=wscservice
ARG LICENSE_TICKET_ID
ARG PRODUCTS=4
ARG INSTALL_SAMPLES=1
```
* Choose languages to be installed:
```
ARG LANGUAGES=en_US,en_GB,en_CA,en_AU
ARG AI_MODELS=1,2
```
where `LANGUAGES` accepts a comma-separated list of language IDs, `AI_MODELS` – a list of AI models to be included, provided that a compatible language is installed. For example, if you select at least one of the compatible English language IDs, you will be able to install the English language model for enhanced text correction. The options for `AI_MODELS` parameter are:
1. English language model
2. English autocomplete model
3. German language model
4. Spanish language model

English language and autocomplete models are available for en_US (American English), en_GB (British English), en_CA (Canadian English) and en_AU (Australian English).  German – for de_DE (Germany), Spanish – for es_ES (Spain).

* Activate license. Update the value for the following option:
```
ARG LICENSE_TICKET_ID=6u*************ZO
```
* Specify `DOMAIN_NAME` which will be used for the setup of demo samples with WProofreader. By default, `localhost` will be used if nothing is specified.

```
ARG DOMAIN_NAME = DOMAIN_NAME
```

If `LICENSE_TICKET_ID` was specified during the image creation, you don't need to specify it during the launch of `docker run` command.

* If using a proxy server for network traffic, add the following proxy settings for automated license activation:

```
ARG ENABLE_PROXY=1
ARG PROXY_HOST=host_name
ARG PROXY_PORT=port_number
ARG PROXY_USER_NAME=user_name
ARG PROXY_PASSWORD=password
```

For details on the available options, refer to [Automated Installing WebSpellChecker on Linux](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux) guide.

4. If you need to use SSL (access the service via HTTPS), put your SSL certificate and key files to the `wproofreader-docker/files/certificate` directory. You need to rename your certificate files to `cert.pem` and `key.pem` accordingly.

5. Build a Docker image using the command below:

```
docker build -t local/wsc_app:x.x.x -f <Dockerfile_name> <path_to_Dockerfile_directory>
```

where:

* `-t` assign a tag name `local/wsc_app:x.x.x`, where `x.x.x` is a package version.
* `<Dockerfile_name>` a Dockerfile name, e.g. `Dockerfile`, `DockerfileCentOS` or `DockerfileRedHat`
* `<path_to_Dockerfile_directory>` the path to the Dockerfile directory, not to the Dockerfile itself. If the Dockerfile is in the same directory, e.g. `/wproofreader-docker/`, you can use `.` instead of the path.

Also, if you don't want to modify the `Dockerfile` you can provide any installation parameter via CLI through the `--build-arg` flag. For example:

```
docker build -t local/wsc_app:x.x.x --build-arg LICENSE_TICKET_ID=6u*************ZO --build-arg LANGUAGES=en_US,en_GB -f Dockerfile .
```

### Choosing platform

Currently, the Docker configuration supports two platforms: `amd64`/`arm64`. To build an image for the desired platform, you need to use an appropriate `.tar.gz` package.

* **amd64**:

Put "wsc_app_**x64**_x.xx.x.x_xxx.tar.gz" package into the `wproofreader-docker/files` directory and add an extra build flag: `--platform linux/amd64`.
So, the build command needs to be updated as follows:
```
docker build -t local/wsc_app:x.x.x --platform linux/amd64 --build-arg <arguments as before> -f Dockerfile .
```

* **arm64**:

Put "wsc_app_**arm64**_x.xx.x.x_xxx.tar.gz" package into the `wproofreader-docker/files` directory and add an extra build flag: `--platform linux/arm64/v8`.
So, the build command needs to be updated as follows:
```
docker build -t local/wsc_app:x.x.x --platform linux/arm64/v8 --build-arg <arguments as before> -f Dockerfile .
```

**Cross-platform consideration**

While Docker allows building images across different architectures, it's important to note that cross-platform compatibility might have limitations. For instance, building an image on an ARM-based system like a Mac M1/M2 for the `amd64` platform might result in an image that's compatible with `amd64` environments but might not function correctly on ARM-based systems, such as the Mac M1/M2.

To ensure seamless execution within your target environment, it's advisable to build the image on a platform that matches the intended deployment architecture. When in doubt, confirm the target system's architecture and build the Docker image accordingly to guarantee compatibility and optimal performance.


## Create and run Docker container

Create and run a Docker container from the latest Docker image with the following options:

```
docker run -d -p 80:8080 local/wsc_app:x.x.x
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

To use user- and company-level custom dictionaries, you need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```
docker run -d -p 80:8080 -v <directory_path>:/dictionaries -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <directory_path>:/dictionaries -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

where:

* `-d` start a container in detached mode.
* `-p 80:8080` map the host port `80:` and the exposed port of container `8080`, where port `8080` is a web server port (by default, NGINX). With the SSL connection, you must use port `443` like `-p 443:8443`. 
* `-v <shared_dictionaries_directory>:/dictionaries` mount a shared directory where user and company custom dictionaries will be created and stored. Upon initial launch, the mounted directory may be empty. All essential subdirectories and files will be generated during initialization of the container. This is required to save the dictionaries among different containers. **Note!** The container user needs to have read and write permissions to the shared dictionary directory.
* `-v <certificate_directory_path>:/certificate` mount a shared directory where your SSL certificates are located. Use this option if you plan to work under SSL and you want to use a specific certificate for this container. The names of the files must be `cert.pem` and `key.pem`. If not specified, the default test SSL certificate (e.g. `ssl-cert-snakeoil`) shipped with Ubuntu will be used.  **Note!** The container user must have read permissions for the certificate files.
* `local/wsc_app:x.x.x` the tag of WebSpellChecker Server Docker image.

Alternatively, these parameters can be changed on the container running by passing them as environment variables:

* `PROTOCOL`
* `DOMAIN_NAME`
* `WEB_PORT`
* `VIRTUAL_DIR`
* `LICENSE_TICKET_ID`

For example:

```
docker run -d -p 443:8443 --env PROTOCOL=1 --env DOMAIN_NAME=localhost --env WEB_PORT=443 --env VIRTUAL_DIR=wscservice --env LICENSE_TICKET_ID=6u*************ZO local/wsc_app:x.x.x
```

where:

* `--env PROTOCOL=1` start a container on HTTPS protocol
* `--env DOMAIN_NAME=localhost` start a container on `localhost` domain name
* `--env WEB_PORT=443` configure `443` port to be an external port of a container
* `--env VIRTUAL_DIR=wscservice` start a container with `wscservice` as virtual dir
* `--env LICENSE_TICKET_ID=6u*************ZO` activate license on container start with `6u*************ZO` license ticket id

The container launched by the command above will be available at the following address:

```
https://localhost:443/wscservice/api?cmd=status
```

Learn more how to [set environment variables in Docker container](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file).

## Verify work

After the successful launch of a container with the app (and the license activation), you can verify the version `ver` and `status` using the commands below from the browser or using `curl` in the terminal:

* Version: http://localhost/wscservice/api?cmd=ver

```{"COPYRIGHT":"(c) 2000-202x WebSpellChecker LLC","PRODUCT WEBSITE":"webspellchecker.com","PROGRAM VERSION":"5.x.x.0 x64 master:xxxxxxx (xxxx) #xx"}```

* Status: http://localhost/wscservice/api?cmd=status

```
{
    "SpellCheckEngine": {
        "active": true
    },
    "GrammarCheckEngine": {
        "active": true
    },
    "EnglishAIModel": {
        "active": true
    },
    "GermanAIModel": {
        "active": true
    },
    "SpanishAIModel": {
        "active": true
    },
    "EnglishAutocomplete": {
        "active": true
    }
}
```

* Getting started http://localhost/wscservice/ as well as the demo samples: http://localhost/wscservice/samples/ pages can be accessed from the browser.


## Working with container

1. Going further if you need to restart the service or container, you should use Docker [start](https://docs.docker.com/engine/reference/commandline/start/) or [stop](https://docs.docker.com/engine/reference/commandline/stop/) commands with a container Id as an option.

```
docker start <container_id>
```

2. If you need to troubleshoot issues with the application, you may want to check logs. All application logs are stored in container [logs](https://docs.docker.com/engine/reference/commandline/logs/):

```
docker logs <container_id>
```

3. If you need to configure the application server (AppServer), for example, edit `AppServerX.xml`, you need to connect to a container. Use `docker exec` command to connect to a container where the app is running:

```
docker exec -it <container_id> /bin/bash
```

4. It's important to keep in mind and monitor the amount of resources allocated for and consumed by the application according the the minimal hardware requirements for its proper work. You can check the resource usage statistics of a container using the `docker stats` command as shown below. [Read more](https://docs.docker.com/engine/reference/commandline/stats/) about this command and its options in the official documentation.

```
docker stats <container_id>
```

## Create image from modified Docker container

If you need to make any changes to the app configuration that is running inside the Docker container (e.g. changes to `AppServerX.xml`) and keep it persistent, create an image from the modified container. It can be easily done with a single command:

```
docker commit <existing_container_id> <new_name_image>
```

Then check if the image has been successfully created, using `docker images` command. You will see the list of existing images. Use this new image to create new containers following the instructions on how to run the container above.


## Docker Compose

Instead of using lengthy `docker run` commands, it is possible to keep all the configuration in a `docker-compose.yml` file (name is important, extension can be `yaml` or `yml`) and deploy it using `docker compose up` command from the same directory. For more information, please refer to the [documentation](https://docs.docker.com/compose/).


Sample `docker-compose.yml` content:
```yaml
version: "3"
services:
  wproofreader:
    image: webspellchecker/wproofreader:latest
    container_name: wproofreader-server
    ports:
      - "80:8080"
    environment:
      - PROTOCOL=2 
      - WEB_PORT=80
      - DOMAIN_NAME=localhost
      - VIRTUAL_DIR=wscservice
```

Notes:
1. If you have a license key, pass it as an environment variable like that:
   ```  - LICENSE_TICKET_ID=<your License ID>```
   The server will be activated automatically upon startup.
2. This deploys the WProofreader Server working with HTTP protocol. To use it over HTTPS please change the following sections to:
 ```yaml
    ports:
      - "443:8443"
    environment:
      - PROTOCOL=1 
      - WEB_PORT=443
      - DOMAIN_NAME=localhost
      - VIRTUAL_DIR=wscservice
```
3. For HTTPS communication you have to provide your certificate file and key, as a pair of files named `cert.pem` and `key.pem`, respectively. If, for instance, they are kept in a folder `/home/user/certificate`, one should add the following section to `docker-compose.yml`:
 ```yaml
    volumes:
      - /home/user/certificate:/certificate
 ```
4. If you have to use custom dictionaries, mount the folder they are located in the docker container the same way:
  ```yaml
    volumes:
      - /home/user/dictionaries:/dictionaries
  ```

Finally, the whole config with activation, custom dictionaries and HTTPS would look like this:
```yaml
version: "3"
services:
  wproofreader:
    image: webspellchecker/wproofreader:latest
    container_name: wproofreader-server
    ports:
      - "443:8443"
    environment:
      - PROTOCOL=1 
      - WEB_PORT=443
      - DOMAIN_NAME=localhost
      - VIRTUAL_DIR=wscservice
      - LICENSE_TICKET_ID=ABCD1234
    volumes:
      - /home/user/certificate:/certificate
      - /home/user/dictionaries:/dictionaries
```

## Further steps

Once a docker container with the app is up and running, you can integrate JavaScript libs/components or plugin it into your web app.

* [WProofreader SDK API options](https://webspellchecker.com/docs/api/wscbundle/Options.html)
* [WProofreader SDK demos](https://demos.webspellchecker.com/)
