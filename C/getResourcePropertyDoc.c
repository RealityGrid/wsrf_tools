#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "soapH.h"
#include "ReG_Steer_types.h"
#include "ReG_Steer_Steerside.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "signal.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  struct soap mySoap;
  char       *rpDoc;
  char       *passPtr;
  const int   MAX_LEN = 1024;
  char        input[MAX_LEN];
  char        username[MAX_LEN];

  signal(SIGPIPE, sigpipe_handle); 

  if(argc != 3){
    printf("Usage:\n  getResourcePropertyDoc <EPR of SWS> <username>\n");
    return 1;
  }
  strncpy(username, argv[2], MAX_LEN);

  soap_init(&mySoap);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(argv[1], "https") == argv[1]) ){

    /* - don't bother with mutually-authenticated SSL
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get passphrase from command line\n");
      return 1;
    }
    strncpy(input, passPtr, MAX_LEN);
    */

    REG_Init_ssl_context(&mySoap,
			 REG_TRUE,
			 NULL,/* user's cert. & key file */
			 NULL,/* Password to read key file */
			 "/etc/grid-security/certificates");
  }

  if( !(passPtr = getpass("Enter SWS password: ")) ){

    printf("Failed to get SWS password from command line\n");
    return 1;
  }

  Get_resource_property_doc(&mySoap,
			    argv[1],
			    username,
			    passPtr,
			    &rpDoc);
	 
  fprintf(stdout, "Resource property document:\n>>%s<<\n", rpDoc);

  /* Explicitly wipe the passphrase from memory */
  memset((void *)(input), '\0', MAX_LEN);

  soap_end(&mySoap);
  soap_done(&mySoap);
  return 0;
}
