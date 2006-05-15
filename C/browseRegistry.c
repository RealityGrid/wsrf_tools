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
  char   filterString[128];
  char   buf[256];
  char  *passPtr;
  int    i;
  struct registry_contents content;
  struct reg_security_info sec;

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

    if(Get_security_config(NULL, &sec)){
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

    snprintf(buf, 256, "Enter your username [%s]: ", getenv("USER"));
    if( !(passPtr = getpass(buf)) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    if(strlen(passPtr) > 0){
      strncpy(sec.userDN, passPtr, REG_MAX_STRING_LENGTH);
    }
    else{
      strncpy(sec.userDN, getenv("USER"), REG_MAX_STRING_LENGTH);
    }
  }

  /* Finally, we can contact the registry */
  if(filterString[0]){
    if(Get_registry_entries_filtered_secure(registryEPR, &sec,
					    &content,
					    filterString) != REG_SUCCESS){
      printf("Get_registry_entries_filtered_secure failed\n");
      return 1;
    }
  }
  else{
    if(Get_registry_entries_secure(registryEPR,
				   &sec, 
				   &content) != REG_SUCCESS){
      printf("Get_registry_entries_secure failed\n");
      return 1;
    }
  }

  for(i=0; i<content.numEntries; i++){
    printf("Entry %d - type: %s\n", i, content.entries[i].service_type);
    printf("           EPR: %s\n", content.entries[i].gsh);
    printf("     Entry EPR: %s\n", content.entries[i].entry_gsh);
    printf("           App: %s\n", content.entries[i].application);
    printf("  User & group: %s, %s\n", 
	   content.entries[i].user, content.entries[i].group);
    printf("    Start time: %s\n", content.entries[i].start_date_time);
    printf("   Description: %s\n\n", content.entries[i].job_description);
  }
  Delete_registry_table(&content);

  return 0;
}
