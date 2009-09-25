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

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

#use SOAP::Lite +trace =>  debug => sub {};
use SOAP::Lite;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use ReG_Utils;
use strict;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV < 1 || @ARGV > 2 )
{
  print "Usage: getRegistryEntries.pl EPR [registry passphrase]\n";
  print "       EPR is the endpoint  of the ServiceGroup/Registry\n";
 exit;
}

my $DN= ReG_Utils::getUsername();

# get the location of the service
my $target = shift @ARGV;
my $passwd = shift @ARGV;

# set the namespace of the service - belongs to WSRP
my $uri = $WSRF::Constants::WSRP;

# set the property name to retrieve
my $param = "Entry";
my $func = "GetResourceProperty";
my $ans;

if(defined $passwd){
    # Create WSSE header...
    my $hdr = ReG_Utils::makeWSSEHeader($DN, $passwd);

    $ans =  WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($target))
	-> $func(SOAP::Header->name('wsse:Security')->value(\$hdr),
		 SOAP::Data->value($param)->type('xml') ); 
}
else{
    $ans =  WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($target))
	-> $func(SOAP::Data->value($param)->type('xml') ); 
}

if ($ans->fault) {  die "GetResourceProperty ERROR:: ".
			$ans->faultcode." ".$ans->faultstring."\n"; }

if(!defined($ans->valueof("//"))) {
  print "   No \"$param\" returned\n";
  exit 1;
}

print "\n";

my $prop_name = "{$WSRF::Constants::WSSG}Content";
my @serviceTypes = ();
my @entryContent = ();
my @userNames = ();
my @startTimes = ();
my @serviceGroupEPRs = ();
my @swsEPRs = ();

#ServiceGroupEPR
#EndpointReference
#Address
for my $t ($ans->valueof("//ServiceGroupEntryEPR/EndpointReference/Address")){
    push @serviceGroupEPRs, $t;
}

for my $t ($ans->valueof("//MemberServiceEPR/EndpointReference/Address")){
    push @swsEPRs, $t;
}

for my $t ($ans->valueof("//".$prop_name."/registryEntry")) {
    #print $t->{serviceType}."\n";
    push @serviceTypes, $t->{serviceType};
}

for my $t ($ans->valueof("//".$prop_name."/registryEntry/componentContent")) {
    #print $t->{componentTaskDescription}."\n";
    push @entryContent, $t->{componentTaskDescription};
    push @userNames, $t->{componentCreatorName};
    push @startTimes, $t->{componentStartDateTime};
}

for (my $i=0; $i < @{entryContent}; $i++){
    my $type = $serviceTypes[$i]; 
    my $content = $entryContent[$i];
    print "\nEntry $i: $type \"$content\"\n";
    if($type eq "SWS"){
	print "         User: $userNames[$i]\n";
        print "         Time: $startTimes[$i]\n";
	print "     SWS addr: $swsEPRs[$i]\n";
    }
    elsif($type eq "ServiceGroup"){
	print "Registry addr: $swsEPRs[$i]\n";
    }
    elsif($type eq "SWSFactory"){
        print " Factory addr: $swsEPRs[$i]\n";
    }
    elsif($type eq "Container"){
        print "      Address: $swsEPRs[$i]\n";
    }
    print "   Entry addr: $serviceGroupEPRs[$i]\n";
}

print "\n";
