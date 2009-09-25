#! /usr/bin/env perl
#
#  The RealityGrid Steering Library WSRF Tools
#
#  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
#  All rights reserved.
#
#  This software is produced by Research Computing Services, University
#  of Manchester as part of the RealityGrid project and associated
#  follow on projects, funded by the EPSRC under grants GR/R67699/01,
#  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
#  EP/F00561X/1.
#
#  LICENCE TERMS
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#    * Neither the name of The University of Manchester nor the names
#      of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written
#      permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Andrew Porter
#          Robert Haines

use strict;

BEGIN {
       @INC = ( @INC, $ENV{'WSRF_LOCATION'} );
};

# This script adds a WS-Resource to ServiceGroup - since
# the stuff that is used in the Add is so complex we hard
# code in this script rather thab try and take if of the 
# command line.

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
  print "   URL is the EndPoint of the ServiceGroup";
  print "   ID is the Resource ID of the ServiceGroup\n";  
  print "eg.\n wsrf_ServiceGroupAdd.pl http://localhost:50005/Session/myServiceGroup/myServiceGroup2345235463546 http://localhost:50005/WSRF/SWS/SWS/55292861054208023930\n";
  exit;
}

#get the location/endpoint of the service
my $target = shift @ARGV;

#get the ResourceID of the ServiceGroup we are trying to an an entry to -
#this is hard coded for WSRF::Lite.
my $id = shift @ARGV;

#the Add operation belongs to this namespace
my $uri = $WSRF::Constants::WSSG;

# operation name to be called
my $func = "Add";

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
                    <serviceType>SWS</serviceType>
                      <componentContent>
                        <componentStartDateTime>2005-05-23T11:40:28Z</componentStartDateTime>
			<componentCreatorName>andy</componentCreatorName>
			<componentCreatorGroup>sve</componentCreatorGroup>
			<componentSoftwarePackage>none</componentSoftwarePackage>
			<componentTaskDescription>test wsrf service groups</componentTaskDescription>
                      </componentContent>
                  </registryEntry>
                  </Content>';

#for simplicity we use raw xml to construct the message ;-)
my $data = SOAP::Data->value($StuffToAdd)->type('xml');


my $ans = WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> $func($data);                   #function + args to invoke


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
