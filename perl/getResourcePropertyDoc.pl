#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use ReG_Utils;
use strict;

if ( @ARGV != 1 )
{
  print "  Script to retrieve the ResourceProperties document of a WS-Resource\n\n";	
  print "Usage:\n getResourcePropertyDoc.pl URL \n\n";
  print "       URL is the endpoint of the Service\n";
  print "getResourcePropertiesDoc.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279\n";
 exit;
}

$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

print "Enter passphrase for service (if any): ";
my $passphrase = <STDIN>;
chomp($passphrase);
print "\n";

my $DN = ReG_Utils::getUsername();
my $hdr = ReG_Utils::makeWSSEHeader($DN, $passphrase);

#get the location of the service
my $target = shift @ARGV;

my $ans =  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))
       -> GetResourcePropertyDocument(SOAP::Header->name('wsse:Security')->value(\$hdr));
       
if ($ans && $ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

my $serializer = WSRF::SimpleSerializer->new();
my $rpDoc = $ans->dataof("//ResourceProperties");
my $rpDocXML = $serializer->serialize($rpDoc);
print ">>".$rpDocXML."<<\n";
print "\n";
