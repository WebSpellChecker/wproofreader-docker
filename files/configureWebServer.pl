my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

configureNginx();
configureNginxConfig();

sub configureNginx
{
	my $nginxPort = $ENV{'WEB_SERVER_PORT'};
	my $nginxSSLPort = $ENV{'WEB_SERVER_SSL_PORT'};

	my $protocol = $ENV{'PROTOCOL'};

	if (-e $nginxConf)
	{
		if ($protocol eq "2") # using http protocol
		{	
			replaceFileContent('listen \d*;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \d* ssl;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:\d*;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:\d* ssl;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			
			print "Container started on HTTP protocol.\n";
		}
		else # using https protocol
		{
			replaceFileContent('listen \d*;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \d* ssl;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:\d*;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:\d* ssl;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			
			enableSSL();
			
			print "Container started on HTTPS protocol.\n";
		}
	}
}

sub configureNginxConfig
{
	my $nginxMainConf = '/etc/nginx/nginx.conf';
	if (-e $nginxMainConf)
	{
		# Make separate directory for nginx pid
		replaceFileContent('pid .*;', 'pid /run/nginx/nginx.pid;', $nginxMainConf);
		
		# Disable access log
		replaceFileContent('access_log .*;', 'access_log off;', $nginxMainConf);
		
		# Remove default server from main log
		replaceFileContent('    server {\n(?:.*\n){15}    }', '', $nginxMainConf);
	}
	
	my $host = $ENV{'DOMAIN_NAME'};
	my $virtual_dir = $ENV{'VIRTUAL_DIR'};
	
	if (-e $nginxConf)
	{
		if ($host ne "")
		{
			# Change server name inside NGINX config
			replaceFileContent('server_name \w*;', "server_name $host;", $nginxConf);
		}
		
		if ($virtual_dir ne "")
		{
			# Change virtual dir inside NGINX config
			replaceFileContent('location \/.*? {', "location /$virtual_dir {", $nginxConf);
			replaceFileContent('location \/.*?/samples {', "location /$virtual_dir/samples {", $nginxConf);
			replaceFileContent('location \/.*?/wscbundle/ {', "location /$virtual_dir/wscbundle/ {", $nginxConf);
			replaceFileContent('location \/.*?/api {', "location /$virtual_dir/api {", $nginxConf);
		}
	}
}

sub enableSSL
{
	my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

	my $certDir = $ENV{'CERT_DIR'};
	my $certName = $ENV{'CERT_FILE_NAME'};
	my $keyName = $ENV{'CERT_KEY_NAME'};

	if (-e $nginxConf)
	{
		# Add ssl certificates to NGINX config
		replaceFileContent('# bindings of static files', "ssl_certificate $certDir/$certName;\n    ssl_certificate_key $certDir/$keyName;\n", $nginxConf);
	}
}


sub replaceFileContent
{
	my ($source, $dest, $path) = @_;
	local $/ = undef;
	open (F,$path) || die "Error! Failed to open '${path}'. $! - Aborting.\n";
	my $file = <F>;
	close(F);

	my $n = ($file =~ s/$source/$dest/);
	if ($n > 0)
	{
		open(F,">$path");
		print F $file;
		close(F);
	}
}

sub addLineToFile
{
	my ($line, $path) = @_;
	open (F,">>$path") || die "Error! Failed to open '${path}'. $! - Aborting.\n";
	print F $line;
	close(F);
}
