#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "ReG_Steer_Utils.h"
#include "ReG_Steer_Utils_WSRF.h"
#include "soapH.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char  containerAddr[256];
  char  registryAddr[256];
  char  dataSource[256];
  char  iodef_label[256];
  char  buf[1024];
  char *EPR;
  char *ioTypes;
  char *passPtr;
  struct soap        mySoap;
  struct msg_struct *msg;
  xmlDocPtr doc;
  xmlNsPtr   ns;
  xmlNodePtr cur;
  struct io_struct        *ioPtr;
  int                      i, count;
  struct registry_contents content;
  struct reg_job_details   job;
  struct reg_security_info sec;

  Wipe_security_info(&sec);

  if(argc != 6){
    printf("Usage:\n  createVisSWS <address of registry> "
	   "<runtime (min)> <application> <purpose> <passphrase>\n");
    return 1;
  }

  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  sprintf(job.group, "RSS");
  strncpy(registryAddr, argv[1], REG_MAX_STRING_LENGTH);
  sscanf(argv[2], "%d", &(job.lifetimeMinutes));
  strncpy(job.software, argv[3], REG_MAX_STRING_LENGTH);
  strncpy(job.purpose, argv[4], REG_MAX_STRING_LENGTH);
  strncpy(job.passphrase, argv[5], REG_MAX_STRING_LENGTH);
  snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", getenv("USER"));
  if(strstr(registryAddr, "https") == registryAddr){

    /* Read the location of certs etc. into global variables */
    if(Get_security_config(NULL, &sec)){
      printf("Failed to get security configuration\n");
      return 1;
    }
    snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", sec.userDN);

    /* Now get the user's passphrase for their key */
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
  }
  else{
    sec.use_ssl = 0;
    if( !(passPtr = getpass("Enter your username for registry: ")) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.userDN, passPtr, REG_MAX_STRING_LENGTH);    
    
    if( !(passPtr = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
    }
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
  }
  printf("\n");

  /* Get the list of available Containers and ask the user to 
     choose one */
  if(Get_registry_entries_filtered_secure(registryAddr, 
					  &sec,
					  &content, 
					  "Container registry") != REG_SUCCESS){
    fprintf(stderr, 
	    "Search for registry of available containers failed\n");
    return 1;
  }

  if(content.numEntries != 1){
    fprintf(stderr, "Search for registry of available containers failed: "
	    "returned %d entries\n", content.numEntries);
    return 1;
  }

  strcpy(containerAddr, content.entries[0].gsh);
  Delete_registry_table(&content);

  if(Get_registry_entries_filtered_secure(containerAddr,
 					  &sec,
					  &content, "Container") != REG_SUCCESS){
    fprintf(stderr, "Search for available containers failed\n");
    return 1;
  }

  if(content.numEntries == 0){
    fprintf(stderr, "No containers available :-(\n");
    return 1;
  }

  fprintf(stdout, "Available containers:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "Container") ){
      fprintf(stdout, "  %d: EPR: %s\n", i, content.entries[i].gsh);
    }
  }
  printf("\nEnter container to use [0-%d]: ",content.numEntries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < content.numEntries))break;
    fprintf(stderr, "\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, content.entries[count].gsh);
  Delete_registry_table(&content);

  /* Look for available SWSs and get user to choose which one to
     use as a data source */
  if(Get_registry_entries_filtered_secure(registryAddr,
					  &sec,  
					  &content,
					  "SWS") != REG_SUCCESS){
    fprintf(stderr, "\nNo jobs to use as data source found in registry!\n");
    return 1;
  }
  printf("\nAvailable jobs:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "SWS") ){
      printf("  %d:      EPR: %s\n", i, content.entries[i].gsh);
      printf("           App: %s\n", content.entries[i].application);
      printf("  User & group: %s, %s\n", 
	     content.entries[i].user, content.entries[i].group);
      printf("    Start time: %s\n", content.entries[i].start_date_time);
      printf("   Description: %s\n\n", content.entries[i].job_description);
    }
  }
  fprintf(stdout, "Select job to use as data source [0-%d]: ",
	  content.numEntries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < content.numEntries))break;
    fprintf(stderr, "\nInvalid choice, please select job [0-%d]: ", 
	    content.numEntries-1);
  }
  strncpy(dataSource, content.entries[count].gsh, 256);
  Delete_registry_table(&content);

  /* Ask the user to specify the (WSSE) password for access to 
     this SWS */
  if( !(passPtr = getpass("Enter password for this SWS: ")) ){

    printf("Failed to get password from command line\n");
    return 1;
  }
  strncpy(job.passphrase, passPtr, REG_MAX_STRING_LENGTH);

  /* Obtain the IOTypes from the data source */
  soap_init(&mySoap);
  if( Get_resource_property (&mySoap,
			     dataSource,
			     sec.userDN,
			     sec.passphrase,
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
  if( !(EPR = Create_steering_service(&job, containerAddr, 
				      registryAddr, &sec)) ){
    printf("FAILED to create SWS for %s :-(\n", job.software);
    return 1;
  }
  fprintf(stdout, "\nAddress of SWS = %s\n", EPR);

  /* Finally, set it up with information on the data source*/

  snprintf(buf, 1024, "<dataSource><sourceEPR>%s</sourceEPR>"
	   "<sourceLabel>%s</sourceLabel></dataSource>",
	   dataSource, iodef_label);

  if(Set_resource_property(&mySoap, EPR,
			   job.userName, job.passphrase,
			   buf) != REG_SUCCESS){
    fprintf(stderr, "Failed to initialize SWS with info. on data source :-(");

    if(Destroy_WSRP(EPR, &sec) == REG_SUCCESS){
      fprintf(stderr, "  => Destroyed %s\n", EPR);
    }
    else{
      fprintf(stderr, "    Also failed to clean-up the SWS %s\n", EPR);
    }
    soap_end(&mySoap);
    soap_done(&mySoap);
    return 1;
  }

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
