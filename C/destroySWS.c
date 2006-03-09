#include <stdio.h>
#include <stdlib.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int i;
  struct reg_security_info sec;
  Wipe_security_info(&sec);

  if(argc < 3 || ((argc-1)%2 != 0) ){
    printf("Usage:\n  destroySWS <EPR of SWS 1> <passphrase of SWS 1> "
	   "[<EPR of SWS 2> <passphrase of SWS2>...]\n");
    printf("\ne.g.: ./destroySWS http://localhost:5000/854884847 secretsanta\n");
    printf("or, if the service has no passphrase: ./destroySWS "
	   "http://localhost:5000/854884847 \"\" \n\n");
    return 1;
  }
  printf("\n");

  strncpy(sec.userDN, getenv("USER"), REG_MAX_STRING_LENGTH);
  sec.use_ssl = 0;

  for(i=1; i<argc; i+=2){

    strncpy(sec.passphrase, argv[i+1], REG_MAX_STRING_LENGTH);
    if(Destroy_WSRP(argv[i], &sec) == REG_SUCCESS){
      printf("Destroyed %s\n", argv[i]);
    }
  }
  printf("\n");
	 
  return 0;
}
