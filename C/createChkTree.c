/*---------------------------------------------------------------------------
  (C) Copyright 2006, University of Manchester, United Kingdom,
  all rights reserved.

  This software was developed by the RealityGrid project
  (http://www.realitygrid.org), funded by the EPSRC under grants
  GR/R67699/01 and GR/R67699/02.

  LICENCE TERMS

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  THIS MATERIAL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. THE ENTIRE RISK AS TO THE QUALITY
  AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE
  DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
  CORRECTION.
---------------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "ReG_Steer_Utils.h"
#include <unistd.h>
#include "signal.h"
#include "configFileParser.h"

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

  if(Get_tools_config(NULL, &conf) != REG_SUCCESS){
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
