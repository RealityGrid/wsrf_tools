#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, "/home/zzcguap/projects/WSRF-Lite" );
};

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

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
$target = shift @ARGV;

#get the property name to retrieve
$param = shift  @ARGV;

$ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))
       -> GetResourceProperty( SOAP::Data->value($param)->type('xml') );             #function + args to72715254105314401250.log invoke

       
if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

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
