
configureApachePorts();

sub configureApachePorts
{
	if ($#ARGV < 1) { return; }

	my $apachePort = $ARGV[0];
	my $apacheSSLPort = $ARGV[1];

	my $portsConfPath = '/etc/apache2/ports.conf';
	my $defaultConfPath = '/etc/apache2/sites-available/default.conf';
	my $defaultSSLConfPath = '/etc/apache2/sites-available/default-ssl.conf';

	replaceFileContent('Listen 80', "Listen $apachePort", $portsConfPath);
	replaceFileContent('Listen 443', "Listen $apacheSSLPort", $portsConfPath);
	if (-e $defaultConfPath)
	{
		replaceFileContent('<VirtualHost *:80>', "<VirtualHost *:$apachePort>", $defaultConfPath);
	}
	if (-e $defaultSSLConfPath)
	{
		replaceFileContent('<VirtualHost _default_:443>', "<VirtualHost _default_:$apacheSSLPort>", $defaultSSLConfPath);
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
