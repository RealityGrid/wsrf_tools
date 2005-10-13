#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "soapH.h"
#include "ReG_Steer_types.h"
#include "ReG_Steer_Steerside_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  struct soap mySoap;
  char       *rpDoc;

  if(argc != 2){
    printf("Usage:\n  getResourcePropertyDoc <EPR of SWS>");
    return 1;
  }

  soap_init(&mySoap);

  Get_resource_property_doc(&mySoap,
			    argv[1],
			    &rpDoc);
	 
  fprintf(stdout, "Resource property document:\n>>%s<<\n", rpDoc);

  soap_end(&mySoap);
  soap_done(&mySoap);
  return 0;
}
