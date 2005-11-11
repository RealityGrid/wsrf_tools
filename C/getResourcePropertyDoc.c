#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "soapH.h"
#include "ReG_Steer_types.h"
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

  signal(SIGPIPE, sigpipe_handle); 

  if(argc != 2){
    printf("Usage:\n  getResourcePropertyDoc <EPR of SWS>\n");
    return 1;
  }

  soap_init(&mySoap);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(argv[1], "https") == argv[1]) ){

    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get passphrase from command line\n");
      return 1;
    }

    strncpy(input, passPtr, MAX_LEN);

    if (soap_ssl_client_context(&mySoap,
				SOAP_SSL_DEFAULT,
				NULL,/*"/home/zzcguap/.globus/usercertandkey.pem", /* user's cert. file */
				NULL,/*input, /* Password to read key file */
				NULL,  /* Optional CA cert. file to store trusted certificates (to verify server) */
				"/etc/grid-security/certificates", /* Optional path to directory containing trusted CA certs */
				NULL)){ /* if randfile!=NULL: use a file with random data to seed randomness */
      soap_print_fault(&mySoap, stderr);
      exit(1);
    }
  }

  Get_resource_property_doc(&mySoap,
			    argv[1],
			    &rpDoc);
	 
  fprintf(stdout, "Resource property document:\n>>%s<<\n", rpDoc);

  /* Explicitly wipe the passphrase from memory */
  memset((void *)(input), '\0', MAX_LEN);

  soap_end(&mySoap);
  soap_done(&mySoap);
  return 0;
}
