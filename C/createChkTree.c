/*
  The RealityGrid Steering Library WSRF Tools

  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
  All rights reserved.

  This software is produced by Research Computing Services, University
  of Manchester as part of the RealityGrid project and associated
  follow on projects, funded by the EPSRC under grants GR/R67699/01,
  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
  EP/F00561X/1.

  LICENCE TERMS

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

    * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of The University of Manchester nor the names
      of its contributors may be used to endorse or promote products
      derived from this software without specific prior written
      permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

  Author: Andrew Porter
          Robert Haines
 */

#include "ReG_Steer_Tools.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

void printUsage();

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int   i;
  char  factoryAddr[REG_MAX_STRING_LENGTH];
  char  treeLabel[REG_MAX_STRING_LENGTH];
  char *pChar = NULL;
  char                    *chkTree;
  struct reg_job_details   job;
  struct reg_security_info sec;
  struct tool_conf         conf;

  job.userName[0] = '\0';
  snprintf(job.group, REG_MAX_STRING_LENGTH, "RSS");
  job.lifetimeMinutes = 0;
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';
  factoryAddr[0] = '\0';
  treeLabel[0] = '\0';

  Wipe_security_info(&sec);

  if( (argc == 1) ){
    printUsage();
    return 1;
  }

  for(i=0; i<argc; i++){
    if(strstr(argv[i], "--factory=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
     strncpy(factoryAddr, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--label=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
        strncpy(treeLabel, ++pChar, REG_MAX_STRING_LENGTH);
    }
  }

  if(get_tools_config(NULL, &conf) != REG_SUCCESS){
    printf("WARNING: Failed to read tools.conf config. file\n");
  }

  if(factoryAddr[0] == '\0'){
    if(conf.checkPointTree[0]){
      strncpy(factoryAddr, conf.checkPointTree, REG_MAX_STRING_LENGTH);
    }
    else{
      printf("No checkpoint tree factory address supplied on cmd line "
	     "or in config file. ");
      printUsage();
      return 1;
    }
  }
  printf("ARPDBG, factory >>%s<<\n", factoryAddr);

  if(treeLabel[0] == '\0'){

    printf("No application name supplied on cmd line or in config file. ");
    printUsage();
    return 1;
  }

  chkTree = Create_checkpoint_tree(factoryAddr, treeLabel);

  printf("Created checkpoint tree: %s\n", chkTree);

  return 0;
}

/*-------------------------------------------------------------------*/

void printUsage(){
  printf("Usage:\n"
	 "  createChkTree --factory=address of checkpoint tree factory"
	 " --label=description of work to be recorded in this tree\n");
}
