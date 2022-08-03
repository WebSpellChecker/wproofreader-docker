use File::Basename;

my $serverPath = '/opt/WSC/AppServer';
my $server_config_path = "$serverPath/AppServerX.xml";

configureSamples();
configureUserAndCustomDictionaries();
configureSsl();
configureAppServerParams();

sub configureSamples
{
	my $protocol = $ENV{'protocol'} eq '1' ? 'https' : 'http';
	my $host = $ENV{'domain_name'};

	my $samples_dir_path = '/opt/WSC/WebComponents/Samples/';
	opendir my $dir, $samples_dir_path or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;

	# If user don't specify web_port, using default 80 for http and 443 for https
	my $web_port = $ENV{'web_port'} eq "" ? ($protocol eq "https" ? "443" : "80") : $ENV{'web_port'};
	my $virtual_dir = $ENV{'virtual_dir'};

	foreach ( @files )
	{
		if ( $_ eq '.' || $_ eq '..' ) { next; }
			
		replaceFileContent('serviceProtocol: \'((http)|(https))\'', "serviceProtocol: '$protocol'", "$samples_dir_path/$_");
		replaceFileContent('servicePort: \'\d*\'', "servicePort: '$web_port'", "$samples_dir_path/$_");
		replaceFileContent('serviceHost: \'\w*\'', "serviceHost: '$host'", "$samples_dir_path/$_");
		replaceFileContent('servicePath: \'\w*/api\'', "servicePath: '$virtual_dir/api'", "$samples_dir_path/$_");
		
		# Configure path to wscbundle
		replaceFileContent('((http)|(https)):\/\/\w*:\d*\/\w*\/wscbundle/wscbundle.js', "$protocol://$host:$web_port/$virtual_dir/wscbundle/wscbundle.js", "$samples_dir_path/$_");
	}
}

sub configureUserAndCustomDictionaries
{
	my $dicts_path = '/dictionaries';
	my $cust_dicts_path = "$dicts_path/CustomDictionaries";
	replaceFileContent('<CustDictDir>CustomDictionaries</CustDictDir>',
	"<CustDictDir>$cust_dicts_path</CustDictDir>", $server_config_path);

	my $cust_dict_conf = "$cust_dicts_path/CustDictConfig.xml";
	replaceFileContent('<CustDictConfig>CustDictConfig.xml</CustDictConfig>',
		"<CustDictConfig>$cust_dict_conf</CustDictConfig>", $server_config_path);

	my $user_dicts_path = "$dicts_path/UserDictionaries";
	replaceFileContent('<UserDictDir>UserDictionaries</UserDictDir>',
		"<UserDictDir>$user_dicts_path</UserDictDir>", $server_config_path);

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
	my $verificationMode = 'NONE';
	replaceFileContent('<VerificationMode>RELAXED</VerificationMode>',
		"<VerificationMode>$verificationMode</VerificationMode>", $server_config_path);
}

sub configureAppServerParams
{
	replaceFileContent('<Size>\d*</Size>', '<Size>0</Size>', "AppServerX.xml");
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
