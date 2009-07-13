#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{'WSRF_LOCATION'} );
};

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;
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
