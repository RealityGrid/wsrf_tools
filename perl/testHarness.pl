#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use WSRF::Lite +trace =>  debug => sub {};
#use WSRF::Lite;
#use XML::DOM;
use strict;

if( @ARGV > 2  || @ARGV == 0 )
{
  print "Usage: testHarness.pl <container address> [Job input file]\n";
  exit;
}

my $myContainer = $ARGV[0];

my $input_file = "";
if( @ARGV == 2 )
{
  $input_file = $ARGV[1];
}

#----------------------------------------------------------------------
# Read handle of registry from file

open(GSH_FILE, "reg_registry_info.sh") || die("can't open datafile: $!");
# Read two lines and then get the text after the '=' character
my $line_text = <GSH_FILE>;
$line_text = <GSH_FILE>;
close(GSH_FILE);

my @item_arr = split(/=/, $line_text);
my $registry_EPR = $item_arr[1];

print "\nRegistry EPR = $registry_EPR\n";

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
my $app_name = "fake";
# Remove new-line character
#chomp($app_name);
#print "\n";

# Purpose of job
#print "Enter purpose of job: ";
#my $content = <STDIN>;
my $content = "wsrf testing";
# Remove new-line character
#chomp($content);
#print "\n";

# Run-time
#print "Max. wall-clock time of job in minutes (hit Return for none): ";
#my $run_time = <STDIN>;
my $run_time = 30;
# Remove new-line character
#chomp($run_time);
#print "\n";

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
</registryEntry>
EOF

print $job_description;

#----------------------------------------------------------------------
# Create SWS

# Give the GS an initial lifetime of 24 hours - specified in minutes
my $timeToLive = 24*60;

#print "Enter EPR for starting checkpoint (hit Return for none): ";
#my $chkEPR = <STDIN>;
my $chkEPR = "";
#print "\n";

# Set the location of the service
my $target = $myContainer . "Session/SWSFactory/SWSFactory";
# Set the namespace of the service
my $uri = "http://www.sve.man.ac.uk/SWSFactory";

# Name of function to be called
my $func = "createSWSResource";

# This call returns a SOM object
my $ans =  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> $func($timeToLive, $registry_EPR, 
		  SOAP::Data->value( $job_description )->type( 'string' ), 
		  $chkEPR);

if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

# Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//createSWSResourceResponse/EndpointReference/Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service, EndPoint = $address\n";
my $SWSAddress = $address;

$target = $SWSAddress;
$uri = "http://www.sve.man.ac.uk/SWS";

#----------------------------------------------------------------------
# Get the complete RP document, just 'cos we can

$ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> GetResourcePropertyDocument();
 
if ($ans->fault) {  die "GetResourcePropertyDocument ERROR:: ".
			$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "RP document >>".$ans->result,"<<\n";

#------------------------------------------------------------
# Now set a resource property value
my $param = "supportedCommands";
my @myval = ("<ReG_steer_message><Supported_commands><Command><Cmd_id>1</Cmd_id></Command></Supported_commands></ReG_steer_message>");

# construct the insert message
my $insertTerm = "<wsrp:Insert>";
foreach my $item ( @myval )
{
      $insertTerm .=  "<$param>$item</$param>";
}
$insertTerm .= "</wsrp:Insert>";

$ans =  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );

# check what we got back from the service
if ( $ans->fault)
{
  print $ans->faultcode, " ", $ans->faultstring, "\n";
  exit;
}
print "\n Inserted Property $param ".$ans->result."\n\n";

#----------------------------------------------------------------------
# Now try and get the value that we've just set

$ans=  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))
       -> GetResourceProperty( SOAP::Data->value($param)->type('xml') );

       
if ($ans->fault) {  die "GetResourceProperty ERROR:: ".$ans->faultcode.
			" ".$ans->faultstring."\n"; }

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

#----------------------------------------------------------------------
# Now call PutStatus

my $statusMsg = <<EOF;
<ReG_steer_message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.realitygrid.org/xml/steering"
       xsi:SchemaLocation="http://www.realitygrid.org/xml/steering /home/zzcguap/projects/wsrf_steering/reg_steer_lib/xml_schema/reg_steer_comm.xsd">
<App_status>
<Param>
<Handle>-100</Handle>
<Value>6</Value>
</Param>
<Param>
<Handle>-99</Handle>
<Value>0.000</Value>
</Param>
<Param>
<Handle>-98</Handle>
<Value></Value>
</Param>
<Param>
<Handle>-97</Handle>
<Value>1</Value>
</Param>
<Param>
<Handle>0</Handle>
<Value>55.59999847412109375</Value>
</Param>
</App_status>
</ReG_steer_message>
EOF

$insertTerm = "<wsrp:Insert><statusMsg>".$statusMsg."</statusMsg></wsrp:Insert>";
$ans =  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );
       
if ($ans->fault) {  die "SetResourceProperties ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "SetResourceProperties for statusMsg returned: ".$ans->result."\n";

# Done
finishNow($address);

#----------------------------------------------------------------------
# Now call PutStatus a second time

$statusMsg = <<EOF;
<ReG_steer_message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.realitygrid.org/xml/steering"
       xsi:SchemaLocation="http://www.realitygrid.org/xml/steering /home/zzcguap/projects/wsrf_steering/reg_steer_lib/xml_schema/reg_steer_comm.xsd">
<App_status>
<Param>
<Handle>-100</Handle>
<Value>7</Value>
</Param>
<Param>
<Handle>-99</Handle>
<Value>0.000</Value>
</Param>
<Param>
<Handle>-98</Handle>
<Value></Value>
</Param>
<Param>
<Handle>-97</Handle>
<Value>1</Value>
</Param>
<Param>
<Handle>0</Handle>
<Value>56.00000847412109375</Value>
</Param>
</App_status>
</ReG_steer_message>
EOF

$insertTerm = "<wsrp:Insert><statusMsg>".$statusMsg."</statusMsg></wsrp:Insert>";
$ans =  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );
       
if ($ans->fault) {  die "SetResourceProperties for statusMsg ERROR:: ".
			$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "SetResourceProperties for statusMsg returned: ".$ans->result."\n";

#----------------------------------------------------------------------
# Now call GetLatestStatus

$ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> GetResourceProperty( SOAP::Data->value("latestStatusMsg")->type('xml') );
       
if ($ans->fault) {  die "GetResourceProperty ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "GetResourceProperty for latestStatusMsg returned:\n";

for my $t ($ans->valueof('//Param')) {
    print "  Handle: ".$t->{Handle}."\n";
    print "  Value: ".$t->{Value}."\n";
}
print "\n";

#----------------------------------------------------------------------
# Now call GetStatus
 
$ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> GetResourceProperty( SOAP::Data->value("statusMsg")->type('xml') );
       
if ($ans->fault) {  die "GetResourceProperty for statusMsg ERROR:: ".
			$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "GetResourceProperty for statusMsg returned:\n";

for my $t ($ans->valueof('//Param')) {
    print "  Handle: ".$t->{Handle}."\n";
    print "  Value: ".$t->{Value}."\n";
}
print "\n";

#----------------------------------------------------------------------
# Now set up supported commands
 
my $suppCmdsMsg = <<EOF;
<ReG_steer_message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.realitygrid.org/xml/steering"
       xsi:SchemaLocation="http://www.realitygrid.org/xml/steering /home/zzcguap/projects/ste
er_test/reg_steer_lib/xml_schema/reg_steer_comm.xsd">
<Supported_commands>
<Command>
<Cmd_id>1</Cmd_id>
</Command>
<Command>
<Cmd_id>2</Cmd_id>
</Command>
<Command><Cmd_id>5</Cmd_id></Command>
<Command><Cmd_id>4</Cmd_id></Command>
<Command><Cmd_id>3</Cmd_id></Command>
</Supported_commands>
</ReG_steer_message>
EOF

$insertTerm = "<wsrp:Insert><supportedCommands>".$suppCmdsMsg.
              "</supportedCommands></wsrp:Insert>";
$ans =  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );
        
if ($ans->fault) {  die "SetResourceProperties ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

# Check to see whether we can get this out again

$ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> GetResourceProperty( SOAP::Data->value("supportedCommands")->type('xml') );
       
if ($ans->fault) {  die "GetResourceProperty ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "GetResourceProperty for supportedCommands returned:\n";

for my $t ($ans->valueof('//Command')) {
    print "  Cmd id: ".$t->{Cmd_id}."\n";
}
print "\n";

#----------------------------------------------------------------------
# Send a control message

 
my $controlMsg = <<EOF;
<ReG_steer_message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.realitygrid.org/xml/steering"
       xsi:SchemaLocation="http://www.realitygrid.org/xml/steering /home/zzcguap/projects/ste
er_test/reg_steer_lib/xml_schema/reg_steer_comm.xsd">
<Steer_control>
<Command>
  <Cmd_id>1</Cmd_id>
</Command>
</Steer_control>
</ReG_steer_message>
EOF

$insertTerm = "<wsrp:Insert><controlMsg>".$controlMsg.
              "</controlMsg></wsrp:Insert>";
$ans =  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))  
       -> SetResourceProperties( SOAP::Data->value( $insertTerm )->type( 'xml' ) );
        
if ($ans->fault) {  die "SetResourceProperties controlMsg ERROR:: ".
			$ans->faultcode." ".
			$ans->faultstring."\n"; }

#----------------------------------------------------------------------
# Get the complete RP document, just 'cos we can

$ans=  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> GetResourcePropertyDocument();
 
if ($ans->fault) {  die "GetResourcePropertyDocument ERROR:: ".
			$ans->faultcode." ".
			$ans->faultstring."\n"; }

print "RP document >>".$ans->result,"<<\n";

#----------------------------------------------------------------------
# Now call Destroy
exit 0;
$ans=  WSRF::Lite
       -> uri($uri)
       -> wsaddress(WSRF::WS_Address->new()->Address($target))
       -> Destroy(); 

# check what we got back from the service - if it is a
# simple variable print it elsif it is a Reference to
# an ARRAY iterate through it and print the values
if ( $ans->fault)
{
  print $ans->faultcode, " ", $ans->faultstring, "\n";
}
else
{
   print "\nResult= ".$ans->result." Resource Destroyed\n";
}

#----------------------------------------------------------------------

sub finishNow {
    my $address = pop @_;
    print "\n   Created WSRF service, EndPoint = $address\n";
    exit;
}
