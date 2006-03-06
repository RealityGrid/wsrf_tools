#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "ReG_Steer_Utils.h"
#include "soapH.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char  passphrase[256];
  char  username[256];
  char  EPR[256];
  char  msg[1024];
  struct soap mySoap;

  if(argc != 4){
    printf("Usage:\n  addUser <address of SWS> <passphrase> <username to add>\n");
    return 1;
  }
  soap_init(&mySoap);

  strncpy(EPR, argv[1], 256);
  strncpy(passphrase, argv[2], 256);
  strncpy(username, argv[3], 256);
  snprintf(msg, 1024, "<user>%s</user>", username);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(EPR, "https") == EPR) ){

    REG_Init_ssl_context(&mySoap,
			 REG_TRUE, /* Authenticate SWS */
			 NULL,/* user's cert. & key file */
			 NULL,/* Password to read key file */
			 "/etc/grid-security/certificates");
  }

  Set_resource_property(&mySoap, EPR, getenv("USER"), 
                        passphrase, msg);

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
