#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int    lifetime;
  int    i, input;
  int    num_entries;
  struct registry_entry *entries;
  char  containerAddr[256];
  char  registryAddr[256];
  char  checkpointEPR[256];
  char  application[256];
  char  passphrase[256];
  char  purpose[1024];
  char *username;
  char *group = "RSS";
  char *EPR;

  if( (argc != 6) && (argc != 7) ){
    printf("Usage:\n  createSWS <address of registry>"
	   " <lifetime (min)> <application> <purpose> <passphrase> [checkpoint EPR]\n");
    return 1;
  }

  strncpy(registryAddr, argv[1], 256);
  sscanf(argv[2], "%d", &lifetime);
  strncpy(application, argv[3], 256);
  strncpy(purpose, argv[4], 1024);
  username = getenv("USER");
  strncpy(passphrase, argv[5], 256);

  checkpointEPR[0] = '\0';
  if(argc == 7){
    strncpy(checkpointEPR, argv[6], 256);
  }

  if(Get_registry_entries_filtered(registryAddr, &num_entries,  
				   &entries,
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
  if(Get_registry_entries_filtered(containerAddr, &num_entries,  
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

  EPR = Create_steering_service(lifetime, containerAddr, registryAddr,
				username, group, application,
				purpose, 
				"", /* name of input file */
				checkpointEPR,
				passphrase);
  if(EPR){
    printf("Address of SWS = %s\n", EPR);
  }
  else{
    printf("FAILED to create SWS :-(\n");
  }
	 
  return 0;
}
