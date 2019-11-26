# WProofreader Docker

This is a Docker configuration that you can use to build a WProofreader image. 

Note! You can also use a [Docker image with WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) that we built and published on Doker Hub.

1. Clone this [repo](https://github.com/WebSpellChecker/wproofreader-docker)).
2. Copy the WebSpellChecker/WProofreader installation package (e.g. `wsc_app_x64_5.5.4.0_57.tar.gz`) to `wproofreader-docker/files` directory.
3. If needed, adjust the default installation options by modifying the `wproofreader-docker/files/config.ini` file. For details about available options refer to the guide [here](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux).
4. Build a Docker image using the command below:

```docker build -t webspellchecker/wproofreader <path_to_Dockerfile_directory>```

5. Run the latest Docker image with the following options:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 webspellchecker/wproofreader <license_ticket_id> <your_host_name>```

To use global custom and user dictionaries your need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 -v <your_directory_path>:/dictionaries webspellchecker/wproofreader <license_ticket_id> <your_host_name>```

where:

* `--mac-address="12:34:d7:b0:6b:61"` predefine a MAC address of Docker container to ensure the correct licensing process.
* `-d` start a container in detached mode.
* `-p 80:80` and `-p 2880:2880` map the host port and the exposed port of container, where port 80 is a web server port and 2880 is the service port.
* `-v <shared_dictionaries_directory>:/dictionaries` mount a shared directory where personal user and global custom dictionaries will be created and stored. This is required to save the dictionaries between starts of containers.
* `webspellchecker/wproofreader` the latest tag of WProofreader Server Docker image.
* `license_ticket_id` your license ticket ID.
* `your_host_name` the name of a host name that will be used for setup of demo samples with WProofreader. This is an optional parameter, and if nothing is specified, `localhost` will be used (e.g. http://localhost/wscservice/samples/).
