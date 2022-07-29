my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

configureNginx();
configureNginxConfig();

sub configureNginx
{
	my $nginxPort = $ENV{'WEB_SERVER_PORT'};
	my $nginxSSLPort = $ENV{'WEB_SERVER_SSL_PORT'};

	my $protocol = $ENV{'PROTOCOL'};

	if ( $protocol ne "" && $protocol ne "http" && $protocol ne "https")
	{
		die "Unknown protocol passed: $protocol";
	}

	if (-e $nginxConf)
	{
		if ($protocol eq "") # protocol was not specified on start, using predefined
		{
			if ( open(CONFFILE, "<$nginxConf") ) 
			{ 
				my $isSSL = 0;
			
				while (<CONFFILE>){
					if ($_ =~ /listen 443 ssl/)
					{
						enableSSL();
						print "Container automatically started on HTTPS protocol.\n";
						$isSSL = 1;
						break;
					}
				}
				
				if ($isSSL eq 0)
				{
					print "Container automatically started on HTTP protocol.\n";
				}
				
				close (CONFFILE);
			}
			
			replaceFileContent('listen 80;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			
			replaceFileContent('listen 443 ssl;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
		}
		elsif ($protocol ne "https") # using http protocol
		{	
			replaceFileContent('listen 80;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen 443 ssl;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			
			print "Container started on HTTP protocol.\n";
		}
		else # using https protocol
		{
			replaceFileContent('listen 80;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen 443 ssl;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			
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
	
	my $host = $ENV{'HOST_NAME'};
	
	if (-e $nginxConf && $host ne "")
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
