#! /usr/bin/env perl
# -wT

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use SOAP::Lite +trace =>  debug => sub {};
use WSRF::Lite +trace =>  debug => sub {};
use ReG_Utils;
use strict;

#
# This script adds a Container to ServiceGroup - since
# the stuff that is used in the Add is so complex we hard
# code in this script rather thab try and take if of the 
# command line.
#

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV != 3)
{
  print "Usage: wsrf_ServiceGroupAddContainer.pl <URL> <Container URL> <passphrase>\n";
  print "   URL is the EndPoint of the Registry to add to\n";
  print "   Container URL is the contact address of the service\n";  
  print "   passphrase is the password need to access the registry\n";
  print "e.g.\n wsrf_ServiceGroupAddContainer.pl http://localhost:50005/Session/regServiceGroup/regServiceGroup2345235463546 http://localhost:50005/ yellow\n";
  exit;
}

my ($target, $container, $passphrase) = @ARGV;

#the Add operation belongs to this namespace
my $uri = "http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup";

my $DN = ReG_Utils::getUsername();

# Get the time and date
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $time_now = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

#This is the information we are going to add to the ServiceGroup -
#we hard code it here because it is pretty complex to try and
#take off the command line. The Add operation can take three things
#in the message - the EPR of the service you want to add, some 
#content (meta-data) about the Service you are adding and optionally
#a time for how long the Service should stay registered for.
#(In this example we do not set a lifetime for the entry) 
 my $StuffToAdd = <<EOF;
<MemberEPR>
<wsa:EndpointReference xmlns:wsa="http://www.w3.org/2005/03/addressing">
<wsa:Address>$container</wsa:Address>
</wsa:EndpointReference>
</MemberEPR>
<Content>
<registryEntry>
<serviceType>Container</serviceType>
<componentContent>
<componentStartDateTime>$time_now</componentStartDateTime>
<componentCreatorName>$DN</componentCreatorName>
<componentCreatorGroup>RSS</componentCreatorGroup>
<componentSoftwarePackage>WSRF::Lite Container</componentSoftwarePackage>
<componentTaskDescription>Hosting environment for WS resources</componentTaskDescription>
</componentContent>
<regSecurity>
<passphrase/>
<allowedUsers>
<user>ANY</user>
</allowedUsers>
</regSecurity>
</registryEntry>
</Content>
EOF

my $hdr = ReG_Utils::makeWSSEHeader($DN, $passphrase);

my $ans = WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target))
         -> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
		SOAP::Data->value($StuffToAdd)->type('xml')); 


#The Add operation returns a WS-Address!! This EPR is of the ServiceGroupEntry
#that models the entry you have just created - destroy the ServiceGroupEntry
#and the entry will disappear from the ServiceGroup. You also control the lifetime
#of the entry using the ServiceGroupEntry - using SetTerminationTime on it.
if ($ans->fault) { 
    die "Add ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; 
}

#Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//AddResponse/EndpointReference/Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Added Container to registry, EndPoint = $address\n";
print "\n";
