#! /usr/bin/env perl
# -wT

use strict;

#
# This script adds a WS-Resource to ServiceGroup - since
# the stuff that is used in the Add is so complex we hard
# code in this script rather thab try and take if of the 
# command line.
#
use SOAP::Lite +trace =>  debug => sub {};

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";



if ( @ARGV != 2)
{
  print "Usage: wsrf_ServiceGroupAdd.pl URL ID\n";
  print "   URL is the EndPoint of the ServiceGroup";
  print "   ID is the Resource ID of the ServiceGroup\n";  
  print "eg.\n wsrf_ServiceGroupAdd.pl http://localhost:50000/Session/myServiceGroup/myServiceGroup2345235463546\n";
  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;

#get the ResourceID of the ServiceGroup we are trying to an an entry to -
#this is hard coded for WSRF::Lite.
my $id = shift @ARGV;

#the Add operation belongs to this namespace
my $uri = "http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup";

# operation name to be called
my $func = "Add";


#This is the WS-Address, it goes into the SOAP Header - note
#this is hard coded for WSRF::Lite - the <mmk...>...</mmk..>
#part will be different for different implementations of
#WSRF (why it is not a fixed format I don't know...)
my $ID = "<wsa:Action xmlns:wsa=\"http://schemas.xmlsoap.org/ws/2003/03/addressing\">".
          $uri."/".$func."Request</wsa:Action><wsa:To xmlns:wsa=\"http://schemas.xmlsoap.org/ws/2003/03/addressing\">".
	  $target."</wsa:To><mmk:ResourceID xmlns:mmk=\"http://www.sve.man.ac.uk/wsrf\">$id</mmk:ResourceID>";

#create a SOAP Header using the $ID
my $header = SOAP::Header->value($ID)->type('xml'); 

#This is the information we are going to add to the ServiceGroup -
#we hard code it here because it is pretty complex to try and
#take off the command line. The Add operation can take three things
#in the message - the EPR of the service you want to add, some 
#content (meta-data) about the Service you are adding and optionally
#a time for how long the Service should stay registered for.
#(In this example we do not set a lieftime for the entry) 
my $StuffToAdd = '<MemberEPR>
                   <wsa:EndpointReference xmlns:wsa="http://schemas.xmlsoap.org/ws/2003/03/addressing">
                   <wsa:Address>http://yaffel.mvc.mcc.ac.uk:50005/Session/myServiceGroup/myServiceGroup</wsa:Address>
		   <wsa:ReferenceProperties>
		       <wsrf:ResourceID xmlns:wsrf="http://www.sve.man.ac.uk/wsrf">275682341051142039400</wsrf:ResourceID>
		   </wsa:ReferenceProperties>
		  </wsa:EndpointReference>
		  </MemberEPR>
		  <Content>
                  <registryEntry>
                    <serviceType>ServiceGroup</serviceType>
                      <componentContent>
                        <componentStartDateTime></componentStartDateTime>
			<componentCreatorName></componentCreatorName>
			<componentCreatorGroup></componentCreatorGroup>
			<componentSoftwarePackage></componentSoftwarePackage>
			<componentTaskDescription>Registry of SWS factories</componentTaskDescription>
                      </componentContent>
                  </registryEntry>
                  </Content>';

#for simplicity we use raw xml to construct the message ;-)
my $data = SOAP::Data->value($StuffToAdd)->type('xml');


my $ans = SOAP::Lite
         -> uri($uri)
	 -> on_action( sub {sprintf '%s/%s', @_} )  #override the default SOAPAction to use a '/' instead of a '#'
	 -> proxy("$target")                        #location of service
         -> $func($header,$data);                   #function + args to invoke


#The Add operation returns a WS-Address!! This EPR is of the ServiceGroupEntry
#that models the entry you have just created - destroy the ServiceGroupEntry
#and the entry will disappear from the ServiceGroup. You also control the lifetime
#of the entry using the ServiceGroupEntry - using SetTerminationTime on it.
if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

my $resourceId ="";
#Check we got a ResourceID back
if ( $ans->dataof('//ReferenceProperties/*') )
{

  my $i=0;
  foreach my $a ($ans->dataof('//ReferenceProperties/*'))
  {
     $i++;
     my $name  = $a->name();
     my $uri   = $a->uri();
     my $value = $a->value();
     $resourceId .= "<myns$i:$name xmlns:myns$i=\"$uri\">$value</myns$i:$name>"
  }
}

print "\n   Created WSRF service:\n";
print "           Resource Identifier = $resourceId\n";
print "           EndPoint            = $address\n";


print "\n";
