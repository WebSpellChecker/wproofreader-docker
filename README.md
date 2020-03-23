# WProofreader Docker

This is a Docker configuration that you can use to build a WProofreader image. 

Note! You can also use a [Docker image with WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) that we built and published on Doker Hub.

To create and use a custom Docker image with WProofreader Server: 

1. Clone [WProofreader Docker repo](https://github.com/WebSpellChecker/wproofreader-docker).
2. Copy the WebSpellChecker/WProofreader installation package (e.g. `wsc_app_x64_5.5.4.0_57.tar.gz`) to `wproofreader-docker/files` directory.
3. If needed, adjust the default installation options by modifying the `wproofreader-docker/files/config.ini` or `wproofreader-docker/files/configSSL.ini` (if you want to use SSL) file. For details on the available options, refer to [Automated Installing WebSpellChecker on Linux](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux) guide.
4. If you need to use SSL you can put your SSL certificate and key files to `wproofreader-docker/files/certificate` directory. You need to rename your files to cert.pem and key.pem.
5. Build a Docker image using the command below:

```docker build -t webspellchecker/wproofreader --build-arg ssl=true <path_to_Dockerfile_directory>```

where:

* `-t` assign a tag name `webspellchecker/wproofreader`.
* `--build-arg ssl=true` the argument indicates whether to use the SSL connection.
* `<path_to_Dockerfile_directory> ` the path to a Dockerfile directory (not to Dockerfile itself). If a Dockerfile is in the same directory, e.g. `/wproofreader-docker/`, you need to use to use `.` instead of the path.

```docker build -t webspellchecker/wproofreader .```

5. Create and run a Docker container from the latest Docker image with the following options:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 webspellchecker/wproofreader <license_ticket_id> <your_host_name>```

To use global custom and user dictionaries your need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 -v <your_directory_path>:/dictionaries -v <your_certificate_directory_path>:/certificate webspellchecker/wproofreader <license_ticket_id> <your_host_name>```

where:

* `--mac-address="12:34:d7:b0:6b:61"` predefine a MAC address of Docker container to ensure the correct licensing process.
* `-d` start a container in detached mode.
* `-p 80:80` and `-p 2880:2880` map the host port and the exposed port of container, where port 80 is a web server port and 2880 is the service port.
* `-v <shared_dictionaries_directory>:/dictionaries` mount a shared directory where personal user and global custom dictionaries will be created and stored. This is required to save the dictionaries between starts of containers.
* `-v <your_certificate_directory_path>:/certificate` mount a shared directory where your personal SSL certificates are placed. You can use the option if you work under SSL and you want to use specific certificate for this contatiner. The names of the files must be cert.pem and key.pem.
* `webspellchecker/wproofreader` the latest tag of WProofreader Server Docker image.
* `license_ticket_id` your license ticket ID.
* `your_host_name` the name of a host name that will be used for setup of demo samples with WProofreader. This is an optional parameter, and if nothing is specified, `localhost` will be used (e.g. http://localhost/wscservice/samples/).


## Working with Container

1. Going further if you need to restart the service or container, you should use Docker [start](https://docs.docker.com/engine/reference/commandline/start/) or [stop](https://docs.docker.com/engine/reference/commandline/stop/) commands with a container Id as an option.

```docker start <container_id>```

2. If you are creating a new container (upgrade the version, migrate to another server, etc.), you must deactivate a license first. Otherwise, it will be broken.

To deactive the license propely, the following steps are required:

* Connect to a container where WProofreader is running using `docker exec` command:

```docker exec -it <container_id> bash```
* Deactivate a license following the steps described in the [manual](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/License+Deactivation+on+Linux).

After that you can use your license safely with a new container. The steps how to start a new container are described above.

## Further Steps

Once a docker container with WProofreader is up and running, you need to integrate it into your web app.

* [Get Started with WProofreader Server (autoSearch)](https://docs.webspellchecker.net/pages/viewpage.action?pageId=454919195)
* [Configuring WProofreader Server in WYSIWYG Editors](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Configuring+WProofreader+Server+in+WYSIWYG+Editors)
* [Customization Options](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/WProofreader+Customization+Options)



  
