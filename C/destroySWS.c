#include <stdio.h>
#include <stdlib.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int i;

  if(argc < 3 || ((argc-1)%2 != 0) ){
    printf("Usage:\n  destroySWS <EPR of SWS 1> <passphrase of SWS 1> "
	   "[<EPR of SWS 2> <passphrase of SWS2>...]\n");
    printf("\ne.g.: ./destroySWS http://localhost:5000/854884847 secretsanta\n");
    printf("or, if the service has no passphrase: ./destroySWS "
	   "http://localhost:5000/854884847 \"\" \n\n");
    return 1;
  }
  printf("\n");

  for(i=1; i<argc; i+=2){
    if(Destroy_WSRP(argv[i], getenv("USER"), argv[i+1]) == REG_SUCCESS){
      printf("Destroyed %s\n", argv[i]);
    }
  }
  printf("\n");
	 
  return 0;
}
