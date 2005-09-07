#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, "/home/zzcguap/projects/WSRF-Lite" );
};

use XML::Parser;
use LWP::Simple;
use WSRF::Lite +trace =>  debug => sub {};
use SOAP::Lite +trace =>  debug => sub {};
#use SOAP::Lite;
use XML::DOM;
use strict;

if( @ARGV != 0  )
{
  print "Usage: visLauncher.pl\n";
  exit;
}

#------------------------------------------------------------------------
# Read handle of registry from file

open(GSH_FILE, "reg_registry_info.sh") || die("can't open datafile: $!");
my $line_text = <GSH_FILE>;
$line_text = <GSH_FILE>;
close(GSH_FILE);

my @item_arr = split(/=/, $line_text);
my $registry_EPR = $item_arr[1];

print "Registry EPR = $registry_EPR\n";

#----------------------------------------------------------------------
# Read list of available containers

open(CONTAINER_FILE, "container_addresses.txt") || die("can't open container list: $!");
my @containers = <CONTAINER_FILE>;
close(CONTAINER_FILE);

for(my $i=0; $i<@{containers}; $i++){
    # Remove new-line character
    $containers[$i] =~ s/\n//og;
}

#------------------------------------------------------------------------
# Query Registry for SWSs

my $ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($registry_EPR))
       -> GetResourceProperty( SOAP::Data->value("Entry")->type('xml') ); 

if ($ans->fault) {  die "GetResourceProperty ERROR:: ".
			$ans->faultcode." ".$ans->faultstring."\n"; }

my @swsEPRs = ();
my @swsContent = ();
my $ser = WSRF::SimpleSerializer->new();

if(defined($ans->valueof("//Entry/MemberServiceEPR/EndpointReference/Address"))) {

    for my $item ($ans->valueof("//Entry")) {

	push @swsEPRs, $item->{MemberServiceEPR}->{EndpointReference}->{Address};
	my $content = $item->{Content}->{registryEntry};
	my $content_xml = $ser->serialize($content);
	push @swsContent, $content_xml;
       }
}
else {
  print "   No Entries returned\n";
  exit;
}

my $app_SWS_EPR = "NOT_SET";
my $count = @{swsEPRs};
print "\nGot $count entries from registry:";
for(my $i=0; $i<$count; $i++){
    print "\n  $i: EPR = $swsEPRs[$i]\n     Content = $swsContent[$i]";
}

$count--;
print "\nWhich app. to use as data source (0 - $count): ";
my $i = <STDIN>;
print "\n";
$app_SWS_EPR = $swsEPRs[$i];

die "No application SWS found" unless ($app_SWS_EPR ne "NOT_SET");

#-------------------------------------------------------------------------
# Query App. SWS for IOType definitions

$ans=  WSRF::Lite
       -> uri($WSRF::Constants::WSRP)
       -> wsaddress(WSRF::WS_Address->new()->Address($app_SWS_EPR))
       -> GetResourceProperty( SOAP::Data->value("ioTypeDefinitions")->type('xml') ); 

if ($ans->fault) {  die "GetResourceProperty ERROR:: ".
			$ans->faultcode." ".$ans->faultstring."\n"; }

my @ioTypeLabels = ();
my @ioTypeAddresses= ();
my $source_label = "";

if(defined($ans->valueof("//ioTypeDefinitions"))) {

    for my $item ($ans->valueof("//IOType")) {

	if($item->{Direction} eq "OUT"){
	    print "Label = ".$item->{Label}."\n";
	    print "Address = ".$item->{Address}."\n";
	    push @ioTypeLabels, $item->{Label};
	    push @ioTypeAddresses, $item->{Address};
	}
    }
}
else {
  print "   No IOType definitions returned\n";
  exit;
}

$count = @{ioTypeLabels};

die "Failed to find a valid data source\n" unless ($count > 0);

if ($count > 0) {

    print "Available IO channels are:\n";
    for($i=0; $i<$count; $i++){
	print "  Source $i: $ioTypeLabels[$i]\n";
    }
    $count--;
    $i = -1;
    while ($i < 0 || $i > $count) {
	print "Which channel to use as input (0 - $count): ";
	$i = <STDIN>;
    }
    $source_label = $ioTypeLabels[$i];
}

#---------------------------------------------------------------------
# Ask user to choose container to host the SWS

print "Available containers:\n";
for($i=0; $i<@{containers}; $i++){
    print "    $i: $containers[$i]\n";
    # ARPDBG - hardwire for now
    if($containers[$i] =~ m/methuselah/){
      last;
    }
}
#$i = -1;
#my $max_container = @{containers} - 1;
#while ($i < 0 || $i > $max_container) {
#    print "Which container do you want to use (0 - $max_container): ";
#    $i = <STDIN>;
#    print "\n";
#}

my $myContainer = $containers[$i];

#-------------------------------------------------------------------------
# Create SWS for vis.

# Get the username
my $username = $ENV{'USER'};

# Virtual Organisation of user
my $virt_org = "SVE Group";

# Get the time and date
my $time_now = time;
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
						gmtime($time_now);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

# Type of application
print "Enter name of application: ";
my $app_name = <STDIN>;
# Remove new-line character
chomp($app_name);
print "\n";

# Purpose of job
print "Enter purpose of job: ";
my $purpose = <STDIN>;
# Remove new-line character
chomp($purpose);
print "\n";

# Run-time
print "Max. wall-clock time of job in minutes (hit Return for none): ";
my $run_time = <STDIN>;
# Remove new-line character
chomp($run_time);
print "\n";

my $content =  <<EOF;
<registryEntry>
<serviceType>SWS</serviceType>
<componentContent>
<componentStartDateTime>$launch_time</componentStartDateTime>
<componentCreatorName>$username</componentCreatorName>
<componentCreatorGroup>$virt_org</componentCreatorGroup>
<componentSoftwarePackage>$app_name</componentSoftwarePackage>
<componentTaskDescription>$purpose</componentTaskDescription>
</componentContent>
</registryEntry>
EOF

# Give the GS an initial lifetime of 24 hours - specified in minutes
my $timeToLive = 24*60;
# Set the location of the service
my $target = $myContainer . "Session/SWSFactory/SWSFactory";
# Set the namespace of the service
my $uri = "http://www.sve.man.ac.uk/SWSFactory";

# This call returns a SOM object
my $ans =  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> createSWSResource($timeToLive, $registry_EPR, 
			      SOAP::Data->value($content)->type('string'));

if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".
                        $ans->faultstring."\n"; }

# Check we got a WS-Address EndPoint back
my $vis_SWS_EPR = $ans->valueof('//Body//Address') or
    die "CREATE ERROR:: No Endpoint returned\n";

#-------------------------------------------------------------------------
# Set-up Vis. SWS with data sources & max. run time

my $dataSources = "<dataSource>
<sourceEPR>" . $app_SWS_EPR . "</sourceEPR>
<sourceLabel>" . $source_label . "</sourceLabel>
</dataSource>";

# If the user has specified a max. run-time of the job then
# configure the SWS with it (is used to control life-time of
# the service). Allow 5 more minutes than specified, just to 
# be on the safe side.
my $arg = "";
if(length($run_time) > 0){
  $run_time += 5;
  $arg = "<wsrp:Insert>".$dataSources.
         "<maxRunTime>".$run_time.
         "</maxRunTime></wsrp:Insert>";
}
else{
  $arg = "<wsrp:Insert>".$dataSources.
         "</wsrp:Insert>";
}

my $ans =  WSRF::Lite
    -> uri($WSRF::Constants::WSRP)
    -> wsaddress(WSRF::WS_Address->new()->Address($vis_SWS_EPR))
    -> SetResourceProperties( SOAP::Data->value( $arg )->type( 'xml' ) );

if($ans->fault){ die "SetResourceProperties ERROR:: ".$ans->faultcode." ".
		     $ans->faultstring."\n"; }

print "\nEPR of Vis SWS = $vis_SWS_EPR\n";

#-------------------------------------------------------------------------
# Save info to file

my $file = "reg_viz_info.sh";

open(GSH_FILE, "> $file") || die("can't open datafile: $!");
print GSH_FILE "#!/bin/sh\n";
print GSH_FILE "export REG_SGS_ADDRESS=$vis_SWS_EPR\n";
close(GSH_FILE);

#--------------------------------------------------
