#! /usr/bin/env perl
#
#  The RealityGrid Steering Library WSRF Tools
#
#  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
#  All rights reserved.
#
#  This software is produced by Research Computing Services, University
#  of Manchester as part of the RealityGrid project and associated
#  follow on projects, funded by the EPSRC under grants GR/R67699/01,
#  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
#  EP/F00561X/1.
#
#  LICENCE TERMS
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#    * Neither the name of The University of Manchester nor the names
#      of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written
#      permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Andrew Porter
#          Robert Haines

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use LWP::Simple;
#use SOAP::Lite +trace =>  debug => sub {};
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use SOAP::Lite;
use XML::DOM;
use strict;

if( (@ARGV == 1) || (@ARGV > 2)  )
{
  print "Usage: coupledAppLauncher.pl <EPR of parent> <no. of children>\n";
  exit;
}

my $i;
my $store_gsh_flag;
my $store_content_flag;
my $count;
my @gsh_array = ();
my @content_array = ();
my $input_file = "";

my $parentEPR = "";
my $numChildren = 1;
# Array to hold EPR's of the SWS's we create
my @children = ();

# Create parser for use in loop below
my $dom_parser = new XML::DOM::Parser;

if( @ARGV == 2 ){
    $parentEPR = $ARGV[0];
    $numChildren = $ARGV[1];
}

#----------------------------------------------------------------------
# Read handle of registry from file

my $registryEPR = "";
#if(!$parentEPR){
    open(GSH_FILE, "reg_registry_info.sh") || die("can't open datafile: $!");
    my $line_text = <GSH_FILE>;
    $line_text = <GSH_FILE>;
    close(GSH_FILE);

    my @item_arr = split(/=/, $line_text);
    $registryEPR = $item_arr[1];
#}
#print "\nRegistry GSH = $registryEPR\n";

#----------------------------------------------------------------------
# Read list of available containers

open(CONTAINER_FILE, "container_addresses.txt") || die("can't open container list: $!");
my @containers = <CONTAINER_FILE>;
close(CONTAINER_FILE);

for($i=0; $i<@{containers}; $i++){
    # Remove new-line character
    $containers[$i] =~ s/\n//og;
}

die "No containers obtained from container_addresses.txt" unless (@{containers} > 0);

print "Available containers:\n";
for($i=0; $i<@{containers}; $i++){
    print "    $i: $containers[$i]\n";
    if($containers[$i] =~ m/methuselah/){
	last;
    }
}
#ARPDBG - hardwire to use methuselah container
#$i = -1;
#my $max_container = @{containers} - 1;
#while ($i < 0 || $i > $max_container) {
#    print "Which container do you want to use (0 - $max_container): ";
#    $i = <STDIN>;
#    print "\n";
#}

# Set the location of the factory service
my $factory = $containers[$i] . "Session/SWSFactory/SWSFactory";

#----------------------------------------------------------------------
# Generate meta data 

# Get the username
my $username = $ENV{'USER'};
print "Username is: $username\n";

# Virtual Organisation of user
my $virt_org = "SVE Group";

# Get the time and date
my $time_now = time;
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time_now);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

# Run-time
#print "Max. wall-clock time of job in minutes (hit Return for none): ";
#my $run_time = <STDIN>;
## Remove new-line character
#chomp($run_time);
#print "\n";
# ARPDBG - hardwire run_time to 60 for now
my $run_time = 180;
my @childNames = ();

for(my $i=0; $i < $numChildren; $i++){

    # Type of application
    print "Enter name of app for child $i: ";
    my $app_name = <STDIN>;
    # Remove new-line character
    chomp($app_name);
    push @childNames, $app_name;
    print "\n";

    # Purpose of job
    #print "Enter purpose of job for child $i: ";
    #my $content = <STDIN>;
    ## Remove new-line character
    #chomp($content);
    #print "\n";
# ARPDBG hardwire during debugging
    my $content = "parent for coupled-model test";
    if($parentEPR){
	$content = "child for coupled-model test";
    }
#...ARPDBGEND

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

    #----------------------
    # Create SWS

    # Give the GS an initial lifetime of 24 hours - specified in minutes
    my $timeToLive = 24*60;

    #print "Enter GSH for starting checkpoint (hit Return for none): ";
    #my $chkGSH = <STDIN>;
    #print "\n";
    my $chkGSH = "";


    my $ans =  WSRF::Lite
	-> uri("http://www.sve.man.ac.uk/SWSFactory")
	-> wsaddress(WSRF::WS_Address->new()->Address($factory))
	-> createSWSResource($timeToLive, 
			     $registryEPR, 
			     SOAP::Data->value("$job_description")->type('string'),
			     $chkGSH);

    if($ans->fault){
	print "Problem in createSWSResource:\n";
	print join ',', $ans->faultcode, $ans->faultstring, 
	           $ans->faultdetail;
    }

    # Check we got a WS-Address EndPoint back
    my $address = $ans->valueof('//Body//Address') or 
	die "CREATE ERROR:: No Endpoint returned\n";
    print "\n   Created WSRF service, EndPoint = $address\n";

    # Store EPR in array
    push @children, $address;

    #-----------------------------------------------------
    # Supply input file, max. runtime & number of children

    $content = " ";

    if( length($input_file) > 0){

	open(GSH_FILE, $input_file) || die("can't open input file: $input_file");

	while (my $line_text = <GSH_FILE>) {
	    $content = $content . $line_text;
	}
	close(GSH_FILE);
    }

    my $target = $address;
    my $uri = "http://www.sve.man.ac.uk/SWS";

    # Protect input-file content by putting it in a CDATA section - we 
    # don't want the parser to attempt to parse it.  If the user has
    # specified a max. run-time of the job then configure the SGS
    # with it (is used to control life-time of the service). Allow 5 more
    # minutes than specified, just to be on the safe side.
    if(length($run_time) > 0){
	$run_time += 5;
	$content = "<wsrp:Insert><inputFileContent><![CDATA[" 
	    . $content ."]]></inputFileContent><maxRunTime>" . $run_time . 
             "</maxRunTime><numChildren>0".
             "</numChildren><parentEPR>".$parentEPR.
             "</parentEPR></wsrp:Insert>";
    }
    else{
	$content = "<wsrp:Insert><inputFileContent><![CDATA[" 
	    . $content ."]]></inputFileContent><numChildren>0".
	    "</numChildren><parentEPR>".$parentEPR.
	    "</parentEPR></wsrp:Insert>";
    }

    $ans =  WSRF::Lite
	-> uri("$uri")
	-> wsaddress(WSRF::WS_Address->new()->Address($target))
	-> SetResourceProperties( SOAP::Data->value($content)->type('xml') );

    #----------------------------
    # Add child to parent

    if( $parentEPR ){
    
	$ans =  WSRF::Lite
	    -> uri("$uri")
	    -> wsaddress(WSRF::WS_Address->new()->Address($parentEPR))
	    -> AddChild(SOAP::Data->value($target)->type('string'), 
			SOAP::Data->value($childNames[$i])->type('string'));
    }
}

if($parentEPR){
  print "\nEPR of parent = $parentEPR\n";
  for(my $i=0; $i < $numChildren; $i++){
      print "  $i: child $childNames[$i] = $children[$i]\n";
  }
} else {

  for(my $i=0; $i < $numChildren; $i++){
      print "  $i: service $childNames[$i] = $children[$i]\n";
  }
}

