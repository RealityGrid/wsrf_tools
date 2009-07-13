
package ReG_Utils;

use SOAP::Lite;
use WSRF::Lite;
use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);;
use strict;

$ReG_Utils::randInitialized = 0;

#----------------------------------------------------
# Returns a SOAP::Data object containing a completed
# wsse:UsernameToken

sub makeWSSEHeader {

    my ($username, $password) = @_;

    if($ReG_Utils::randInitialized == 0){
        # seed the random number generator
        srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
        $ReG_Utils::randInitialized = 1;
    }
    my $num = rand 1000000;
    my $nonce = encode_base64("$num", "");

    # Get the time and date
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    # month returned by localtime is zero-indexed and we need to convert to
    # a four-digit date...
    my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                           $year+1900,$mon+1,$mday,$hour,$min,$sec;

    # Password digest = Base64( SHA-1(nonce + created + password) )
    my $digest = sha1_base64($nonce . $launch_time . $password);
    my $user = SOAP::Data->name('wsse:Username' => $username);
    my $passData = SOAP::Data->name('wsse:Password' => $digest);
    my $nonceData = SOAP::Data->name('wsse:Nonce' => $nonce);
    my $created = SOAP::Data->name('wsse:Created' => $launch_time);

    my $hdr1 = SOAP::Data->new(name => 'wsse:UsernameToken',
                               value => \SOAP::Data->value($user,
                                                           $passData,
                                                           $nonceData,
                                                           $created));
    return $hdr1;
}

#----------------------------------------------------

sub getUsername {

    my $DN="";
    if( open(CERT_FILE, $ENV{HTTPS_CERT_FILE}) ){
	my @lines = <CERT_FILE>;
	close(CERT_FILE);

	foreach my $line (@lines){

	    if($line =~ m/^subject=/){
		chomp($line);
		$line =~ s/^subject=//o;
		$DN = $line;
		last;
	    }
	}
    }
    else{
	$DN = $ENV{'USER'};
    }
    print "Your DN = $DN\n";
    return $DN;
}

1;

