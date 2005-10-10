#include <stdio.h>
#include <ReG_Steer_Steerside.h>
#include <ReG_Steer_Browser.h>
/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char   registryEPR[128];
  int    i;
  int    status;
  char  *out1;
  int    num_entries;
  struct registry_entry *entries;

  if(argc < 2 || argc > 3){
    printf("Usage:\n  browseRegistry <EPR of Registry "
	   "(ServiceGroup)> [<pattern to filter on>]\n");
    return 1;
  }
  strncpy(registryEPR, argv[1], 128);

  if(argc != 3){

    if(Get_registry_entries(registryEPR, &num_entries,  
			    &entries) != REG_SUCCESS){
      printf("Get_registry_entries failed\n");
      return 1;
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
    printf("          user: %s, %s\n", entries[i].user, entries[i].group);
    printf("    Start time: %s\n", entries[i].start_date_time);
    printf("   Description: %s\n\n", entries[i].job_description);
  }
  free(entries);
  return 0;
}
