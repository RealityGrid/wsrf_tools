#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, ".." );
};


use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV le 2 )
{
  print "  Script to update the ResourceProperties of a WS-Resource\n\n";	
  print "Usage:\n wsrf_updateResourceProperty.pl URL Property Value Value\n\n";
  print "     URL is the endpoint of the Service\n";
  print "     Property is the ResourceProperty to update\n";
  print "     Value is new value for the ResourceProperty\n\n";
  print "wsrf_updateResourceProperty.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279 foo my_value1 my_value2\n";
  exit;
}


#get the location of the service
$target = shift @ARGV;

#get the name of the thing to update
$param = shift @ARGV;

#get the new set of values
@myval = @ARGV;

$insertTerm = "<wsrp:Update>";
foreach my $item ( @myval )
{
      $insertTerm .=  "<$param>$item</$param>";
}
$insertTerm .= "</wsrp:Update>";



$ans=  WSRF::Lite
       -> wsaddress(WSRF::WS_Address->new()->Address($target))   
       -> uri($WSRF::Constants::WSRP)
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );             #function + args to invoke

       

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
if ( $ans->fault)
{
  print $ans->faultcode, " ", $ans->faultstring, "\n";
  exit;
}

   print "\n Updated Property $param ".$ans->result."\n";

print "\n";
