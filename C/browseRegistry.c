#include <stdio.h>
#include <string.h>
#include <ReG_Steer_types.h>
#include <ReG_Steer_Browser.h>
#include <unistd.h>
#include "signal.h"
#include "securityUtils.h"

#include "libxml/xmlmemory.h"
#include "libxml/parser.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char   registryEPR[128];
  char  *passPtr;
  int    i;
  int    num_entries;
  struct registry_entry *entries;
  struct security_info   sec;

  printf("\n");
  if(argc < 2 || argc > 3){
    printf("Usage:\n  browseRegistry <EPR of Registry "
	   "(ServiceGroup)> [<pattern to filter on>]\n");
    return 1;
  }
  strncpy(registryEPR, argv[1], 128);

  if(argc != 3){

    if(strstr(registryEPR, "https") == registryEPR){

      /* Read the location of certs etc. into global variables */
      if(getSecurityConfig(&sec)){
	printf("Failed to get security configuration\n");
	return 1;
      }

      /* Now get the user's passphrase for their key */
      if( !(passPtr = getpass("Enter passphrase for key: ")) ){

	printf("Failed to get key passphrase from command line\n");
	return 1;
      }
      printf("\n");

      /* Finally, we can contact the registry */
      if(Get_registry_entries_secure(registryEPR, 
				     passPtr,
				     sec.myKeyCertFile,
				     sec.caCertsPath,
				     &num_entries,  
				     &entries) != REG_SUCCESS){
	printf("Get_registry_entries_secure failed\n");
	return 1;
      }
    }
    else{
      if(Get_registry_entries_secure(registryEPR, "","","",&num_entries,  
				     &entries) != REG_SUCCESS){
	printf("Get_registry_entries_secure failed\n");
	return 1;
      }
    }
  }
  else{

    if(Get_registry_entries_filtered(registryEPR, &num_entries,  
				     &entries,
				     argv[2]) != REG_SUCCESS){
      printf("Get_registry_entries_filtered failed\n");
      return 1;
    }
  }

  for(i=0; i<num_entries; i++){
    printf("Entry %d - type: %s\n", i, entries[i].service_type);
    printf("           EPR: %s\n", entries[i].gsh);
    printf("     Entry EPR: %s\n", entries[i].entry_gsh);
    printf("           App: %s\n", entries[i].application);
    printf("  User & group: %s, %s\n", entries[i].user, entries[i].group);
    printf("    Start time: %s\n", entries[i].start_date_time);
    printf("   Description: %s\n\n", entries[i].job_description);
  }
  free(entries);
  return 0;
}
