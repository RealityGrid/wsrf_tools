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
       @INC = ( @INC, $ENV{'WSRF_LOCATION'} );
};

#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use ReG_Utils;
use strict;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV != 2 )
{
  print "  Script to retrieve a property of a WS-Resource\n\n";	
  print "Usage:\n wsrf_getResourceProperties.pl URL Property\n\n";
  print "       URL is the endpoint of the Service\n";
  print "       Property is the ResourceProperty to retrieve eg. TerminationTime, CurrentTime, count or foo\n\n";
  print "wsrf_getResourceProperties.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279  count\n";
 exit;
}


#get the location of the service
my $target = shift @ARGV;

#get the property name to retrieve
my $param = shift  @ARGV;

my $arg = "<ResourceProperty>".$param."</ResourceProperty>";
my $ans;
if( index($target, "https://") == -1){
    # Create WSSE header...
    print "Enter the passphrase for the registry: ";
    my $passphrase = <STDIN>;
    chomp($passphrase);
    print "\n";

    my $DN = ReG_Utils::getUsername();
    my $hdr = ReG_Utils::makeWSSEHeader($DN, $passphrase);

    $ans =  WSRF::Lite
        -> uri($WSRF::Constants::WSRP)
        -> wsaddress(WSRF::WS_Address->new()->Address($target))
        -> GetMultipleResourceProperties(SOAP::Header->name('wsse:Security')->value(\$hdr),
					 SOAP::Data->value($arg)->type('xml') );
}
else{
    $ans=  WSRF::Lite
	-> uri($WSRF::Constants::WSRP)
	-> wsaddress(WSRF::WS_Address->new()->Address($target))
#       -> GetResourceProperty( SOAP::Data->value($param)->type('xml') );
	-> GetMultipleResourceProperties( SOAP::Data->value($arg)->type('xml') );
}
       
die "GetMultipleResourceProperties ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n" if ($ans->fault);

my $prop_name = $param;
$prop_name =~ s/\w*://;

if(defined($ans->valueof("//$prop_name"))) {
       foreach my $item ($ans->valueof("//$prop_name")) {
     	     print "   Returned value for \"$param\" = $item\n";
       }
}
else {
  print "   No \"$prop_name\" returned\n";
}

print "\n";
