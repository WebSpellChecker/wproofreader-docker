# WProofreader Docker

This is a Docker configuration that you can use to build a WProofreader Server image based on the latest Ubuntu (default) or CentOS. 

**Note!** You can also use a [Docker image with WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) that we built and published on Docker Hub.

## Create Docker image

To create a custom Docker image with WProofreader Server: 

1. Clone [WProofreader Docker repo](https://github.com/WebSpellChecker/wproofreader-docker).
2. Copy the WebSpellChecker/WProofreader installation package (e.g. `wsc_app_x64_5.x.x.x_xx.tar.gz`) to `wproofreader-docker/files` directory.
3. Adjust the default installation options by modifying one of the `wproofreader-docker/files/config.ini` or `wproofreader-docker/files/configSSL.ini` (if you want to use SSL) file. 

* Activate license during the image creation. Add the following options to `config.ini` or `configSSL.ini` file.

```
activate_license = 1
license_ticket_id = 6u*************ZO
```
* Specify `domain_name` which will be used for setup of demo samples with WProofreader. By default, `localhost` will be used if nothing is specified.

```
domain_name = domain_name
```

If both `license_ticket_id` and `domain_name` were specified during the image creation, you don't need to specify these values during the launch of `docker run` command.

* If you are using a proxy server to handle inbound/outbound traffic to your network, for the automated license activation step, the following proxy settings must be added. 

```
enable_proxy = 1
proxy_host = host_name
proxy_port = port_number
proxy_user_name = user_name
proxy_password = password
```

For details on the available options, refer to [Automated Installing WebSpellChecker on Linux](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux) guide.

4. If you need to use SSL, put your SSL certificate and key files to the `wproofreader-docker/files/certificate` directory. You need to rename your certificate files to `cert.pem` and `key.pem` accordingly.

5. Build a Docker image using the command below:

```
docker build -t webspellchecker/wproofreader --build-arg ssl=true -f <Dockerfile_name> <path_to_Dockerfile_directory>
```

where:

* `-t` assign a tag name `webspellchecker/wproofreader`.
* `--build-arg ssl=true` the argument indicates if to use the SSL connection. Otherwise, just omit this option or use `false` as a value.
* `<Dockerfile_name>` a Dockerfile name, e.g. `Dockerfile` or `DockerfileCentOS`.
* `<path_to_Dockerfile_directory>` the path to a Dockerfile directory, not to Dockerfile itself. If a Dockerfile is in the same directory, e.g. `/wproofreader-docker/`, you need to use to use `.` instead of the path.

```
docker build -t webspellchecker/wproofreader --build-arg ssl=true -f Dockerfile .
```

## Create and run Docker container

Create and run a Docker container from the latest Docker image with the following options:

```
docker run -d -p 80:8080 webspellchecker/wproofreader
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <certificate_directory_path>:/certificate webspellchecker/wproofreader
```

To use global custom and user dictionaries your need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```
docker run -d -p 80:8080 -v <directory_path>:/dictionaries -v <certificate_directory_path>:/certificate webspellchecker/wproofreader
```

or (for the SSL version)

```
docker run -d -p 443:8443 -v <shared_dictionaries_directory>:/dictionaries -v <your_certificate_directory_path>:/certificate webspellchecker/wproofreader
```

where:

* `-d` start a container in detached mode.
* `-p 80:8080` map the host port `80:` and the exposed port of container `8080`, where port `8080` is a web server port (by default Apache HTTP Server). With the SSL connection, you must use port `443` like `-p 443:8443`. 
* `-v <shared_dictionaries_directory>:/dictionaries` mount a shared directory where user and company custom dictionaries will be created and stored. This is required to save the dictionaries between starts of containers.
* `-v <certificate_directory_path>:/certificate` mount a shared directory where your SSL certificates are located. Use this option if you plan to work under SSL and you want to use a specific certificate for this container. The names of the files must be `cert.pem` and `key.pem`. If not specified, the default test SSL certificate (e.g. `ssl-cert-snakeoil`) shipped with Ubuntu will be used.
* `webspellchecker/wproofreader` the latest tag of WProofreader Server Docker image.
* `license_ticket_id` your license ticket ID. **Note!** Can be skipped if you specified it during the image creation.
* `domain_name` the name of a host name that will be used for setup of demo samples with WProofreader. This is an optional parameter, and if nothing is specified, `localhost` will be used (e.g. http(s)://localhost/wscservice/samples/). **Note!** Can be skipped if you specified it during the image creation.

## Verify work of WProofreader Server

After successful launch of a container with WProofreader Server, and the license activation, you can verify the version and status of WProofreader Server using the commands below:

* Version: http://localhost/wscservice/api/?cmd=ver

```{"COPYRIGHT":"(c) 2000-2021 WebSpellChecker LLC","PRODUCT WEBSITE":"webspellchecker.com","PROGRAM VERSION":"5.x.x.0 x64 master:xxxxxxx (xxxx) #xx"}```

* Status: http://localhost/wscservice/api/?cmd=status

```
{
    "Spell Check Engine": {
        "active": true
    },
    "Grammar Check Engine": {
        "active": true
    },
    "Thesaurus Engine": {
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

2. If you need to troubleshoot issues with the application, you may want to check log files in `opt/WSC/AppServer/Logs` directory. For this, you need to connect to a container. Use `docker exec` command to connect to a container where WProofreader is running:

```
docker exec -it <container_id> bash
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
