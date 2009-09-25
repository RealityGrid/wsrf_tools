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

package ReG_Utils;

use SOAP::Lite;
use WSRF::Lite;
use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);;
use strict;

$ReG_Utils::randInitialized = 0;

#----------------------------------------------------
# Returns a SOAP::Data object containing a completed
# wsse:UsernameToken

sub makeWSSEHeader {

    my ($username, $password) = @_;

    if($ReG_Utils::randInitialized == 0){
        # seed the random number generator
        srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
        $ReG_Utils::randInitialized = 1;
    }
    my $num = rand 1000000;
    my $nonce = encode_base64("$num", "");

    # Get the time and date
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    # month returned by localtime is zero-indexed and we need to convert to
    # a four-digit date...
    my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                           $year+1900,$mon+1,$mday,$hour,$min,$sec;

    # Password digest = Base64( SHA-1(nonce + created + password) )
    my $digest = sha1_base64($nonce . $launch_time . $password);
    my $user = SOAP::Data->name('wsse:Username' => $username);
    my $passData = SOAP::Data->name('wsse:Password' => $digest);
    my $nonceData = SOAP::Data->name('wsse:Nonce' => $nonce);
    my $created = SOAP::Data->name('wsse:Created' => $launch_time);

    my $hdr1 = SOAP::Data->new(name => 'wsse:UsernameToken',
                               value => \SOAP::Data->value($user,
                                                           $passData,
                                                           $nonceData,
                                                           $created));
    return $hdr1;
}

#----------------------------------------------------

sub getUsername {

    my $DN="";
    if( open(CERT_FILE, $ENV{HTTPS_CERT_FILE}) ){
	my @lines = <CERT_FILE>;
	close(CERT_FILE);

	foreach my $line (@lines){

	    if($line =~ m/^subject=/){
		chomp($line);
		$line =~ s/^subject=//o;
		$DN = $line;
		last;
	    }
	}
    }
    else{
	$DN = $ENV{'USER'};
    }
    print "Your DN = $DN\n";
    return $DN;
}

1;

