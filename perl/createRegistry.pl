#! /usr/bin/env perl
# -wT
use strict;
#
# script to creates a new ServiceGroup in WSRF::Lite - note
# since WS-ServiceGroup does not define an operation to
# create a new ServiceGroup this only works with the sample
# ServiceGroup service provided with WSRF::Lite though
# it provides a pretty good template 
#
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



if ( @ARGV != 1)
{
  print "Usage: createRegistry.pl URL\n";
  print "   URL is the endpoint of the service\n";
  print "   e.g.: createRegistry.pl http://localhost:50000/Session/regServiceGroup/regServiceGroup\n";

  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;

#get the namespace of the service - this is hard coded for the
#ServiceGroup sample service distributed with WSRF::Lite
my $uri = "http://www.sve.man.ac.uk/regServiceGroup";

#This is the operation to invoke - again it is hard coded
#for the sample ServiceGroup distributed with WSRF::Lite
my $func = "createServiceGroup";


my $ans=  SOAP::Lite
         -> uri($uri)
	 -> on_action( sub {sprintf '%s/%s', @_} )       #override the default SOAPAction to use a '/' instead of a '#'
	 -> proxy("$target")                             #location of service
         -> $func();                                     #function + args to invoke


if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service:\n";
print "           EndPoint            = $address\n";
print "\n";

#----------------------------------------------------------------------
# Save the registry EPR

open(EPR_FILE, "> reg_registry_info.sh") || die("can't open datafile: $!");

print EPR_FILE "#!/bin/sh\n";
print EPR_FILE "export REG_REGISTRY_EPR=$address\n";

close(EPR_FILE);
