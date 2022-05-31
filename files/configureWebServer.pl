
configureApachePorts();
enableSSL();

sub configureApachePorts
{
	if ($#ARGV < 2) { return; }

	my $nginxPort = $ARGV[1];
	my $nginxSSLPort = $ARGV[2];

	my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

	if (-e $nginxConf)
	{
		replaceFileContent('listen 80', "listen $nginxPort", $nginxConf);
		replaceFileContent('listen 443', "listen $nginxSSLPort", $nginxConf);
		replaceFileContent('listen \\[::]:80', "listen \[::]:$nginxPort", $nginxConf);
		replaceFileContent('listen \\[::]:443', "listen \[::]:$nginxSSLPort", $nginxConf);
	}
	
	my $nginxMainConf = '/etc/nginx/nginx.conf';
	if (-e $nginxMainConf)
	{
		replaceFileContent('pid /run/nginx.pid', 'pid /run/nginx/nginx.pid', $nginxMainConf);
	}
}

sub enableSSL
{
	if ($#ARGV < 1) { return; }

	if ($ARGV[0] ne "true") { return; }

	my $pathToCert = '/certificate/cert.pem';
	my $pathToKey = '/certificate/key.pem';

	my $nginxConf = '/etc/nginx/conf.d/wscservice.conf';

	if (-e $nginxConf)
	{
		replaceFileContent('# Note: You should disable gzip for SSL traffic.', "ssl_certificate $pathToCert;", $nginxConf);
		replaceFileContent('# See: https://bugs.debian.org/773332', "ssl_certificate_key $pathToKey;", $nginxConf);
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
