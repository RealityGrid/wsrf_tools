#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use LWP::Simple;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use ReG_Utils;
use strict;

#need to point to user's certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


if( @ARGV > 1  )
{
  print "Usage: appLauncher.pl [Job input file]\n";
  exit;
}

my $input_file = "";
if( @ARGV == 1 )
{
  $input_file = $ARGV[0];
}

#----------------------------------------------------------------------
# Read handle of registry from file

open(GSH_FILE, "reg_registry_info.sh") || die("can't open datafile: $!");
# Read the details of the registry to use
my $registry_EPR = "";
my $registry_passphrase = "";
while( (my $line_text = <GSH_FILE>) ){
    chomp $line_text;
    next if( $line_text =~ m/^\#/ );
    if( index($line_text, "REG_REGISTRY_EPR") > -1){
	my @item_arr = split(/=/, $line_text);
	$registry_EPR = $item_arr[1];
    }
    elsif( index($line_text, "REG_REGISTRY_PASSPHRASE") > -1){
	my @item_arr = split(/=/, $line_text);
	$registry_passphrase = $item_arr[1];
    }
}
close(GSH_FILE);

print "\nRegistry EPR = $registry_EPR\n".
      "Registry_passphrase = $registry_passphrase\n";

#----------------------------------------------------------------------
# Read list of available containers

open(CONTAINER_FILE, "container_addresses.txt") || die("can't open container list: $!");
my $i = 0;
my @containers = <CONTAINER_FILE>;
close(CONTAINER_FILE);

for($i=0; $i<@{containers}; $i++){
    # Remove new-line character
    $containers[$i] =~ s/\n//og;
}

#---------------------------------------------------------------------
# Ask user to choose container to host the SWS

print "Available containers:\n";
for($i=0; $i<@{containers}; $i++){
    print "    $i: $containers[$i]\n";
    # ARPDBG - hardwire for now 
    #if($containers[$i] =~ m/methuselah/){
    #  last;
    #}
}
$i = -1;
my $max_container = @{containers} - 1;
while ($i < 0 || $i > $max_container) {
    print "Which container do you want to use (0 - $max_container): ";
    $i = <STDIN>;
    print "\n";
}

my $myContainer = $containers[$i];

#----------------------------------------------------------------------
# Generate meta data 

# Get the username
my $username = $ENV{'USER'};
print "Username is: $username\n";

# Virtual Organisation of user
my $virt_org = "RSS Group";

# Get the time and date
my $time_now = time;
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time_now);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

# Type of application
#print "Enter name of application: ";
#my $app_name = <STDIN>;
my $app_name = "mini_app\n";
# Remove new-line character
chomp($app_name);
print "\n";

# Purpose of job
#print "Enter purpose of job: ";
#my $content = <STDIN>;
my $content = "test wsrf work\n";
# Remove new-line character
chomp($content);
print "\n";

# Run-time
#print "Max. wall-clock time of job in minutes (hit Return for none): ";
#my $run_time = <STDIN>;
my $run_time = "120\n";
# Remove new-line character
chomp($run_time);
print "\n";

print "Enter a passphrase to protect the SWS: ";
my $passphrase = <STDIN>;
chomp($passphrase);
print "\n";


my $DN= ReG_Utils::getUsername();

my $job_description = <<EOF;
<registryEntry>
<serviceType>SWS</serviceType>
<componentContent>
<componentStartDateTime>$launch_time</componentStartDateTime>
<componentCreatorName>$username</componentCreatorName>
<componentCreatorGroup>$virt_org</componentCreatorGroup>
<componentSoftwarePackage>$app_name</componentSoftwarePackage>
<componentTaskDescription>$content</componentTaskDescription>
</componentContent>
<regSecurity>
<passphrase>$passphrase</passphrase>
<allowedUsers>
<user>$DN</user>
</allowedUsers>
</regSecurity>
</registryEntry>
EOF

print "Job description >>$job_description<<\n";

#----------------------------------------------------------------------
# Create SWS

# Give the GS an initial lifetime of 24 hours - specified in minutes
my $timeToLive = 24*60;

#print "Enter EPR for starting checkpoint (hit Return for none): ";
#my $chkEPR = <STDIN>;
#print "\n";
my $chkEPR = '\n';

# Set the location of the service
my $target = $myContainer . "Session/SWSFactory/SWSFactory";
# Set the namespace of the service
my $uri = "http://www.sve.man.ac.uk/SWSFactory";

print "Calling createSWSResource on $target...\n";

# This call returns a SOM object
my $ans =  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> createSWSResource($timeToLive, $chkEPR, $passphrase);

die "createSWSResource call did not return anything" if !defined($ans);

if ($ans->fault) {  die "createSWSResource ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

# Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//Body//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service, EndPoint = $address\n";
$target = $address;
$uri = "http://www.sve.man.ac.uk/SWS";

#---------------------------------------------------------------------
# Register this SWS

my $location = "<MemberEPR><wsa:Address>".$address."</wsa:Address></MemberEPR>\n<Content>";

$job_description = $location . $job_description . "</Content>";

print "Arg to Add call is >>$job_description<<\n";

my $locator = "";

if(index($registry_EPR, "https://") == -1){
    # Make sure we use WSSE if not using SSL
    my $hdr = ReG_Utils::makeWSSEHeader($DN, $registry_passphrase);
    $ans = WSRF::Lite
	-> uri("http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup")
	-> wsaddress(WSRF::WS_Address->new()->Address($registry_EPR))
	-> Add(SOAP::Header->name('wsse:Security')->value(\$hdr),
	       SOAP::Data->value($job_description)->type('xml'));  
}
else{
    $ans =  WSRF::Lite
	-> uri("http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup")
	-> wsaddress(WSRF::WS_Address->new()->Address($registry_EPR))
	-> Add(SOAP::Data->value($job_description)->type('xml')); 
}
	  
if ($ans->fault) {  
    warn "Failed to register SWS: ".$ans->faultcode." ".
	$ans->faultstring."\n"; 
}

#The Add operation returns a WS-Address (within a SOM object).
#This EPR is of the ServiceGroupEntry that models the entry you
#have just created - destroy the ServiceGroupEntry and the entry
#will disappear from the ServiceGroup. You also control the
#lifetime of the entry using the ServiceGroupEntry - using
#SetTerminationTime on it.

$locator = $ans->valueof('//AddResponse/EndpointReference/Address') or 
    warn "Service registration error: No Endpoint returned\n";

print "Call to Add returned:\n";
print "      serviceEntry locator = $locator\n";


#---------------------------------------------------------------------
# Supply location of ServiceGroupEntry, ServiceGroup, content of input file & 
# max. runtime

$content = " ";
if( length($input_file) > 0){

    open(GSH_FILE, $input_file) || die("can't open input file: $input_file");

    while (my $line_text = <GSH_FILE>) {
	$content = $content . $line_text;
    }
    close(GSH_FILE);
}

$content = "<wsrp:Insert><inputFileContent><![CDATA[" . $content .
    "]]></inputFileContent>";
# Protect input-file content by putting it in a CDATA section - we 
# don't want the parser to attempt to parse it.  If the user has
# specified a max. run-time of the job then configure the SGS
# with it (is used to control life-time of the service). Allow 5 more
# minutes than specified, just to be on the safe side.
if(length($run_time) > 0){
  $run_time += 5;
  $content .= "<maxRunTime>" . $run_time . "</maxRunTime>";
}
if($locator){
    $content .= "<ServiceGroupEntry>".$locator."</ServiceGroupEntry>".
	        "<registryEPR>".$registry_EPR."</registryEPR>";
}
$content .= "</wsrp:Insert>";

my $hdr = ReG_Utils::makeWSSEHeader($DN, $passphrase);

my $ans =  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> SetResourceProperties( SOAP::Header->name('wsse:Security')->value(\$hdr),
			      SOAP::Data->value( $content )->type( 'xml' ) );

if($ans && $ans->fault){
    die "SetResourceProperties ERROR:: ".$ans->faultcode." ".
	$ans->faultstring."\n"; 
}

#----------------------------------------------------------------------
# Save the GSH to file

open(GSH_FILE, "> reg_app_info.sh") || die("can't open datafile: $!");

print GSH_FILE "#!/bin/sh\n";
print GSH_FILE "export REG_SGS_ADDRESS=$target\n";
print GSH_FILE "export REG_PASSPHRASE=$passphrase\n";

close(GSH_FILE);
