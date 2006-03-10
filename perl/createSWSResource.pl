#! /usr/bin/env perl

#
# script to create a new WSRF SWS resource - makes
# a createSWSResource call to a Web Service - 
#
# The Resource Identifier for the resource is returned in the
# SOAP Headers - this Resource Identifier needs to be included
# in the SOAP Headers for any other calls to use this
# resource

BEGIN {
       @INC = ( @INC, $ENV{'WSRF_LOCATION'} );
};

foreach my $item ( @INC )
{
  print $item."\n";
}

use WSRF::Lite +trace =>  debug => sub {};
use SOAP::Packager;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";



if ( @ARGV != 2)
{
  print "Usage: createSWSResource.pl URL URI\n";
  print "   URI is the namespace for the service\n";
  print "   URL is the endpoint of the service\n";  
  print "eg\n  createSWSResource.pl http://localhost:50005/Session/SWSFactory/SWSFactory\n\t\t\t http://www.sve.man.ac.uk/SWSFactory\n";
  exit;
}

#get the location of the service
$target = shift @ARGV;
#get the namespace of the service
$uri = shift @ARGV;

# function name to be called
$func = "createSWSResource";

$ans=  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> $func();      #function + args to invoke

exit;

if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service:\n";
print "           EndPoint            = $address\n";

print "\n";
