#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"
#include <unistd.h>
#include "signal.h"

#include "libxml/xmlmemory.h"
#include "libxml/parser.h"

/*------------------------------------------------------------*/
void sigpipe_handle(int x) { }
int getSecurityConfig();

#define MAX_LEN 256
char   securityConfigFile[MAX_LEN];
char   caCertsPath[MAX_LEN]; 
char   myKeyCertFile[MAX_LEN];
char   userDN[MAX_LEN];

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int    i, input;
  int    num_entries;
  struct registry_entry *entries;
  char  containerAddr[MAX_LEN];
  char  registryAddr[MAX_LEN];
  char *EPR;
  char *keyPassphrase = NULL;
  struct job_details job;

  job.userName[0] = '\0';
  sprintf(job.group, "RSS");
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';

  if( (argc != 6) && (argc != 7) ){
    printf("Usage:\n  createSWS <address of registry>"
	   " <lifetime (min)> <application> <purpose> <passphrase> [checkpoint EPR]\n");
    return 1;
  }

  strncpy(registryAddr, argv[1], MAX_LEN);
  sscanf(argv[2], "%d", &(job.lifetimeMinutes));
  strncpy(job.software, argv[3], MAX_LEN);
  strncpy(job.purpose, argv[4], 1024);
  sprintf(job.userName, getenv("USER"));
  strncpy(job.passphrase, argv[5], MAX_LEN);

  if(argc == 7){
    strncpy(job.checkpointAddress, argv[6], MAX_LEN);
  }

  securityConfigFile[0] = '\0';
  caCertsPath[0] = '\0';
  myKeyCertFile[0] = '\0';

  if(strstr(registryAddr, "https") == registryAddr){

    /* Read the location of certs etc. into global variables */
    if(getSecurityConfig()){
      printf("Failed to get security configuration\n");
      return 1;
    }
    sprintf(job.userName, userDN);

    /* Now get the user's passphrase for their key */
    if( !(keyPassphrase = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
  }

  if(Get_registry_entries_filtered_secure(registryAddr,
					  keyPassphrase,
					  myKeyCertFile, 
					  caCertsPath,  
					  &num_entries,  &entries,
					  "Container registry") != REG_SUCCESS){
    printf("Search for registry of available containers failed\n");
    return 1;
  }

  if(num_entries != 1){
    printf("Search for registry of available containers failed: "
	   "returned %d entries\n", num_entries);
    return 1;
  }

  strcpy(containerAddr, entries[0].gsh);
  free(entries);
  if(Get_registry_entries_filtered_secure(containerAddr, 
					  keyPassphrase,
					  myKeyCertFile, 
					  caCertsPath,  
					  &num_entries,  
					  &entries,
					  "Container") != REG_SUCCESS){
    printf("Search for available containers failed\n");
    return 1;
  }

  if(num_entries == 0){
    printf("No containers available :-(\n");
    return 1;
  }

  printf("Available containers:\n");
  for(i=0; i<num_entries; i++){
    if( !strcmp(entries[i].service_type, "Container") ){
      printf("  %d: EPR: %s\n", i, entries[i].gsh);
    }
  }
  printf("Enter container to use [0-%d]: ",num_entries-1);
  while(1){
    if((scanf("%d", &input) == 1) && 
       (input > -1 && input < num_entries))break;
    printf("\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, entries[input].gsh);
  free(entries);

  EPR = Create_steering_service(&job, containerAddr, registryAddr,
				keyPassphrase, myKeyCertFile,
				caCertsPath);
  if(EPR){
    printf("Address of SWS = %s\n", EPR);
  }
  else{
    printf("FAILED to create SWS :-(\n");
  }
	 
  return 0;
}

/*-----------------------------------------------------------------*/

int getSecurityConfig(){

  char      *pChar;
  int        len;
  xmlDocPtr  doc;
  xmlNodePtr cur;
  xmlChar   *attrValue;
  FILE      *fp;
  char       bufline[512];

  /* Parse the RealityGrid/etc/security.conf file */
  if( !(pChar = getenv("HOME")) ){
    fprintf(stderr, "Failed to get $HOME environment variable\n");
    return REG_FAILURE;
  }
  sprintf(securityConfigFile, "%s/RealityGrid/etc/security.conf",
	  pChar);

  doc = xmlParseFile(securityConfigFile);
  if( !(cur = xmlDocGetRootElement(doc)) ){
    printf("Error parsing xml from security.conf: empty document\n");
    xmlFreeDoc(doc);
    xmlCleanupParser();
    return 1;
  }
  if (xmlStrcmp(cur->name, (const xmlChar *) "Security_config")){
    printf("Error parsing xml from security.conf: root element "
	   "is not 'Security_config'\n");
    return 1;
  }
  cur = cur->xmlChildrenNode;
  /* Walk the tree - search for first non-blank node */
  while ( cur ){
    if(xmlIsBlankNode ( cur ) ){
      cur = cur -> next;
      continue;
    }
    if( !xmlStrcmp(cur->name, (const xmlChar *)"caCertsPath") ){
      attrValue = xmlGetProp(cur, "value");
      if(attrValue){
	len = xmlStrlen(attrValue);
	strncpy(caCertsPath, (char *)attrValue, len);
	myKeyCertFile[len] = '\0';
	printf("caCertsPath >>%s<<\n", caCertsPath);
	xmlFree(attrValue);
      }
    }
    else if( !xmlStrcmp(cur->name, (const xmlChar *)"privateKeyCertFile") ){	  
      attrValue = xmlGetProp(cur, "value");
      if(attrValue){
	len = xmlStrlen(attrValue);
	strncpy(myKeyCertFile, (char *)attrValue, len);
	myKeyCertFile[len] = '\0';
	printf("myKeyCertFile >>%s<<\n", myKeyCertFile);
	xmlFree(attrValue);
      }
    }
    cur = cur -> next;
  }

  /* Extract user's DN from their certificate */
  if( !(fp = fopen(myKeyCertFile, "r")) ){

    fprintf(stderr, "Failed to open key and cert file >>%s<<\n",
	    myKeyCertFile);
    return REG_FAILURE;
  }

  userDN[0] = '\0';
  while( fgets(bufline, 512, fp) ){
    if(strstr(bufline, "subject=")){
      /* Remove trailing new-line character */
      bufline[strlen(bufline)-1] = '\0';
      pChar = strchr(bufline, '=');
      snprintf(userDN, MAX_LEN, "%s", pChar+1);
      break;
    }
  }

  printf("User's DN >>%s<<\n", userDN);

  return 0;
}
