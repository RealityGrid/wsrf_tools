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
