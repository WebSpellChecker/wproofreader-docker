# wproofreader-docker
Docker configuration to automatic build Wproofreader image.

1. Copy webspellchecker installation package (like wsc_app_x64_5.5.4.0_57.tar.gz) to files directory.
2. Modify installation settings into config.ini file.
3. Build package like: docker build --build-arg VERSION=5.5.4.0 -t webspellchecker/wproofreader .
4. Launch package like: docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 wproofreader <license_ticket_id> <your_host_name>
5. If your want to use custom and user dictionaries your need to share directory for the dictionaries with the docker container, so run container like this:
docker run --mac-address="12:34:d7:b0:6b:61" -d -p 80:80 -p 2880:2880 -v <your_directory_path>:/dictionaries wproofreader <license_ticket_id> <your_host_name>
