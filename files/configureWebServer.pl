
configureNGINX();

sub configureNGINX
{
	my $nginxPort = <#NginxPort#>;
	my $nginxSSLPort = <#NginxSSLPort#>;

	my $protocol = $ENV{'PROTOCOL'};

	if ( $protocol ne "" && $protocol ne "http" && $protocol ne "https")
	{
		die "Unknown protocol passed: $protocol";
	}

	my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

	if (-e $nginxConf)
	{
		if ($protocol eq "")
		{
			if ( open(LOGFILE, "<$nginxConf") ) 
			{ 
				my $isSSL = 0;
			
				while (<LOGFILE>){
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
				
				close (LOGFILE);
			}
			
			replaceFileContent('listen 80;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			
			replaceFileContent('listen 443 ssl;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
		}
		elsif ($protocol ne "https")
		{	
			replaceFileContent('listen 80;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen 443 ssl;', "listen $nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxPort default_server;", $nginxConf);
			
			print "Container started on HTTP protocol.\n";
		}
		else
		{
			replaceFileContent('listen 80;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen 443 ssl;', "listen $nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:80;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			replaceFileContent('listen \\[::]:443 ssl;', "listen \[::]:$nginxSSLPort ssl default_server;", $nginxConf);
			
			enableSSL();
			
			print "Container started on HTTPS protocol.\n";
		}
	}
	
	my $nginxMainConf = '/etc/nginx/nginx.conf';
	if (-e $nginxMainConf)
	{
		replaceFileContent('pid /run/nginx.pid', 'pid /run/nginx/nginx.pid', $nginxMainConf);
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
