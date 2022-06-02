
configureWebPorts();

sub configureWebPorts
{
	if ($#ARGV < 1) { return; }
	
	my $port = $ARGV[0];
	my $sslPort = $ARGV[1];
	
	my $configureWebServerFile = "/opt/WSC/AppServer/configureWebServer.pl";
	
	replaceFileContent('<#NginxPort#>', $port, $configureWebServerFile);
	replaceFileContent('<#NginxSSLPort#>', $sslPort, $configureWebServerFile);
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