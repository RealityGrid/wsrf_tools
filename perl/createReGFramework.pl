#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use strict;
#use SOAP::Lite +trace =>  debug => sub {};
use SOAP::Lite;
#use WSRF::Lite +trace => debug => sub{};
use WSRF::Lite;
use ReG_Utils;

#------------------------------------------------------------
sub createEntryData {

    my ($addr, $now, $DN, $group, $serviceType, $soft, $descr, $passwd) = @_;

    my $StuffToAdd = <<EOF;
<MemberEPR>
<wsa:EndpointReference xmlns:wsa="http://www.w3.org/2005/03/addressing">
<wsa:Address>$addr</wsa:Address>
</wsa:EndpointReference>
</MemberEPR>
<Content>
<registryEntry>
<serviceType>$serviceType</serviceType>
<componentContent>
<componentStartDateTime>$now</componentStartDateTime>
<componentCreatorName>$DN</componentCreatorName>
<componentCreatorGroup>$group</componentCreatorGroup>
<componentSoftwarePackage>$soft</componentSoftwarePackage>
<componentTaskDescription>$descr</componentTaskDescription>
</componentContent>
<regSecurity>
<passphrase>$passwd</passphrase>
<allowedUsers>
<user>ANY</user>
</allowedUsers>
</regSecurity>
</registryEntry>
</Content>
EOF

    return $StuffToAdd;
}

#------------------------------------------------------------

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";

if ( @ARGV < 1 || @ARGV > 2)
{
  print "Usage: createReGFramework.pl <Container for registries> [passphrase]\n";
  print "   passphrase is used to authentic the web-based registry browser if using security\n";
  print "   e.g.: createReGFramework.pl http://localhost:50000/ roygbiv\n";
  exit;
}
my $topContainer = $ARGV[0];
my $containerPassphrase = "";

if(@ARGV == 2){
    $containerPassphrase = $ARGV[1];
}

#---------------------------------------------------------
#Create registry for containers and registry for ioProxies
$topContainer =~ s/\/$//o;
my $target = $topContainer."/Session/regServiceGroup/regServiceGroup";
my $uri = "http://www.sve.man.ac.uk/regServiceGroup";

my $ans =  SOAP::Lite
         -> uri($uri)
         -> on_action( sub {sprintf '%s/%s', @_} ) #override the default SOAPAction to use a '/' instead of a '#'
         -> proxy("$target")                       #location of service
         -> createServiceGroup($containerPassphrase);

if ($ans->fault) {  
    die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring.
	" ".$ans->faultdetail."\n"; 
}

#Check we that got a WS-Address EndPoint back
my $containerRegistryAddress = $ans->valueof('//Address') or
       die "CREATE ERROR:: No Endpoint returned for container registry\n";

$ans =  SOAP::Lite
         -> uri($uri)
         -> on_action( sub {sprintf '%s/%s', @_} ) #override the default SOAPAction to use a '/' instead of a '#'
         -> proxy("$target")                       #location of service
         -> createServiceGroup($containerPassphrase);

if ($ans->fault) {  
    die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring.
	" ".$ans->faultdetail."\n"; 
}

#Check we that got a WS-Address EndPoint back
my $ioProxyRegistryAddress = $ans->valueof('//Address') or
       die "CREATE ERROR:: No Endpoint returned for ioProxy registry\n";

print "EndPoint of container registry = $containerRegistryAddress\n";
print "EndPoint of  ioProxy  registry = $ioProxyRegistryAddress\n";
print "\n";

#------------------------------------
#Add containers to container registry

#the Add operation belongs to this namespace
$uri = "http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup";

# Get the time and date
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $time_now = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

my $DN = $ENV{USER};
if(defined $ENV{HTTPS_CERT_FILE} && open(CERT_FILE, $ENV{HTTPS_CERT_FILE})){
    my @lines = <CERT_FILE>;
    close(CERT_FILE);
    $DN="";
    foreach my $line (@lines){

	if($line =~ m/^subject=/){
	    chomp($line);
	    $line =~ s/^subject=//o;
	    $DN = $line;
	    last;
	}
    }
    print "Your DN = $DN\n";
}

# Read in the lists of containers and ioProxies to register
open(CONTAINER_FILE, "container_addresses.txt") || die("can't open container list: $!");
my @containers = <CONTAINER_FILE>;
close(CONTAINER_FILE);

open(IOPROXY_FILE, "ioproxy_addresses.txt") || die("can't open ioProxy list: $!");
my @proxies = <IOPROXY_FILE>;
close(IOPROXY_FILE);

foreach my $container (@containers){
    chomp($container);

    my $StuffToAdd = createEntryData($container, $time_now, $DN,
                                     "RSS", "Container",
				     "WSRF::Lite Container",
				     "Hosting environment for WS resources", 
				     $containerPassphrase);

    if(index($containerRegistryAddress, "https://") == -1){
	# Make sure we use WSSE if not using SSL
	my $hdr = ReG_Utils::makeWSSEHeader($DN, $containerPassphrase);
	$ans = WSRF::Lite
	    -> uri($uri)
	    -> wsaddress(WSRF::WS_Address->new()->Address($containerRegistryAddress))
	    -> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
		   SOAP::Data->value($StuffToAdd)->type('xml'));  
    }
    else{
	$ans = WSRF::Lite
	    -> uri($uri)
	    -> wsaddress(WSRF::WS_Address->new()->Address($containerRegistryAddress))
	    -> Add(SOAP::Data->value($StuffToAdd)->type('xml'));  
    }

    #Check we got a WS-Address EndPoint back
    die "Add ERROR:: No Endpoint returned\n" unless ($ans->match('//AddResponse/EndpointReference/Address'));
    
} # End of loop over containers

foreach my $proxy (@proxies){
    chomp($proxy);

    my $StuffToAdd = createEntryData($proxy, $time_now, $DN, "RSS",
				     "ioProxy", "ReG ioProxy",
				     "Proxy for mediating socket connections", 
				     $containerPassphrase);

    if(index($ioProxyRegistryAddress, "https://") == -1){
	# Make sure we use WSSE if not using SSL
	my $hdr = ReG_Utils::makeWSSEHeader($DN, $containerPassphrase);
	$ans = WSRF::Lite
	    -> uri($uri)
	    -> wsaddress(WSRF::WS_Address->new()->Address($ioProxyRegistryAddress))
	    -> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
		   SOAP::Data->value($StuffToAdd)->type('xml'));  
    }
    else{
	$ans = WSRF::Lite
	    -> uri($uri)
	    -> wsaddress(WSRF::WS_Address->new()->Address($ioProxyRegistryAddress))
	    -> Add(SOAP::Data->value($StuffToAdd)->type('xml'));  
    }

    #Check we got a WS-Address EndPoint back
    die "Add ERROR:: No Endpoint returned\n" unless ($ans->match('//AddResponse/EndpointReference/Address'));

} # End of loop over ioProxies

#------------------------------------
#Create top-level registry
$target = $topContainer."/Session/regServiceGroup/regServiceGroup";
$uri = "http://www.sve.man.ac.uk/regServiceGroup";

$ans=  SOAP::Lite
         -> uri($uri)
         -> on_action( sub {sprintf '%s/%s', @_} ) #override the default SOAPAction to use a '/' instead of a '#'
         -> proxy("$target")                       #location of service
         -> createServiceGroup($containerPassphrase);

if ($ans->fault) {  
    die "Failed to create top-level registry: ERROR: ".
	$ans->faultcode." ".$ans->faultstring."\n"; 
}

#Check we that got a WS-Address EndPoint back
my $topLevelRegistryAddress = $ans->valueof('//Address') or
       die "CREATE ERROR:: No Endpoint returned for top-level registry\n";

print "EndPoint of top-level registry = $topLevelRegistryAddress\n";
print "\n";

#------------------------------------
#Register container registry with top-level registry

my $StuffToAdd = createEntryData($containerRegistryAddress, $time_now, 
				 $DN, "RSS",
				 "ServiceGroup", "none",
				 "Container registry", 
				 $containerPassphrase);

if(index($topLevelRegistryAddress, "https://") == -1){
    # Make sure we use WSSE if not using SSL
    my $hdr = ReG_Utils::makeWSSEHeader($DN, $containerPassphrase);
    $ans = WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($topLevelRegistryAddress))
	-> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
	       SOAP::Data->value($StuffToAdd)->type('xml'));  
}
else{
    $ans = WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($topLevelRegistryAddress))
	-> Add(SOAP::Data->value($StuffToAdd)->type('xml'));  
}

#Check we got a WS-Address EndPoint back
die "Add ERROR:: No Endpoint returned\n" unless ($ans->match('//AddResponse/EndpointReference/Address'));

#------------------------------------
#Register ioProxy registry with top-level registry

my $StuffToAdd = createEntryData($ioProxyRegistryAddress, $time_now, 
				 $DN, "RSS",
				 "ServiceGroup", "none",
				 "ioProxy registry", 
				 $containerPassphrase);

if(index($topLevelRegistryAddress, "https://") == -1){
    # Make sure we use WSSE if not using SSL
    my $hdr = ReG_Utils::makeWSSEHeader($DN, $containerPassphrase);
    $ans = WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($topLevelRegistryAddress))
	-> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
	       SOAP::Data->value($StuffToAdd)->type('xml'));  
}
else{
    $ans = WSRF::Lite
	-> uri($uri)
	-> wsaddress(WSRF::WS_Address->new()->Address($topLevelRegistryAddress))
	-> Add(SOAP::Data->value($StuffToAdd)->type('xml'));  
}

#Check we got a WS-Address EndPoint back
die "Add ERROR:: No Endpoint returned\n" unless ($ans->match('//AddResponse/EndpointReference/Address'));

#-----------------------------------
# Save the registry EPR

open(EPR_FILE, "> reg_registry_info.sh") || die("can't open datafile: $!");

print EPR_FILE "#!/bin/sh\n";
print EPR_FILE "export REG_REGISTRY_EPR=$topLevelRegistryAddress\n";
print EPR_FILE "export REG_REGISTRY_PASSPHRASE=$containerPassphrase\n";

close(EPR_FILE);

#------------------------------------
print "All done... :-)\n";
