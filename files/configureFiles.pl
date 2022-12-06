use File::Basename;

my $installPath = '/opt/WSC';
my $serverPath = "$installPath/AppServer";
my $server_config_path = "$serverPath/AppServerX.xml";

configureSamplesAndVirtualDir();
configureUserAndCustomDictionaries();
configureSsl();
configureAppServerParams();
configureDatabase();

sub configureSamplesAndVirtualDir
{
	my $protocol = $ENV{'PROTOCOL'} eq '1' ? 'https' : 'http';
	my $host = $ENV{'DOMAIN_NAME'};

	# If user don't specify WEB_PORT, using default 80 for http and 443 for https
	my $web_port = $ENV{'WEB_PORT'} eq "" ? ($protocol eq "https" ? "443" : "80") : $ENV{'WEB_PORT'};
	my $virtual_dir = $ENV{'VIRTUAL_DIR'};

	configureVirtualDir($protocol, $host, $web_port, $virtual_dir);
	
	configureSamples($protocol, $host, $web_port, $virtual_dir);
}

sub configureSamples()
{
	my ($protocol, $host, $web_port, $virtual_dir) = @_;
	
	my $samples_dir_path = "$installPath/WebComponents/Samples/";
	opendir my $dir, $samples_dir_path or return;
	my @files = readdir $dir;
	closedir $dir;

	foreach ( @files )
	{
		if ( $_ eq '.' || $_ eq '..' ) { next; }

		my %pairs = (
			'serviceProtocol: \'((http)|(https))\'' => "serviceProtocol: '$protocol'",
			'servicePort: \'\d*\'' => "servicePort: '$web_port'",
			'serviceHost: \'\w*\'' => "serviceHost: '$host'",
			'servicePath: \'\w*/api\'' => "servicePath: '$virtual_dir/api'",
			'((http)|(https)):\/\/\w*:\d*\/\w*\/wscbundle\/wscbundle.js' => "$protocol://$host:$web_port/$virtual_dir/wscbundle/wscbundle.js",
			'((http)|(https)):\/\/\w*:\d*\/\w*\/samples\/' => "$protocol://$host:$web_port/$virtual_dir/samples/"
		);
		replaceFileContent(\%pairs, "$samples_dir_path/$_");
	}
}

sub configureVirtualDir()
{
	my ($protocol, $host, $web_port, $virtual_dir) = @_;
	
	my $virtual_dir_file = "$installPath/WebComponents/WebInterface/index.html";
	
	replaceFileContent({'((http)|(https)):\/\/\w*:\d*\/\w*\/' => "$protocol://$host:$web_port/$virtual_dir/"}, $virtual_dir_file);
	
	print "Verify the WSC Application Operability: $protocol://$host:$web_port/$virtual_dir/ \n";
}

sub configureUserAndCustomDictionaries
{
	my $dicts_path = '/dictionaries';
	my $cust_dicts_path = "$dicts_path/CustomDictionaries";
	my $cust_dict_conf = "$cust_dicts_path/CustDictConfig.xml";
	my $user_dicts_path = "$dicts_path/UserDictionaries";

	replaceXmlValues({'CustDictDir' => $cust_dicts_path,
					 'CustDictConfig' => $cust_dict_conf,
					 'UserDictDir' => $user_dicts_path},
					 $server_config_path);

	if (! -e $cust_dicts_path)
	{
		mkdir $cust_dicts_path;
	}

	if (! -e $user_dicts_path)
	{
		mkdir $user_dicts_path;
	}

	if (! -e $cust_dict_conf)
	{
		system("mv $serverPath/CustDictConfig.xml $cust_dict_conf");
	}
	
	for my $file (<$serverPath/CustomDictionaries/*.txt>)
	{
		my $file_name = basename($file);
		if (! -e "$cust_dicts_path/$file_name")
		{
			system("mv $file $cust_dicts_path/");
		}
	}
}

sub configureSsl
{
	replaceXmlValues({ 'VerificationMode' => 'NONE' }, $server_config_path);
}

sub configureAppServerParams
{
	replaceXmlValues({ 'Size' => '0' }, $server_config_path);
}

sub configureDatabase
{
	if ($ENV{'ENABLE_REQUEST_STATISTIC'})
	{
		my %tags = (
			'EnableRequestStatistic' => 'true',
			'RequestStatisticDataType' => 'DATABASE',
			'EnableRequestValidation' => 'true',
			'EnableUserActionStatistic' => 'true',
			'EnableDatabaseProvider' => 'true',
			'DatabaseHost' => $ENV{'DATABASE_HOST'},
			'DatabasePort' => $ENV{'DATABASE_PORT'},
			'DatabaseSchema' => $ENV{'DATABASE_SCHEMA'},
			'DatabaseUser' => $ENV{'DATABASE_USER'},
			'DatabasePassword' => $ENV{'DATABASE_PASSWORD'}
		);
		replaceXmlValues(\%tags, $server_config_path);
	}
}

sub replaceFileContent
{
	my ($pairs, $path) = @_;
	local $/ = undef;
	open (F,$path) || die "Error! Failed to open '${path}'. $! - Aborting.\n";
	my $file = <F>;
	close(F);

	my $n = 0;
	while (my ($key, $value) = each %$pairs)
	{
		$n += ($file =~ s/$key/$value/g);
	}

	if ($n > 0)
	{
		open(F,">$path");
		print F $file;
		close(F);
	}
}

sub replaceXmlValues
{
	my ($pairs, $file) = @_;
	my %tags = map { ("<$_>.*?</$_>" => "<$_>$$pairs{$_}</$_>") } keys %$pairs;
	replaceFileContent(\%tags, $file);
}