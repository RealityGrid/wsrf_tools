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
  struct wsrp__SetResourcePropertiesResponse response;

  if(argc != 4){
    printf("Usage:\n  addUser <address of SWS> <passphrase> <username to add>\n");
    return 1;
  }

  strncpy(EPR, argv[1], 256);
  strncpy(passphrase, argv[2], 256);
  strncpy(username, argv[3], 256);

  soap_init(&mySoap);

  if(passphrase[0]){
    Create_WSSE_header(&mySoap, getenv("USER"), passphrase);
  }

  snprintf(msg, 1024, "<user>%s</user>", username);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(EPR, "https") == EPR) ){

    REG_Init_ssl_context(&mySoap,
			 NULL,/* user's cert. & key file */
			 NULL,/* Password to read key file */
			 "/etc/grid-security/certificates");
  }

  if(soap_call_wsrp__SetResourceProperties(&mySoap, EPR, 
					   "", msg, &response) != SOAP_OK){
    soap_print_fault(&mySoap, stderr);
    fprintf(stderr, "Failed to add user >>%s<< to SWS :-(\n\n", username);
    return 1;
  }
  else{
    fprintf(stderr, "Added user >>%s<< to SWS :-)\n\n", username);
  }

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
