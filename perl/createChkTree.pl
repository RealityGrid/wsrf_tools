#! /usr/bin/env perl
use strict;

# The Resource Identifier for the resource is returned in the
# SOAP Headers - this Resource Identifier needs to be included
# in the SOAP Headers for any other calls to use this
# ServiceGroup

use SOAP::Lite +trace =>  debug => sub {};
#use SOAP::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV < 1)
{
  print "Usage: createChkTree.pl URL <CP Data> <Input file> <Meta-data>\n";
  print "   CP Data is \n";
  print "   e.g.: createChkTree.pl \n";
  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;
my $cpData = shift @ARGV;
my $inputFile = shift @ARGV;
my $metaData = shift @ARGV;

#my $passphrase = "";
#if($target =~ m/^https/){
#    if (@ARGV != 1){
#	print "A passphrase must be specified when creating a secured registry\n";
#	exit;
#    }
#    $passphrase = shift @ARGV;
#}

my $uri = "http://www.sve.man.ac.uk/CheckPointTree";

my $ans=  SOAP::Lite
         -> uri($uri)
	 -> on_action( sub {sprintf '%s/%s', @_} ) #override the default SOAPAction to use a '/' instead of a '#'
	 -> proxy("$target")                     
         -> createNewTree($cpData, $inputFile, $metaData);

if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

#Check we that got a WS-Address EndPoint back
my $address = $ans->valueof('//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created Checkpoint Tree service:\n";
print "           EndPoint            = $address\n";
print "\n";
