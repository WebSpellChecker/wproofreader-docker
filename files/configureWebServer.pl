my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

configureNginx();
configureNginxConfig();

sub configureNginx
{
	my $nginxPort = $ENV{'WEB_SERVER_PORT'};
	my $nginxSSLPort = $ENV{'WEB_SERVER_SSL_PORT'};

	my $protocol = $ENV{'protocol'};

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
		replaceFileContent('pid /run/nginx.pid', 'pid /run/nginx/nginx.pid', $nginxMainConf);
	}
	
	my $host = $ENV{'domain_name'};
	
	if (-e $nginxConf)
	{
		replaceFileContent('localhost', $host, $nginxConf);
	}
}

sub enableSSL
{
	my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

	my $pathToCert = '/certificate/cert.pem';
	my $pathToKey = '/certificate/key.pem';

	if (-e $nginxConf)
	{
		replaceFileContent('# bindings of static files', "ssl_certificate $pathToCert;\n    ssl_certificate_key $pathToKey;\n", $nginxConf);
	}
}


sub replaceFileContent
{
	my ($source, $dest, $path) = @_;
	local $/ = undef;
	open (F,$path) || die "Error! Failed to open '${path}'. $! - Aborting.\n";
	my $file = <F>;
	close(F);

	my $n = ($file =~ s/$source/$dest/g);
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
