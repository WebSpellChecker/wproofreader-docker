
`a2enmod ssl`;
`a2ensite default-ssl`;

my $pathToApacheConf = '/etc/apache2/sites-available/default-ssl.conf';
my $pathToCert = '\\/certificate\\/cert.pem/';
my $pathToKey = '\\/certificate\\/key.pem/';

`sed -i "s/\\(\\s*\\)SSLCertificateFile.*\\/.*/\\1SSLCertificateFile $pathToCert" $pathToApacheConf`;
`sed -i "s/\\(\\s*\\)SSLCertificateKeyFile.*\\/.*/\\1SSLCertificateKeyFile $pathToKey" $pathToApacheConf`;

