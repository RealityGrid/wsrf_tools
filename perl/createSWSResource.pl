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

use WSRF::Lite;
#use WSRF::Lite +trace =>  debug => sub {};
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
