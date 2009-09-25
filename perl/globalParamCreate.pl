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
use SOAP::Lite;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use XML::DOM;
use strict;

if( @ARGV != 1 ){
  print "Usage: globalParamCreate.pl <EPR of parent>\n";
  exit;
}

my $parentEPR = $ARGV[0];
my $content = "paramDefinitions";
my %child_params = ();
my @childEPRList = ();
my $parser = new XML::DOM::Parser;
my $serializer = WSRF::SimpleSerializer->new();

# Get parameter definitions from parent and parse
my $ans = WSRF::Lite
    -> uri("SWS")       #set the namespace
    -> wsaddress(WSRF::WS_Address->new()->Address($parentEPR)) 
    -> GetResourceProperty(SOAP::Data->value("$content")->type('xml'));

if($ans->fault){
    die "GetResourceProperty ERROR:: ".$ans->faultcode." ".
	$ans->faultstring."\n";
}

my $data = $ans->dataof('//paramDefinitions');
my $param_xml = $serializer->serialize($data);

if (!$param_xml){
    print "Got no parameter definitions from parent\n";
    exit;
}
my $param_doc = $parser->parse($param_xml);

# Now get details of parent's children
$ans =  WSRF::Lite
    -> uri("SWS")       #set the namespace
    -> wsaddress(WSRF::WS_Address->new()->Address($parentEPR)) 
    -> GetResourceProperty(SOAP::Data->value("childService")->type('xml'));

if($ans->fault){
    die "GetResourceProperty for childService ERROR:: ".$ans->faultcode." ".
	$ans->faultstring."\n";
}

die "No children found :-(\n" if (!$ans->match('//childService'));

@childEPRList = $ans->valueof('//childService');
foreach my $dataElem (@childEPRList){
    print "Child: ".$dataElem."\n";
}

# Loop over each child
foreach my $childEPR (@childEPRList){

    print "EPR: $childEPR\n";

    my @bits = split("/", $childEPR);
    my $childID = pop @bits;

    # Get the name of the application making up this component
    $ans =  WSRF::Lite
	-> uri("SWS")      #set the namespace
	-> wsaddress(WSRF::WS_Address->new()->Address($childEPR)) 
	-> GetResourceProperty(SOAP::Data->value("applicationName")->type('xml'));
    die "Got no application name from child $childEPR\n" if !$ans->match('//applicationName');
    my $name = $ans->valueof();
    print "Application name = $name\n";

    # Create a file with name constructed from application name
    my $file_name = $name;
    $file_name =~ s/ /_/og;
    $file_name .= "_metadata.xml";
    open(PARAM_FILE, "> $file_name") || die("can't open datafile: $!");
    print PARAM_FILE "<Param_defs>\n";

    my @params = $param_doc->getElementsByTagName("Param");

    foreach my $param_node (@params){

	# We don't want 'internal' parameters
	my $parent = $param_node->getParentNode();
	my $internal = $param_node->getElementsByTagName("Is_internal");
	my $val = $internal->item(0)->getFirstChild->getData;
	if ("$val" eq "TRUE"){
	    $parent->removeChild($param_node);
	    next;
	}

	# We don't want 'monitored' parameters
        $internal =  $param_node->getElementsByTagName("Steerable");
	$val = $internal->item(0)->getFirstChild->getData;
	if ("$val" eq "0"){
	    $parent->removeChild($param_node);
	    next;
	}

	my $param = $param_node->toString;
	print PARAM_FILE "$param\n";
    }

    my @labels = $param_doc->getElementsByTagName("Label");
    my @list = ();
    foreach my $label_node (@labels){

	my $label = $label_node->getFirstChild->getData;
	if(index($label, $childID) > -1){
	    # This parameter belongs to this child - we use fact
	    # that encoded labels contain the UID from the end
	    # of a child's GSH.
	    push @list, $label;
	}
    }
    $child_params{$childEPR} = \@list;

    print "\n";

    print PARAM_FILE "</Param_defs>\n";
    close(PARAM_FILE);
}

# Now loop over parameter sets from each child and allow
# user to construct a set of parameters that are in fact
# global.
my $coupling_config = "<couplingConfig>\n<Global_param_list>\n";

while (1) {
    my $input;
    my @param_set = ();

    foreach my $epr (@childEPRList){

	print "EPR = $epr\n";
	my $count = 0;
	foreach my $label (@{$child_params{$epr}}){
	    print "  Label $count = $label\n";
	    $count++;
	}

	print "Select parameter to add to set or <return> for none: ";
	$input = <STDIN>;
	chomp($input);
	next if !$input;
	push @param_set, $epr;
	push @param_set, $child_params{$epr}[$input];
    }

    print "\nSet consists of: \n";
    for (my $i = 0; $i < @param_set; $i+=2){
	print "$param_set[$i]: $param_set[$i+1]\n";
    }
    print "\nName of this set/global parameter: ";
    $input = <STDIN>;
    chomp($input);

    $coupling_config .= "  <Global_param name=\"$input\">\n";

    for (my $i = 0; $i < @param_set; $i+=2){
	$coupling_config .= "    <Child_param id=\"$param_set[$i]\" ".
	    "label=\"$param_set[$i+1]\"/>\n";
    }
    $coupling_config .= "  </Global_param>\n";

    print "\nConstruct another set (y/n)? ";
    $input = <STDIN>;
    chomp($input);
    last if ("$input" eq "n" || "$input" eq "N");
}

$coupling_config .= "</Global_param_list>\n</couplingConfig>\n";

print "\n".$coupling_config."\n";

$content = "<wsrp:Insert>".$coupling_config."</wsrp:Insert>";

$ans =  WSRF::Lite
    -> uri("SWS")
    -> wsaddress(WSRF::WS_Address->new()->Address($parentEPR)) 
    -> SetResourceProperties(SOAP::Data->value($content)->type('xml'));

print "Done\n";




