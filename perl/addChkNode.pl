#! /usr/bin/env perl
use strict;

BEGIN{
    @INC = (@INC, $ENV{'WSRF_LOCATION'});
}

# The Resource Identifier for the resource is returned in the
# SOAP Headers - this Resource Identifier needs to be included
# in the SOAP Headers for any other calls to use this
# ServiceGroup

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV != 5)
{
  print "Usage: addChkNode.pl URL <CP Data> <Steering log> ".
      "<Input file> <Meta-data>\n";
  print "   CP Data is \n";
  print "   e.g.: addChkNode.pl \n";
  exit;
}

#get the location/endpoint of the service
my ($target, $cpData, $steerLog, $inputFile, $metaData) = @ARGV;

#my $passphrase = "";
#if($target =~ m/^https/){
#    if (@ARGV != 1){
#	print "A passphrase must be specified when creating a secured registry\n";
#	exit;
#    }
#    $passphrase = shift @ARGV;
#}

my $uri = "http://www.sve.man.ac.uk/CheckPointTreeNode";

my $ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> addNode($cpData, $steerLog, $inputFile, $metaData);

if ($ans->fault) {  die "ERROR adding node: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

#Check we that got a WS-Address EndPoint back
my $address = $ans->valueof('//Body//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n";
print "           EndPoint of new node = $address\n";
print "\n";
