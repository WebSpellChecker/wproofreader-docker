use File::Basename;

my $serverPath = '/opt/WSC/AppServer';
my $server_config_path = "$serverPath/AppServerX.xml";

configureSamples();
configureUserAndCustomDictionaries();
configureSsl();

sub configureSamples
{
	my $protocol = $ENV{'PROTOCOL'};
	my $host = $ENV{'HOST_NAME'};
	
	if ( $host eq "" ) { $host = "localhost"; }

	if ( $protocol ne "" && $protocol ne "http" && $protocol ne "https")
	{
		die "Unknown protocol passed: $protocol";
	}

	my $samples_dir_path = '/opt/WSC/WebComponents/Samples/';
	opendir my $dir, $samples_dir_path or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;

	foreach ( @files )
	{
		if ( $_ eq '.' || $_ eq '..' ) { next; }
			
		if ( $protocol ne "" )
		{
			replaceFileContent("serviceProtocol: 'http'", "serviceProtocol: '$protocol'", "$samples_dir_path/$_");
			
			if ($protocol eq "https")
			{
				replaceFileContent("servicePort: '80'", "servicePort: '443'", "$samples_dir_path/$_");
				
				replaceFileContent("http://localhost:80/", "https://localhost:443/", "$samples_dir_path/$_");
			}
			else
			{
				replaceFileContent("servicePort: '443'", "servicePort: '80'", "$samples_dir_path/$_");
				
				replaceFileContent("https://localhost:443/", "http://localhost:80/", "$samples_dir_path/$_");
			}
		}
			
		replaceFileContent('localhost', $host, "$samples_dir_path/$_");
		
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
