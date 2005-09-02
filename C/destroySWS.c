#include <stdio.h>
#include <stdlib.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int i;

  if(argc < 2){
    printf("Usage:\n  destroySWS <EPR of SWS 1> [<EPR of SWS 2>...]");
    return 1;
  }

  for(i=1; i<argc; i++){
    if(Destroy_WSRP(argv[i]) == REG_SUCCESS){
      printf("Destroyed %s\n", argv[i]);
    }
  }
	 
  return 0;
}
