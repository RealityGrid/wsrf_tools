#!/usr/bin/env perl
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

use DBI;
use strict;

if(@ARGV != 1){
    print "Useage: ./destroyChkNode <GSH/ID of node to destroy>\n";
    exit;
}

my $GSH = $ARGV[0];
if(index($GSH, "service\?") > -1){
    my @bits = split(/service\?/, $GSH);
    $GSH = $bits[1];
}

my $datasource="dbi:mysql:database=RealityGridTree;host=vermont.mvc.mcc.ac.uk";
my $username="zzcgumk";
my $auth="mysqlig";

my $dbh = DBI->connect($datasource, $username, $auth)
                         or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT SGE_GSH,SG_GSH FROM ".
			"ServiceGroupEntries WHERE Registered_GSH = ?");
$sth->execute( $GSH );
my @row = $sth->fetchrow_array;
my ($targetNodeSGE, $targetNodeSG) = @row;
print "Node $GSH has SGE= $targetNodeSGE and SG = $targetNodeSG\n";
die "Cannot delete the root of a Checkpoint Tree (use pruneChkTree.pl ".
    "to delete a Tree)\n" if ($targetNodeSG eq "ActiveTrees");

# Get its parent node
$sth = $dbh->prepare("SELECT ParentNode,SteeringCommands FROM NodeData ".
		     "WHERE NodeGSH = ?");
$sth->execute( $GSH );
@row = $sth->fetchrow_array;
my ($parent, $steerCmdsXML) = @row;

print "Parent node = $parent\n";
$steerCmdsXML =~ s/<\/Steer_log>//;

# Get its children
$sth = $dbh->prepare("SELECT SGE_GSH,Registered_GSH FROM ".
		     "ServiceGroupEntries WHERE SG_GSH = ?");
$sth->execute( $GSH );

while(@row = $sth->fetchrow_array){
    my ($childSGE,$childGSH) = @row;
    # Each child will now belong to a new SG/have a new parent and have 
    # additional steering commands
    my $sth1 = $dbh->prepare("SELECT SteeringCommands FROM ".
			     "NodeData WHERE NodeGSH = ?");
    $sth1->execute( $childGSH );
    @row = $sth1->fetchrow_array;
    my $childXML = $row[0];
    $childXML =~ s/<Steer_log>//;
    $childXML = $steerCmdsXML . $childXML;

    # Update the log of steering commands for this child
    print("UPDATE NodeData SET SteeringCommands = $childXML WHERE NodeGSH = $childGSH\n");
    $sth1 = $dbh->prepare("UPDATE NodeData SET SteeringCommands = ? WHERE NodeGSH = ?");
    $sth1->execute( $childXML, $childGSH );

    # Update the parent node of this child
    print("UPDATE NodeData SET ParentNode = $parent WHERE NodeGSH = $childGSH\n");
    $sth1 = $dbh->prepare("UPDATE NodeData SET ParentNode = ? WHERE NodeGSH = ?");
    $sth1->execute( $parent, $childGSH );

    # Change the ServiceGroup of this child to be that of its parent
    print "UPDATE ServiceGroupEntries SET SG_GSH = $targetNodeSG WHERE Registered_GSH = $childGSH\n";
    $sth1 = $dbh->prepare("UPDATE ServiceGroupEntries SET SG_GSH = ? WHERE Registered_GSH = ?");
    $sth1->execute( $targetNodeSG, $childGSH );
    print "UPDATE ServiceGroupContent SET SG_GSH = $targetNodeSG WHERE SGE_GSH = $childSGE\n";
    $sth1 = $dbh->prepare("UPDATE ServiceGroupContent SET SG_GSH = ? WHERE SGE_GSH = ?");
    $sth1->execute( $targetNodeSG, $childSGE );
    $sth1->finish();
}

# Finally, remove the target node itself
print "Removing row from ServiceGroupEntries where SGE_GSH ".
    "== $targetNodeSGE...\n";
$sth = $dbh->prepare("DELETE FROM ServiceGroupEntries WHERE SGE_GSH = ?");
$sth->execute( $targetNodeSGE );

print "Removing row from ServiceGroupContent where SGE_GSH ".
    "== $targetNodeSGE...\n";
$sth = $dbh->prepare("DELETE FROM ServiceGroupContent WHERE SGE_GSH = ?");
$sth->execute( $targetNodeSGE );

print "Removing row from GSH_URL_map where GSH_id == $GSH...\n";
$sth = $dbh->prepare("DELETE FROM GSH_URL_map WHERE GSH_id = ?");
$sth->execute( $GSH );

print "Removing row from NodeData where NodeGSH == $GSH...\n";
$sth = $dbh->prepare("DELETE FROM NodeData WHERE NodeGSH = ?");
$sth->execute( $GSH );

$sth->finish();
$dbh->disconnect();
exit;
