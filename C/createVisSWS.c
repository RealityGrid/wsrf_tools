#include <stdio.h>
#include <stdlib.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Common.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_XML.h"
#include "ReG_Steer_Utils_WSRF.h"
#include "soapH.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int   lifetime;
  char  containerAddr[256];
  char  registryAddr[256];
  char  application[256];
  char  dataSource[256];
  char  purpose[1024];
  char  iodef_label[256];
  char *username;
  char *group = "RSS";
  char *EPR;
  char *ioTypes;
  struct soap mySoap;
  struct wsrp__SetResourcePropertiesResponse response;
  struct msg_struct *msg;
  xmlDocPtr doc;
  xmlNsPtr   ns;
  xmlNodePtr cur;
  struct io_struct *ioPtr;
  int               i, count;

  if(argc != 7){
    printf("Usage:\n  createVisSWS <address of container> <address of registry>"
	   "<EPR of data source> <runtime (min)> <application> <purpose>\n");
    return 1;
  }

  strncpy(containerAddr, argv[1], 256);
  strncpy(registryAddr, argv[2], 256);
  strncpy(dataSource, argv[3], 256);
  sscanf(argv[4], "%d", &lifetime);
  strncpy(application, argv[5], 256);
  strncpy(purpose, argv[6], 1024);
  username = getenv("USER");

  /* Obtain the IOTypes from the data source */
  soap_init(&mySoap);
  if( Get_resource_property (&mySoap,
			     dataSource,
			     "ioTypeDefinitions",
			     &ioTypes) != REG_SUCCESS ){

    printf("Call to get ioTypeDefinitions ResourceProperty on %s failed\n",
	   dataSource);
    return 1;
  }

  printf("Got ioTypeDefinitions >>%s<<\n", ioTypes);

  if( !(doc = xmlParseMemory(ioTypes, strlen(ioTypes))) ||
      !(cur = xmlDocGetRootElement(doc)) ){
    fprintf(stderr, "Hit error parsing buffer\n");
    xmlFreeDoc(doc);
    xmlCleanupParser();
    return 1;
  }

  ns = xmlSearchNsByHref(doc, cur,
            (const xmlChar *) "http://www.realitygrid.org/xml/steering");

  if ( xmlStrcmp(cur->name, (const xmlChar *) "ioTypeDefinitions") ){
    fprintf(stderr, "ioTypeDefinitions not the root element\n");
    return 1;
  }
  /* Step down to ReG_steer_message and then to IOType_defs */
  cur = cur->xmlChildrenNode->xmlChildrenNode;

  msg = New_msg_struct();
  msg->io_def = New_io_def_struct();
  parseIOTypeDef(doc, ns, cur, msg->io_def);
  Print_msg(msg);

  if(!(ioPtr = msg->io_def->first_io) ){
    fprintf(stderr, "Got no IOType definitions from data source\n");
    return 1;
  }
  i = 0;
  printf("Available IOTypes:\n");
  while(ioPtr){
    if( !xmlStrcmp(ioPtr->direction, (const xmlChar *)"OUT") ){
      printf("  %d: %s\n", i++, (char *)ioPtr->label);
    }
    ioPtr = ioPtr->next;
  }
  count = i-1;
  printf("Enter IOType to use as data source (0-%d): ", count);
  while(1){
    if(scanf("%d", &i) == 1)break;
  }
  printf("\n");

  count = 0; ioPtr = msg->io_def->first_io;
  while(ioPtr){
    if( !xmlStrcmp(ioPtr->direction, (const xmlChar *)"OUT") ){
      if(count == i){
	strncpy(iodef_label, (char *)(ioPtr->label), 256);
	break;
      }
      count++;
    }
    ioPtr = ioPtr->next;
  }

  Delete_msg_struct(&msg);

  /* Now create SWS for the vis */

  if( !(EPR = Create_SWS(lifetime, containerAddr, registryAddr,
			 username, group, application,
			 purpose, "")) ){
    printf("FAILED to create SWS for %s :-(\n", application);
    return 1;
  }

  /* Finally, set it up with information on the data source*/

  snprintf(purpose, 1024, "<dataSource><sourceEPR>%s</sourceEPR>"
	   "<sourceLabel>%s</sourceLabel></dataSource>",
	   dataSource, iodef_label);

  printf("Calling SetResourceProperties with >>%s<<\n",
	 purpose);
  if(soap_call_wsrp__SetResourceProperties(&mySoap, EPR, 
					   "", purpose, &response) != SOAP_OK){
    soap_print_fault(&mySoap, stderr);
    return 1;
  }

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
