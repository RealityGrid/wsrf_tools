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
  char   securityConfigFile[REG_MAX_STRING_LENGTH];
  char   filterString[128];
  char  *passPtr;
  int    i;
  int    num_entries;
  struct registry_entry *entries;
  struct reg_security_info   sec;

  printf("\n");
  if(argc < 2 || argc > 3){
    printf("Usage:\n  browseRegistry <EPR of Registry "
	   "(ServiceGroup)> [<pattern to filter on>]\n");
    return 1;
  }
  strncpy(registryEPR, argv[1], 128);
  Wipe_security_info(&sec);
  memset(filterString, '\0', 128);

  if(argc==3){
    strncpy(filterString, argv[2], 128);
  }

  if(strstr(registryEPR, "https") == registryEPR){
    
    /* Read the location of certs etc. into global variables */
    if( !(passPtr = getenv("HOME")) ){
      fprintf(stderr, "Failed to get $HOME environment variable\n");
      return 1;
    }
    snprintf(securityConfigFile, REG_MAX_STRING_LENGTH,
	     "%s/RealityGrid/etc/security.conf", passPtr);

    if(Get_security_config(securityConfigFile, &sec)){
      printf("Failed to get security configuration\n");
      return 1;
    }

    /* Now get the user's passphrase for their key */
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);

  }
  else{
    /* No SSL - get the passphrase for the registry */
    if( !(passPtr = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
      }
    printf("\n");
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);

    if( !(passPtr = getpass("Enter your username: ")) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.userDN, passPtr, REG_MAX_STRING_LENGTH);
    
  }

  /* Finally, we can contact the registry */
  if(filterString[0]){
    if(Get_registry_entries_filtered_secure(registryEPR, &sec,
					    &num_entries,  
					    &entries,
					    filterString) != REG_SUCCESS){
      printf("Get_registry_entries_filtered_secure failed\n");
      return 1;
    }
  }
  else{
    if(Get_registry_entries_secure(registryEPR,
				   &sec, 
				   &num_entries,  
				   &entries) != REG_SUCCESS){
      printf("Get_registry_entries_secure failed\n");
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
