#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, "/home/zzcguap/projects/WSRF-Lite" );
};

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

if ( @ARGV != 1 )
{
  print "  Script to retrieve a property of a WS-Resource\n\n";	
  print "Usage:\n getResourcePropertiesDoc.pl URL \n\n";
  print "       URL is the endpoint of the Service\n";
  print "       Property is the ResourceProperty to retrieve eg. TerminationTime, CurrentTime, count or foo\n\n";
  print "getResourcePropertiesDoc.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279\n";
 exit;
}

$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

#get the location of the service
$target = shift @ARGV;

$ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))
       -> GetResourcePropertyDocument();
       
if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

exit;

if(defined($ans->valueof("//$prop_name"))) {
       foreach my $item ($ans->valueof("//$prop_name")) {
     	     print "   Returned value for \"$param\" = $item\n";
       }
}
else {
  print "   No \"$prop_name\" returned\n";
}


print "\n";
