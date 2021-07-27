
configureApachePorts();
enableSSL();

sub configureApachePorts
{
	if ($#ARGV < 2) { return; }

	my $apachePort = $ARGV[1];
	my $apacheSSLPort = $ARGV[2];

	my $apache2Conf = '/etc/apache2/apache2.conf';
	my $portsConfPath = '/etc/apache2/ports.conf';
	my $defaultConfPath = '/etc/apache2/sites-available/default.conf';
	my $defaultSSLConfPath = '/etc/apache2/sites-available/default-ssl.conf';

	my $portsConfPathCentos = '/etc/httpd/conf/httpd.conf';
	my $defaultSSLConfPathCentos = '/etc/httpd/conf.d/ssl.conf';

	if (-e $apache2Conf)
	{
		addLineToFile("ServerName 127.0.0.1\n", $apache2Conf);
	}
	if (-e $portsConfPath)
	{
		replaceFileContent('Listen 80', "Listen $apachePort", $portsConfPath);
		replaceFileContent('Listen 443', "Listen $apacheSSLPort", $portsConfPath);
	}
	if (-e $defaultConfPath)
	{
		replaceFileContent('<VirtualHost *:80>', "<VirtualHost *:$apachePort>", $defaultConfPath);
	}
	if (-e $defaultSSLConfPath)
	{
		replaceFileContent('<VirtualHost _default_:443>', "<VirtualHost _default_:$apacheSSLPort>", $defaultSSLConfPath);
	}

	if (-e $portsConfPathCentos)
	{
		addLineToFile("ServerName 127.0.0.1\n", $portsConfPathCentos);
		replaceFileContent('Listen 80', "Listen $apachePort", $portsConfPathCentos);
	}
	if (-e $defaultSSLConfPathCentos)
	{
		replaceFileContent('Listen 443', "Listen $apacheSSLPort", $defaultSSLConfPathCentos);
		replaceFileContent('<VirtualHost _default_:443>', "<VirtualHost _default_:$apacheSSLPort>", $defaultSSLConfPathCentos);
	}
}

sub enableSSL
{
	if ($#ARGV < 1) { return; }

	if ($ARGV[0] ne "true") { return; }

	`a2enmod ssl`;
	`a2ensite default-ssl`;

	my $pathToCert = '\\/certificate\\/cert.pem/';
	my $pathToKey = '\\/certificate\\/key.pem/';

	my $pathToApacheConfUbuntu = '/etc/apache2/sites-available/default-ssl.conf';

	if (-e $pathToApacheConfUbuntu)
	{
		`sed -i "s/\\(\\s*\\)SSLCertificateFile.*\\/.*/\\1SSLCertificateFile $pathToCert" $pathToApacheConfUbuntu`;
		`sed -i "s/\\(\\s*\\)SSLCertificateKeyFile.*\\/.*/\\1SSLCertificateKeyFile $pathToKey" $pathToApacheConfUbuntu`;
	}

	my $pathToApacheConfCentos = '/etc/httpd/conf.d/ssl.conf';

	if (-e $pathToApacheConfCentos)
	{
		`sed -i "s/\\(\\s*\\)SSLCertificateFile.*\\/.*/\\1SSLCertificateFile $pathToCert" $pathToApacheConfCentos`;
		`sed -i "s/\\(\\s*\\)SSLCertificateKeyFile.*\\/.*/\\1SSLCertificateKeyFile $pathToKey" $pathToApacheConfCentos`;
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
