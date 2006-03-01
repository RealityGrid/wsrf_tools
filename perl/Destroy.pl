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
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
#$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
#$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if( @ARGV < 1 )
{
  print "  Script to destroy a WS-Resource\n\n";	
  print "Usage:\n Destroy.pl URL [URL2 URL3...]\n\n";
  print "     URL is the endpoint of the service\n\n";
  print "Destroy.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279\n";
  exit;
}

print "Enter passphrase for service (if any): ";
my $passphrase = <STDIN>;
chomp($passphrase);
print "\n";

my $DN = ReG_Utils::getUsername();
my $hdr = ReG_Utils::makeWSSEHeader($DN, $passphrase);

my $target;
while(defined($target = shift @ARGV)){

    my $ans=  WSRF::Lite
	-> uri($WSRF::Constants::WSRL)
	-> wsaddress(WSRF::WS_Address->new()->Address($target))  
	-> Destroy(SOAP::Header->name('wsse:Security')->value(\$hdr));

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
    if( defined($ans) ){
	if ($ans->fault){
	    print $ans->faultcode, " ", $ans->faultstring, "\n";
	    print "Error description: ".$ans->valueof("//Description")."\n";
	}
	else{
	    print "\nResult = ".$ans->result." Resource Destroyed\n";	
	}
    }
}
print "\n";
