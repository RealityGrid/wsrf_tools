#!/usr/bin/env perl 

use DBI;
use strict;

#----------------------------------------------------------------

sub deleteNodeEntry {

    my ($dbh, $nodeGSH, $nodeSGE) = @_;

    print "Removing row from ServiceGroupEntries where SGE_GSH ".
	"== $nodeSGE...\n";
    my $sth = $dbh->prepare("DELETE FROM ServiceGroupEntries WHERE SGE_GSH = ?");
    $sth->execute( $nodeSGE );

    print "Removing row from ServiceGroupContent where SGE_GSH ".
	"== $nodeSGE...\n";
    $sth = $dbh->prepare("DELETE FROM ServiceGroupContent WHERE SGE_GSH = ?");
    $sth->execute( $nodeSGE );

    print "Removing row from GSH_URL_map where GSH_id == $nodeGSH...\n";
    $sth = $dbh->prepare("DELETE FROM GSH_URL_map WHERE GSH_id = ?");
    $sth->execute( $nodeGSH );

    print "Removing row from NodeData where NodeGSH == $nodeGSH...\n";
    $sth = $dbh->prepare("DELETE FROM NodeData WHERE NodeGSH = ?");
    $sth->execute( $nodeGSH );
}

#----------------------------------------------------------------

if(@ARGV != 1){
    print "\nUseage: pruneChkTree.pl <ID or GSH of starting node>\n\n";
    print "e.g. pruneChkTree.pl \"http://a.machine.addr:10560/Session".
	"/RealityGridTree/service?/52595\"\n";
    print "or; pruneChkTree.pl /52595\n\n";
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

my $ans = "";
my $count = 0;
my $sth;

while(1){

    print "Loop $count:\n";
    $count++;

    $sth = $dbh->prepare("SELECT SGE_GSH,Registered_GSH FROM ServiceGroupEntries WHERE SG_GSH = ?");
    $sth->execute( $GSH );

    my @nodeGSHs = ();
    my @sgeGSHs = ();
    my $SGE_GSH;
    my $Registered_GSH;

    while(my @row = $sth->fetchrow_array ){

	($SGE_GSH,$Registered_GSH) = @row;
	push @nodeGSHs, $Registered_GSH;
	push @sgeGSHs, $SGE_GSH;
	print "Child Data Node Registered_GSH: $Registered_GSH\n";
	$sth = $dbh->prepare("SELECT SGE_GSH,Registered_GSH FROM ServiceGroupEntries WHERE SG_GSH = ?");
	$sth->execute( $Registered_GSH );
    }
    if (@{nodeGSHs} == 0){
	print "No children left...\n";
	last;
    }

    my $lastNodeSGE = pop @sgeGSHs;
    my $lastNodeGSH = pop @nodeGSHs;
    print "SGE of last node = $lastNodeSGE\n";
    print "GSH of last node = $lastNodeGSH\n";
    deleteNodeEntry($dbh, $lastNodeGSH, $lastNodeSGE);
}

# Finally, delete the node we were given to start with (now that it
# has no children
my $sth = $dbh->prepare("SELECT SGE_GSH,SG_GSH FROM ServiceGroupEntries WHERE Registered_GSH = ?");
$sth->execute( $GSH );
my @row = $sth->fetchrow_array;
my($sge, $sg_gsh) = @row;
print "Selected root node has SGE of $sge and is in SG $sg_gsh\n";
deleteNodeEntry($dbh, $GSH, $sge);

# If the root node is actually the root of a checkpoint tree then
# we must remove it from the ActiveTrees ServiceGroup too...
if($sg_gsh eq "ActiveTrees"){
    print "Selected root node is the root of a tree - deleting ".
	"from ActiveTrees...\n";
    $sth = $dbh->prepare("DELETE FROM ActiveTrees WHERE SGE_GSH = ?");
    $sth->execute( $sge );
}

$sth->finish();
$dbh->disconnect();
exit;
