#! /usr/bin/env perl
# -wT

use strict;

BEGIN {
       @INC = ( @INC, $ENV{'WSRF_LOCATION'} );
};

#
# This script adds a WS-Resource to ServiceGroup - since
# the stuff that is used in the Add is so complex we hard
# code in this script rather thab try and take if of the 
# command line.
#
#use SOAP::Lite +trace =>  debug => sub {};
#use WSRF::Lite +trace =>  debug => sub {};
use SOAP::Lite;
use WSRF::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";



if ( @ARGV != 2)
{
  print "Usage: wsrf_ServiceGroupAdd.pl URL ID\n";
  print "   URL is the EndPoint of the ServiceGroup to register with";
  print "   ID is the EPR of the ServiceGroup to register\n";  
  print "eg.\n wsrf_ServiceGroupAddSG.pl http://localhost:50005/Session/myServiceGroup/myServiceGroup2345235463546 http://localhost:50005/WSRF/SWS/SWS/55292861054208023930\n";
  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;

#get the ResourceID of the ServiceGroup we are trying to an an entry to -
#this is hard coded for WSRF::Lite.
my $id = shift @ARGV;

#the Add operation belongs to this namespace
my $uri = $WSRF::Constants::WSSG;

# Get the time and date
my $time_now = time;
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time_now);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

#This is the information we are going to add to the ServiceGroup -
#we hard code it here because it is pretty complex to try and
#take off the command line. The Add operation can take three things
#in the message - the EPR of the service you want to add, some 
#content (meta-data) about the Service you are adding and optionally
#a time for how long the Service should stay registered for.
#(In this example we do not set a lifetime for the entry) 
my $StuffToAdd = '<MemberEPR>
                    <wsa:EndpointReference xmlns:wsa="$WSRF::Constants::WSA">
                      <wsa:Address>'.$id.'</wsa:Address>
		    </wsa:EndpointReference>
		  </MemberEPR>
		  <Content>
                  <registryEntry>
                    <serviceType>ServiceGroup</serviceType>
                      <componentContent>
                        <componentStartDateTime>'.$launch_time.'</componentStartDateTime>
			<componentCreatorName>/C=UK/O=eScience/OU=Manchester/L=MC/CN=andrew porter</componentCreatorName>
			<componentCreatorGroup>RSS</componentCreatorGroup>
			<componentSoftwarePackage>none</componentSoftwarePackage>
			<componentTaskDescription>Container registry</componentTaskDescription>
                      </componentContent>
                  </registryEntry>
                  </Content>';

#for simplicity we use raw xml to construct the message ;-)
my $data = SOAP::Data->value($StuffToAdd)->type('xml');


my $ans = WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> Add($data);                   #function + args to invoke


#The Add operation returns a WS-Address!! This EPR is of the ServiceGroupEntry
#that models the entry you have just created - destroy the ServiceGroupEntry
#and the entry will disappear from the ServiceGroup. You also control the lifetime
#of the entry using the ServiceGroupEntry - using SetTerminationTime on it.
if ($ans->fault) {  die "Add ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//AddResponse/EndpointReference/Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service, EndPoint = $address\n";
print "\n";
