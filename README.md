# WebSpellChecker/WProofreader Docker

This is a Docker configuration that you can use to build a WebSpellChecker/WProofreader Server image based on the latest [Ubuntu Server (latest)](https://hub.docker.com/_/ubuntu), [CentOS Linux 7](https://hub.docker.com/_/centos) or [Red Hat Universal Base Image 8](https://hub.docker.com/r/redhat/ubi8).

**Note!** You can also use a [Docker image with WebSpellChecker/WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) that we built and published on Docker Hub.

## Create Docker image

To create a custom Docker image: 

1. Clone [WProofreader Docker repo](https://github.com/WebSpellChecker/wproofreader-docker).
2. Copy the WebSpellChecker/WProofreader installation package (e.g. `wsc_app_x64_5.x.x.x_xx.tar.gz`) to `wproofreader-docker/files` directory. Such an installation package can be requested via [contact us form](https://webspellchecker.com/contact-us/).
3. Adjust the default installation options by modifying one of the Dockerfiles that you want to use: `Dockerfile`, `DockerfileCentOS`, `DockerfileRedHat`:
```
ARG file_owner=33:33
ARG products=4
ARG languages_to_install=1,2
ARG install_samples=1
ARG protocol=2
ARG domain_name=localhost
ARG web_port
ARG virtual_dir=wscservice
ARG web_server_type=2
ARG activate_license=0
ARG license_ticket_id
ARG restart_web_server=1
```

* Activate license during the image creation. Change the following options.

```
ARG activate_license=1
ARG license_ticket_id=6u*************ZO
```
* Specify `domain_name` which will be used for setup of demo samples with WProofreader. By default, `localhost` will be used if nothing is specified.

```
ARG domain_name = domain_name
```

If `license_ticket_id` was specified during the image creation, you don't need to specify it during the launch of `docker run` command.

* If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 

```
ARG enable_proxy=1
ARG proxy_host=host_name
ARG proxy_port=port_number
ARG proxy_user_name=user_name
ARG proxy_password=password
```

For details on the available options, refer to [Automated Installing WebSpellChecker on Linux](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux) guide.

4. If you need to use SSL, put your SSL certificate and key files to the `wproofreader-docker/files/certificate` directory. You need to rename your certificate files to `cert.pem` and `key.pem` accordingly.

5. Build a Docker image using the command below:

```
docker build -t local/wsc_app:x.x.x --build-arg USER_ID=YOUR_USER_ID --build-arg GROUP_ID=YOUR_GROUP_ID -f <Dockerfile_name> <path_to_Dockerfile_directory>
```

where:

* `-t` assign a tag name `local/wsc_app:x.x.x`, where `x.x.x` is a package version.
* `--build-arg USER_ID=YOUR_USER_ID` the argument sets a user ID for the default user in the container. If not specified, the default USER_ID=2000.
* `--build-arg GROUP_ID=YOUR_GROUP_ID` the argument sets a user group ID for the default user in the container.  If not specified, the default GROUP_ID=2000.
* `<Dockerfile_name>` a Dockerfile name, e.g. `Dockerfile`, `DockerfileCentOS` or `DockerfileRedHat`
* `<path_to_Dockerfile_directory>` the path to a Dockerfile directory, not to Dockerfile itself. If a Dockerfile is in the same directory, e.g. `/wproofreader-docker/`, you need to use to use `.` instead of the path.

Also if you don't want to modify `Dockerfile` you are able to provide any installation parameter through `--build-arg`. For example:

```
docker build -t local/wsc_app:x.x.x --build-arg activate_license=1 --build-arg license_ticket_id=6u*************ZO --build-arg USER_ID=2001 --build-arg GROUP_ID=2001 -f Dockerfile .
```

## Create and run Docker container

Create and run a Docker container from the latest Docker image with the following options:

```
docker run -d -p 80:8080 local/wsc_app:x.x.x
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

To use global custom and user dictionaries your need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```
docker run -d -p 80:8080 -v <directory_path>:/dictionaries -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <directory_path>:/dictionaries -v <certificate_directory_path>:/certificate local/wsc_app:x.x.x
```

where:

* `-d` start a container in detached mode.
* `-p 80:8080` map the host port `80:` and the exposed port of container `8080`, where port `8080` is a web server port (by default NGINX). With the SSL connection, you must use port `443` like `-p 443:8443`. 
* `-v <shared_dictionaries_directory>:/dictionaries` mount a shared directory where user and company custom dictionaries will be created and stored. This is required to save the dictionaries between starts of containers. **Note!** The container user must have read and write permissions to the shared dictionaries directory.
* `-v <certificate_directory_path>:/certificate` mount a shared directory where your SSL certificates are located. Use this option if you plan to work under SSL and you want to use a specific certificate for this container. The names of the files must be `cert.pem` and `key.pem`. If not specified, the default test SSL certificate (e.g. `ssl-cert-snakeoil`) shipped with Ubuntu will be used.  **Note!** The container user must have read permissions for the certificate files.
* `local/wsc_app:x.x.x` the tag of WebSpellChecker Server Docker image.

Also these parameters can be changed on container running by passing them as enviroment variables:

* protocol
* domain_name
* web_port
* virtual_dir
* license_ticket_id

For example:

```
docker run -d -p 8443:8443 -v -e protocol=1 -e domain_name=localhost -e web_port=8443 -e virtual_dir=wscservice -e license_ticket_id=6u*************ZO local/wsc_app:x.x.x
```

You can read about setting environment variables to docker container [here](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file).

## Verify work of WProofreader Server

After successful launch of a container with WebSpellChecker/WProofreader Server, and the license activation, you can verify the version and status of WProofreader Server using the commands below:

* Version: http://localhost/wscservice/api?cmd=ver

```{"COPYRIGHT":"(c) 2000-2021 WebSpellChecker LLC","PRODUCT WEBSITE":"webspellchecker.com","PROGRAM VERSION":"5.x.x.0 x64 master:xxxxxxx (xxxx) #xx"}```

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

* Demo samples: http://localhost/wscservice/samples/


## Working with container

1. Going further if you need to restart the service or container, you should use Docker [start](https://docs.docker.com/engine/reference/commandline/start/) or [stop](https://docs.docker.com/engine/reference/commandline/stop/) commands with a container Id as an option.

```
docker start <container_id>
```

2. If you need to troubleshoot issues with the application, you may want to check logs. All application logs are stored in container [logs](https://docs.docker.com/engine/reference/commandline/logs/):

```
docker logs <container_id>
```

3. If you need to configure AppServer, for example edit `AppServerX.xml`, you need to connect to a container. Use `docker exec` command to connect to a container where WProofreader is running:

```
docker exec -it <container_id> /bin/bash
```

## Create image from modified Docker container

In case you need to make any changes to the configuration of the application which is running inside Docker container (e.g. changes to `AppServerX.xml`) and keep them persistent, you can create an image from the modified container. It can be easily done with a single command:

```
docker commit <existing_container_id> <new_name_image>
```

Then check that the image has been successfully created, using `docker images` command. You will see the list of existing images. Use this new image to create new containers following the instructions on how to run container above.


## Further steps

Once a docker container with WProofreader is up and running, you need to integrate it into your web app.

* [Get Started with WProofreader Server (autoSearch)](https://docs.webspellchecker.net/pages/viewpage.action?pageId=454919195)
* [Configuring WProofreader Server in WYSIWYG Editors](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Configuring+WProofreader+Server+in+WYSIWYG+Editors)
* [Customization options](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/WProofreader+Customization+Options)
* [WProofreader API options](https://webspellchecker.com/docs/api/wscbundle/Options.html)
