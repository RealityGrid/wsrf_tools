#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, "/home/zzcguap/projects/WSRF-Lite" );
};

#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);;
use strict;

#need to point to users certificates - these are only used
#if https protocal is being used.
#$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if( @ARGV < 1 )
{
  print "  Script to destroy a WS-Resource\n\n";	
  print "Usage:\n Destroy.pl URL [URL2 URL3...]\n\n";
  print "     URL is the endpoint of the service\n\n";
  print "Destroy.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279\n";
  exit;
}

# seed the random number generator
srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
my $num = rand 1000000;
my $nonce = encode_base64("$num", "");

my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $created = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

my $passphrase;
if($ARGV[0] =~ m/\/SWS\/SWS\//){
    print "Enter SWS passphrase: ";
    $passphrase = <STDIN>;
    chomp($passphrase);
    print "\n";
}
#my $passphrase = "somethingcunning";

# Password digest = Base64( SHA-1(nonce + created + password) )
my $digest = sha1_base64($nonce . $created . $passphrase);

my $user = SOAP::Data->name('wsse:Username' => 'Andy_Porter');
my $passwd = SOAP::Data->name('wsse:Password' => $digest);
my $nonce = SOAP::Data->name('wsse:Nonce' => $nonce);
my $created = SOAP::Data->name('wsse:Created' => $created);

my $hdr1 = SOAP::Data->new(name => 'wsse:UsernameToken', 
			   value => \SOAP::Data->value($user,
						       $passwd,
						       $nonce,
						       $created));
my $target;
#get the location of the service
while(defined($target = shift @ARGV)){

    my $ans=  WSRF::Lite
	-> uri($WSRF::Constants::WSRL)
	-> wsaddress(WSRF::WS_Address->new()->Address($target))  
	-> Destroy(SOAP::Header->name('wsse:Security')->value(\$hdr1));

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
    if( defined($ans) ){
	if ($ans->fault){
	    print $ans->faultcode, " ", $ans->faultstring, "\n";
	}
	else{
	    print "\nResult = ".$ans->result." Resource Destroyed\n";	
	}
    }
}
print "\n";
