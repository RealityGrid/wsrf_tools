#include <stdio.h>
#include <string.h>
#include <ReG_Steer_types.h>
#include <ReG_Steer_Browser.h>
#include <unistd.h>
#include "signal.h"

#include "libxml/xmlmemory.h"
#include "libxml/parser.h"
/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char   registryEPR[128];
  char   securityConfigFile[256];
  char   caCertsPath[256]; 
  char   myKeyCertFile[256];
  char  *passPtr;
  char  *homeDir;
  int    i, len;
  int    num_entries;
  struct registry_entry *entries;

  xmlDocPtr  doc;
  xmlNodePtr cur;
  xmlChar   *attrValue;

  if(argc < 2 || argc > 3){
    printf("Usage:\n  browseRegistry <EPR of Registry "
	   "(ServiceGroup)> [<pattern to filter on>]\n");
    return 1;
  }
  strncpy(registryEPR, argv[1], 128);

  if(argc != 3){

    if(strstr(registryEPR, "https") == registryEPR){

      /* Parse the RealityGrid/etc/security.conf file */
      homeDir = getenv("HOME");
      sprintf(securityConfigFile, "%s/RealityGrid/etc/security.conf",
	      homeDir);

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

      /* Now get the user's passphrase for their key */
      if( !(passPtr = getpass("Enter passphrase for key: ")) ){

	printf("Failed to get key passphrase from command line\n");
	return 1;
      }

      /* Finally, we can contact the registry */
      if(Get_registry_entries_secure(registryEPR, 
				     passPtr,
				     myKeyCertFile,
				     caCertsPath,
				     &num_entries,  
				     &entries) != REG_SUCCESS){
	printf("Get_registry_entries_secure failed\n");
	return 1;
      }
    }
    else{
      if(Get_registry_entries_secure(registryEPR, "","","",&num_entries,  
				     &entries) != REG_SUCCESS){
	printf("Get_registry_entries_secure failed\n");
	return 1;
      }
    }
  }
  else{

    if(Get_registry_entries_filtered(registryEPR, &num_entries,  
				     &entries,
				     argv[2]) != REG_SUCCESS){
      printf("Get_registry_entries_filtered failed\n");
      return 1;
    }
  }

  for(i=0; i<num_entries; i++){
    printf("Entry %d - type: %s\n", i, entries[i].service_type);
    printf("           EPR: %s\n", entries[i].gsh);
    printf("     Entry EPR: %s\n", entries[i].entry_gsh);
    printf("           App: %s\n", entries[i].application);
    printf("          user: %s, %s\n", entries[i].user, entries[i].group);
    printf("    Start time: %s\n", entries[i].start_date_time);
    printf("   Description: %s\n\n", entries[i].job_description);
  }
  free(entries);
  return 0;
}
