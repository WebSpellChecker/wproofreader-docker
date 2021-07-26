
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