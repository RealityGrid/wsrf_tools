#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"
#include <unistd.h>
#include "signal.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int    i, input;
  struct registry_contents content;
  char  containerAddr[REG_MAX_STRING_LENGTH];
  char  registryAddr[REG_MAX_STRING_LENGTH];
  char *EPR;
  char *pChar = NULL;
  struct reg_job_details   job;
  struct reg_security_info sec;

  job.userName[0] = '\0';
  snprintf(job.group, REG_MAX_STRING_LENGTH, "RSS");
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';

  Wipe_security_info(&sec);

  if( (argc != 6) && (argc != 7) ){
    printf("Usage:\n  createSWS <address of registry>"
	   " <lifetime (min)> <application> <purpose> <passphrase>"
	   " [checkpoint EPR]\n");
    return 1;
  }

  strncpy(registryAddr, argv[1], REG_MAX_STRING_LENGTH);
  sscanf(argv[2], "%d", &(job.lifetimeMinutes));
  strncpy(job.software, argv[3], REG_MAX_STRING_LENGTH);
  strncpy(job.purpose, argv[4], REG_MAX_STRING_LENGTH);
  snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", getenv("USER"));
  strncpy(job.passphrase, argv[5], REG_MAX_STRING_LENGTH);

  if(argc == 7){
    strncpy(job.checkpointAddress, argv[6], REG_MAX_STRING_LENGTH);
  }

  if(strstr(registryAddr, "https") == registryAddr){

    sec.use_ssl = 1;

    /* Read the location of certs etc. into global variables */
    if(Get_security_config(NULL, &sec) != REG_SUCCESS){
      printf("Failed to get security configuration\n");
      return 1;
    }
    snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", sec.userDN);

    /* Now get the user's passphrase for their key */
    if( !(pChar = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    strncpy(sec.passphrase, pChar, REG_MAX_STRING_LENGTH);
  }
  else{
    sec.use_ssl = 0;

    if( !(pChar = getpass("Enter your username for registry: ")) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.userDN, pChar, REG_MAX_STRING_LENGTH);    
    
    if( !(pChar = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.passphrase, pChar, REG_MAX_STRING_LENGTH);
  }

  if(Get_registry_entries_filtered_secure(registryAddr,
					  &sec,
					  &content,
					  "Container registry") != REG_SUCCESS){
    printf("Search for registry of available containers failed\n");
    return 1;
  }

  if(content.numEntries != 1){
    printf("Search for registry of available containers failed: "
	   "returned %d entries\n", content.numEntries);
    return 1;
  }

  strncpy(containerAddr, content.entries[0].gsh, REG_MAX_STRING_LENGTH);
  Delete_registry_table(&content);

  if(Get_registry_entries_filtered_secure(containerAddr,
					  &sec, 
					  &content,
					  "Container") != REG_SUCCESS){
    printf("Search for available containers failed\n");
    return 1;
  }

  if(content.numEntries == 0){
    printf("No containers available :-(\n");
    return 1;
  }

  printf("Available containers:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "Container") ){
      printf("  %d: EPR: %s\n", i, content.entries[i].gsh);
    }
  }
  printf("Enter container to use [0-%d]: ",content.numEntries-1);
  while(1){
    if((scanf("%d", &input) == 1) && 
       (input > -1 && input < content.numEntries))break;
    printf("\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, content.entries[input].gsh);
  Delete_registry_table(&content);

  EPR = Create_steering_service(&job, containerAddr,
				registryAddr, &sec);
  if(EPR){
    printf("\nAddress of SWS = %s\n", EPR);
  }
  else{
    printf("\nFAILED to create SWS :-(\n");
  }
	 
  return 0;
}
