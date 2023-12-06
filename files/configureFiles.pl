use File::Basename;

my $serverPath = $ENV{'APP_SERVER_DIR'};
my $installPath = "$serverPath/..";
my $server_config_path = "$serverPath/AppServerX.xml";

configureSamplesAndVirtualDir();
configureUserAndCustomDictionaries();
configureSsl();
configureAppServerParams();
configureDatabase();
configureProxyParams();

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
			'serviceHost: \'[\w.-]*\'' => "serviceHost: '$host'",
			'servicePath: \'.*?\/api\'' => "servicePath: '$virtual_dir/api'",
			'((http)|(https)):\/\/[\w.-]*:\d*\/.*?\/wscbundle\/wscbundle.js' => "$protocol://$host:$web_port/$virtual_dir/wscbundle/wscbundle.js",
			'((http)|(https)):\/\/[\w.-]*:\d*\/.*?\/samples\/' => "$protocol://$host:$web_port/$virtual_dir/samples/"
		);
		replaceFileContent(\%pairs, "$samples_dir_path/$_");
	}
}

sub configureVirtualDir()
{
	my ($protocol, $host, $web_port, $virtual_dir) = @_;
	
	my $virtual_dir_file = "$installPath/WebComponents/WebInterface/index.html";
	
	replaceFileContent({'((http)|(https)):\/\/[\w.-]*:\d*\/.*?\/api\?cmd' => "$protocol://$host:$web_port/$virtual_dir/api?cmd"}, $virtual_dir_file);
	replaceFileContent({'((http)|(https)):\/\/[\w.-]*:\d*\/.*?\/samples\/' => "$protocol://$host:$web_port/$virtual_dir/samples/"}, $virtual_dir_file);
	
	print "Verify the WSC Application Operability: $protocol://$host:$web_port/$virtual_dir/ \n";
}

sub configureUserAndCustomDictionaries
{
	my $dicts_path = $ENV{'DICTIONARIES_DIR'} eq '' ? '/dictionaries' : $ENV{'DICTIONARIES_DIR'};
	my $cust_dicts_path = $ENV{'CUSTOM_DICTIONARIES_DIR'} eq '' ? "$dicts_path/CustomDictionaries" : $ENV{'CUSTOM_DICTIONARIES_DIR'};
	my $cust_dict_conf = "$cust_dicts_path/CustDictConfig.xml";
	my $user_dicts_path = $ENV{'USER_DICTIONARIES_DIR'} eq '' ? "$dicts_path/UserDictionaries" : $ENV{'USER_DICTIONARIES_DIR'};

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
	if (replaceXmlValues({ 'PathToServiceFilesDirectory' => "$ENV{'SERVICE_FILES_DIR'}" }, $server_config_path) == 0)
	{
		replaceFileContent({ '</ServiceName>' => "</ServiceName>\n	<PathToServiceFilesDirectory>$ENV{'SERVICE_FILES_DIR'}</PathToServiceFilesDirectory>" }, $server_config_path);
	}
}

sub configureDatabase
{
	my %tags = (
		'EnableRequestStatistic' => $ENV{'ENABLE_REQUEST_STATISTIC'},
		'RequestStatisticDataType' => 'DATABASE',
		'EnableRequestValidation' => $ENV{'ENABLE_REQUEST_VALIDATION'},
		'EnableUserActionStatistic' => $ENV{'ENABLE_USER_ACTION_STATISTIC'},
		'EnableDatabaseProvider' => $ENV{'ENABLE_DATABASE'},
		'DatabaseHost' => $ENV{'DATABASE_HOST'},
		'DatabasePort' => $ENV{'DATABASE_PORT'},
		'DatabaseSchema' => $ENV{'DATABASE_SCHEMA'},
		'DatabaseUser' => $ENV{'DATABASE_USER'},
		'DatabasePassword' => $ENV{'DATABASE_PASSWORD'}
	);
	replaceXmlValues(\%tags, $server_config_path);
}

sub configureProxyParams
{
	my %tags = (
		'EnableProxy' => $ENV{'ENABLE_PROXY'},
		'ProxyHost' => $ENV{'PROXY_HOST'},
		'ProxyPort' => $ENV{'PROXY_PORT'},
		'ProxyUserName' => $ENV{'PROXY_USER_NAME'},
		'ProxyPassword' => $ENV{'PROXY_PASSWORD'}
	);
	replaceXmlValues(\%tags, $server_config_path);
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

	return $n;
}

sub replaceXmlValues
{
	my ($pairs, $file) = @_;
	my %tags = map { ("<$_>.*?</$_>" => "<$_>$$pairs{$_}</$_>") } keys %$pairs;
	replaceFileContent(\%tags, $file);
}
