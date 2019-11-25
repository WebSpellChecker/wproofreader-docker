# WProofreader Docker

This is a Docker configuration that you can use to build a WProofreader image. 

Note! You can also use a [Docker image with WProofreader Server](https://hub.docker.com/r/webspellchecker/wproofreader) that we built and published on Doker Hub.

1. Copy the WebSpellChecker/WProofreader installation package (e.g. `wsc_app_x64_5.5.4.0_57.tar.gz`) to `wproofreader-docker/files` directory.
2. Modify installation settings in `config.ini` file. Refer to the guide [here](https://docs.webspellchecker.net/display/WebSpellCheckerServer55x/Automated+Installing+WebSpellChecker+on+Linux).
3. Build a Docker image using the command below:

```docker build -t webspellchecker/wproofreader```

4. Run a Docker container with WProofreader Server using the command below:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 webspellchecker/wproofreader <license_ticket_id> <your_host_name>```

To use global custom and user dictionaries your need to share a directory for the dictionaries with the Docker container. To do so, run a container as follows:

```docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 -v <your_directory_path>:/dictionaries webspellchecker/wproofreader <license_ticket_id> <your_host_name>```
