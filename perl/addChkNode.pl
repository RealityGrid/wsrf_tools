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

BEGIN{
    @INC = (@INC, $ENV{WSRF_LOCATION});
}

use strict;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
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
