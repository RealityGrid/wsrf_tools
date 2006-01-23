#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"
#include <unistd.h>
#include "signal.h"

#include "libxml/xmlmemory.h"
#include "libxml/parser.h"
#include "securityUtils.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int    i, input;
  int    num_entries;
  struct registry_entry *entries;
  char  containerAddr[MAX_LEN];
  char  registryAddr[MAX_LEN];
  char *EPR;
  char *keyPassphrase = NULL;
  struct job_details job;
  struct security_info sec;

  job.userName[0] = '\0';
  snprintf(job.group, REG_MAX_STRING_LENGTH, "RSS");
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';

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

    /* Read the location of certs etc. into global variables */
    if(getSecurityConfig(&sec)){
      printf("Failed to get security configuration\n");
      return 1;
    }
    snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", sec.userDN);

    /* Now get the user's passphrase for their key */
    if( !(keyPassphrase = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
  }

  if(Get_registry_entries_filtered_secure(registryAddr,
					  keyPassphrase,
					  sec.myKeyCertFile, 
					  sec.caCertsPath,  
					  &num_entries,  &entries,
					  "Container registry") != REG_SUCCESS){
    printf("Search for registry of available containers failed\n");
    return 1;
  }

  if(num_entries != 1){
    printf("Search for registry of available containers failed: "
	   "returned %d entries\n", num_entries);
    return 1;
  }

  strcpy(containerAddr, entries[0].gsh);
  free(entries);
  if(Get_registry_entries_filtered_secure(containerAddr, 
					  keyPassphrase,
					  sec.myKeyCertFile, 
					  sec.caCertsPath,  
					  &num_entries,  
					  &entries,
					  "Container") != REG_SUCCESS){
    printf("Search for available containers failed\n");
    return 1;
  }

  if(num_entries == 0){
    printf("No containers available :-(\n");
    return 1;
  }

  printf("Available containers:\n");
  for(i=0; i<num_entries; i++){
    if( !strcmp(entries[i].service_type, "Container") ){
      printf("  %d: EPR: %s\n", i, entries[i].gsh);
    }
  }
  printf("Enter container to use [0-%d]: ",num_entries-1);
  while(1){
    if((scanf("%d", &input) == 1) && 
       (input > -1 && input < num_entries))break;
    printf("\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, entries[input].gsh);
  free(entries);

  EPR = Create_steering_service(&job, containerAddr, registryAddr,
				keyPassphrase, sec.myKeyCertFile,
				sec.caCertsPath);
  if(EPR){
    printf("\nAddress of SWS = %s\n", EPR);
  }
  else{
    printf("\nFAILED to create SWS :-(\n");
  }
	 
  return 0;
}
