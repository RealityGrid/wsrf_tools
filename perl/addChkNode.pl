#!/usr/bin/env perl

BEGIN{
    @INC = (@INC, $ENV{WSRF_LOCATION});
}

use strict;
use WSRF::Lite +trace =>  debug => sub {};
use SOAP::Lite;

if(@ARGV != 1){
    print "Useage:\n";
    print "  ./addChkNode.pl <EPR of node to add to>\n";
    exit;
}

my $gsh = $ARGV[0];

my $chkMetaData = <<EOF;
<Checkpoint_data application="mini_app v.1.0">
<Chk_type>1002</Chk_type>
<Chk_UID>1804289383</Chk_UID>
<Files location="methuselah.mvc.mcc.ac.uk">
  <file type="gsiftp-URL">gsiftp://methuselah.mvc.mcc.ac.uk/home/zzcguap/RealityGrid/scratch/./fake_chkpoint_1804289383.dat</file>
</Files>
</Checkpoint_data>
EOF

my $steeringCmds = <<EOF;
<Steer_log>
<Log_entry><Steer_log_entry><Param><Value>4</Value><Handle>12</Handle></Param></Steer_log_entry><Seq_num>12</Seq_num></Log_entry><Log_entry><Steer_log_entry><Param>
<Value>0</Value><Handle>2</Handle></Param></Steer_log_entry>
<Seq_num>13</Seq_num></Log_entry><Log_entry><Steer_log_entry>
<Command><Cmd_param><Value>OUT</Value><Handle>(null)</Handle>
</Cmd_param><Cmd_param><Value>1</Value><Handle>(null)</Handle>
</Cmd_param><Cmd_id>1002</Cmd_id></Command></Steer_log_entry>
<Seq_num>24</Seq_num></Log_entry></Steer_log>
EOF

my $input_file = "";
my $nodeMetaData = <<EOF;
<Checkpoint_node_data>
<Param>
<Handle>-100</Handle>
<Label>SEQUENCE_NUM</Label>
<Value>24</Value>
</Param>
<Param>
<Handle>-99</Handle>
<Label>CPU_TIME_PER_STEP</Label>
<Value>0.000</Value>
</Param>
<Param>
<Handle>-98</Handle>
<Label>TIMESTAMP</Label>
<Value>Thu Apr 13 12:50:52 2006
</Value>
</Param>
<Param>
<Handle>-97</Handle>
<Label>STEERING_INTERVAL</Label>
<Value>1</Value>
</Param>
<Param>
<Handle>0</Handle>
<Label>WALL CLOCK PER STEP (S)</Label>
<Value>4.0014238357543945312</Value>
</Param>
</Checkpoint_node_data>
EOF

my $som = WSRF::Lite
    -> uri("http://www.realitygrid.org/CheckPointTreeNode")
    -> wsaddress( WSRF::WS_Address->new()->Address($gsh) )
    -> addNode(SOAP::Data->value("$chkMetaData")->type('string'), 
	       SOAP::Data->value("$steeringCmds")->type('string'), 
	       SOAP::Data->value("$input_file")->type('string'), 
	       SOAP::Data->value("$nodeMetaData")->type('string'));
if ($som->fault) {  
    print "RecordCheckpoint: ERROR: addNode call failed:\n";
    print $som->faultcode." ".$som->faultstring.
	" ".$som->faultdetail."\n"; 
    WSRF::BaseFaults::die_with_Fault(Description => $som->faultcode.
				     " ".$som->faultstring,
				     ErrorCode => '103',
				     FaultCause => $som->faultdetail);
}

# addNode returns a WSAddress object if successful
if( $som->match("//{$WSRF::Constants::WSA}Address") ){
    # Update the GSH of the checkpoint we are currently running from
    $WSRF::WSRP::ResourceProperties{checkpointEPR} = 
	$som->valueof("//{$WSRF::Constants::WSA}Address");
    $WSRF::WSRP::ResourceProperties{lastModifiedTime} = time;
}
else{
    print "No WS-Address returned\n";
}
