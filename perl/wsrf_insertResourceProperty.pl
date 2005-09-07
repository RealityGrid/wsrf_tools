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

if ( @ARGV lt 3 )
{
  print "  Script to insert a ResourceProperty into a WS-Resource\n\n";	
  print "Usage:\n wsrf_insertResourceProperty.pl URL Property Value Value\n\n";
  print "     URL is the endpoint of the Web Service\n";
  print "     Property is the property to insert\n";
  print "     Value is value to insert for thhe Property\n\n";
  print "wsrf_updateResourceProperty.pl http://localhost:50000/MultiSession/Counter/Counter/19501981104038050279 foo my_value1 my_value2\n";
  exit;
}


#get the location of the service
$target = shift @ARGV;

#name of the property we are going to insert
$param = shift @ARGV;

#list of values to insert
@myval = @ARGV;

#now construct the insert message
$insertTerm = "<wsrp:Insert>";
foreach my $item ( @myval )
{
      $insertTerm .=  "<$param>$item</$param>";
}
$insertTerm .= "</wsrp:Insert>";



$ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );             #function + args to invoke

       

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
if ( $ans->fault)
{
  print $ans->faultcode, " ", $ans->faultstring, "\n";
  exit;
}

   print "\n Inserted Property $param ".$ans->result."\n";

print "\n";
