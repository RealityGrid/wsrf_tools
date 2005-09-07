#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

#use SOAP::Lite +trace =>  debug => sub {};
use SOAP::Lite;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use strict;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV != 1 )
{
  print "Usage: getRegistryEntries.pl EPR\n";
  print "       EPR is the endpoint  of the ServiceGroup/Registry\n";
 exit;
}


#get the location of the service
my $target = shift @ARGV;

#get the namespace of the service - belongs to WSRP
my $uri = 'http://www.ibm.com/xmlns/stdwip/web-services/WS-ResourceProperties';

#get the property name to retrieve
my $param = "Entry";
my $func = "GetResourceProperty";

my $ans =  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
    -> $func( SOAP::Data->value($param)->type('xml') ); 

       
if ($ans->fault) {  die "GetResourceProperty ERROR:: ".
			$ans->faultcode." ".$ans->faultstring."\n"; }

if(!defined($ans->valueof("//"))) {
  print "   No \"$param\" returned\n";
  exit 1;
}

print "\n";

my $prop_name = "{http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup}Content";
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
    print "Entry $i: $type \"$content\"\n";
    if($type ne "ServiceGroup"){
	print "         User: $userNames[$i]\n";
        print "         Time: $startTimes[$i]\n";
	print "     SWS addr: $swsEPRs[$i]\n";
	print "   Entry addr: $serviceGroupEPRs[$i]\n";
    }

}

print "\n";
