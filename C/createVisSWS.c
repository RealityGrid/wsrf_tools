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
  int               num_entries;
  struct registry_entry *entries;

  if(argc != 5){
    printf("Usage:\n  createVisSWS <address of registry> "
	   "<runtime (min)> <application> <purpose>\n");
    return 1;
  }

  strncpy(registryAddr, argv[1], 256);
  sscanf(argv[2], "%d", &lifetime);
  strncpy(application, argv[3], 256);
  strncpy(purpose, argv[4], 1024);
  username = getenv("USER");

  /* Get the list of available Containers and ask the user to 
     choose one */
  if(Get_registry_entries_filtered(registryAddr, &num_entries,  
				   &entries,
				   "Container registry") != REG_SUCCESS){
    fprintf(stderr, 
	    "Search for registry of available containers failed\n");
    return 1;
  }

  if(num_entries != 1){
    fprintf(stderr, "Search for registry of available containers failed: "
	    "returned %d entries\n", num_entries);
    return 1;
  }

  strcpy(containerAddr, entries[0].gsh);
  free(entries);
  if(Get_registry_entries_filtered(containerAddr, &num_entries,  
				   &entries,
				   "Container") != REG_SUCCESS){
    fprintf(stderr, "Search for available containers failed\n");
    return 1;
  }

  if(num_entries == 0){
    fprintf(stderr, "No containers available :-(\n");
    return 1;
  }

  fprintf(stdout, "Available containers:\n");
  for(i=0; i<num_entries; i++){
    if( !strcmp(entries[i].service_type, "Container") ){
      fprintf(stdout, "  %d: EPR: %s\n", i, entries[i].gsh);
    }
  }
  printf("\nEnter container to use [0-%d]: ",num_entries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < num_entries))break;
    fprintf(stderr, "\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, entries[count].gsh);
  free(entries);

  /* Look for available SWSs and get user to choose which one to
     use as a data source */
  if(Get_registry_entries_filtered(registryAddr, &num_entries,  
				   &entries,
				   "SWS") != REG_SUCCESS){
    fprintf(stderr, "\nNo jobs to use as data source found in registry!\n");
    return 1;
  }
  printf("\nAvailable jobs:\n");
  for(i=0; i<num_entries; i++){
    if( !strcmp(entries[i].service_type, "SWS") ){
      printf("  %d:      EPR: %s\n", i, entries[i].gsh);
      printf("           App: %s\n", entries[i].application);
      printf("          user: %s, %s\n", entries[i].user, entries[i].group);
      printf("    Start time: %s\n", entries[i].start_date_time);
      printf("   Description: %s\n\n", entries[i].job_description);
    }
  }
  fprintf(stdout, "Select job to use as data source [0-%d]: ",
	  num_entries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < num_entries))break;
    fprintf(stderr, "\nInvalid choice, please select job [0-%d]: ", 
	    num_entries-1);
  }
  strncpy(dataSource, entries[count].gsh, 256);
  free(entries);

  /* Obtain the IOTypes from the data source */
  soap_init(&mySoap);
  if( Get_resource_property (&mySoap,
			     dataSource,
			     "ioTypeDefinitions",
			     &ioTypes) != REG_SUCCESS ){

    fprintf(stderr, "Call to get ioTypeDefinitions ResourceProperty on "
	    "%s failed\n", dataSource);
    return 1;
  }

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

  if(!(ioPtr = msg->io_def->first_io) ){
    fprintf(stderr, "Got no IOType definitions from data source\n");
    return 1;
  }
  i = 0;
  fprintf(stdout, "Available IOTypes:\n");
  while(ioPtr){
    if( !xmlStrcmp(ioPtr->direction, (const xmlChar *)"OUT") ){
      fprintf(stdout, "  %d: %s\n", i++, (char *)ioPtr->label);
    }
    ioPtr = ioPtr->next;
  }
  count = i-1;
  fprintf(stdout, "\nEnter IOType to use as data source [0-%d]: ", count);
  while(1){
    if(scanf("%d", &i) == 1)break;
  }
  fprintf(stdout, "\n");

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

  if( !(EPR = Create_steering_service(lifetime, 
				      containerAddr, registryAddr,
				      username, group, application,
				      purpose, "", /* name of input file */
				      "")) ){ /* chkpoint GSH to restart from */
    printf("FAILED to create SWS for %s :-(\n", application);
    return 1;
  }

  fprintf(stdout, "Address of SWS = %s\n", EPR);

  /* Finally, set it up with information on the data source*/

  snprintf(purpose, 1024, "<dataSource><sourceEPR>%s</sourceEPR>"
	   "<sourceLabel>%s</sourceLabel></dataSource>",
	   dataSource, iodef_label);

  if(soap_call_wsrp__SetResourceProperties(&mySoap, EPR, 
					   "", purpose, &response) != SOAP_OK){
    soap_print_fault(&mySoap, stderr);
    fprintf(stderr, "Failed to initialize SWS with info. on data source :-(");
    return 1;
  }

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
