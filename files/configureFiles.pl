use File::Basename;

my $serverPath = $ENV{'WPR_APP_SERVER_DIR'};
my $installPath = "$serverPath/..";
my $server_config_path = "$serverPath/AppServerX.xml";

printStartEndpoint();
configureUserAndCustomDictionaries();

sub printStartEndpoint
{
	my $protocol = $ENV{'WPR_PROTOCOL'} eq '1' ? 'https' : 'http';
	# If user don't specify WEB_PORT, using default 80 for http and 443 for https
	my $web_port = $ENV{'WPR_WEB_PORT'} eq "" ? ($protocol eq "https" ? "443" : "80") : $ENV{'WPR_WEB_PORT'};
	my $virtual_dir = $ENV{'WPR_VIRTUAL_DIR'};

	# Normalize virtual_dir for display
	my $is_root_path = ($virtual_dir eq '/' || $virtual_dir eq '');
	my $vdir_part = $is_root_path ? '' : $virtual_dir;
	$vdir_part =~ s/^\///;  # Remove leading slash if present
	$vdir_part = '/' . $vdir_part if $vdir_part ne '';  # Add it back with proper formatting

	print "Verify the WSC Application Operability: $protocol://<host>:$web_port$vdir_part/ \n";
}

sub configureUserAndCustomDictionaries
{
	my $dicts_path = $ENV{'WPR_DICTIONARIES_DIR'} eq '' ? '/dictionaries' : $ENV{'WPR_DICTIONARIES_DIR'};
	my $cust_dicts_path = $ENV{'WPR_CUSTOM_DICTIONARIES_DIR'} eq '' ? "$dicts_path/CustomDictionaries" : $ENV{'WPR_CUSTOM_DICTIONARIES_DIR'};
	my $cust_dict_conf = "$cust_dicts_path/CustDictConfig.xml";
	my $user_dicts_path = $ENV{'WPR_USER_DICTIONARIES_DIR'} eq '' ? "$dicts_path/UserDictionaries" : $ENV{'WPR_USER_DICTIONARIES_DIR'};
	my $style_guide_path = $ENV{'WPR_STYLE_GUIDE_DIR'} eq '' ? "$dicts_path/StyleGuide" : $ENV{'WPR_STYLE_GUIDE_DIR'};

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
	
	if (! -e $style_guide_path)
	{
		system("mv $serverPath/StyleGuide $style_guide_path");
	}

	if (! -e $cust_dict_conf)
	{
		system("mv $serverPath/CustDictConfig.xml $cust_dict_conf");
	}
	
	replaceFileContent({ '<StyleGuideCheck Enabled="(true|false)">[\s]*?<DirectoryPath>[\w\\\/:]*?<\/DirectoryPath>[\s]*?<\/StyleGuideCheck>' =>
		"<StyleGuideCheck Enabled=\"true\">\n\t\t<DirectoryPath>$style_guide_path</DirectoryPath>\n\t</StyleGuideCheck>" }, $server_config_path);
	
	for my $file (<$serverPath/CustomDictionaries/*.txt>)
	{
		my $file_name = basename($file);
		if (! -e "$cust_dicts_path/$file_name")
		{
			system("mv $file $cust_dicts_path/");
		}
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

	return $n;
}

sub replaceXmlValues
{
	my ($pairs, $file) = @_;
	my %tags = map { ("<$_>.*?</$_>" => "<$_>$$pairs{$_}</$_>") } keys %$pairs;
	replaceFileContent(\%tags, $file);
}
