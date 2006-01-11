#include <stdio.h>
#include <string.h>
#include "libxml/xmlmemory.h"
#include "libxml/parser.h"
#include "securityUtils.h"
#include "ReG_Steer_types.h"

/*-----------------------------------------------------------------*/

int getSecurityConfig(struct security_info *sec){

  char      *pChar;
  int        len;
  xmlDocPtr  doc;
  xmlNodePtr cur;
  xmlChar   *attrValue;
  FILE      *fp;
  char       bufline[512];
  char       securityConfigFile[MAX_LEN];

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
	strncpy(sec->caCertsPath, (char *)attrValue, len);
	sec->myKeyCertFile[len] = '\0';
	printf("caCertsPath >>%s<<\n", sec->caCertsPath);
	xmlFree(attrValue);
      }
    }
    else if( !xmlStrcmp(cur->name, (const xmlChar *)"privateKeyCertFile") ){	  
      attrValue = xmlGetProp(cur, "value");
      if(attrValue){
	len = xmlStrlen(attrValue);
	strncpy(sec->myKeyCertFile, (char *)attrValue, len);
	sec->myKeyCertFile[len] = '\0';
	printf("myKeyCertFile >>%s<<\n", sec->myKeyCertFile);
	xmlFree(attrValue);
      }
    }
    cur = cur -> next;
  }

  /* Extract user's DN from their certificate */
  if( !(fp = fopen(sec->myKeyCertFile, "r")) ){

    fprintf(stderr, "Failed to open key and cert file >>%s<<\n",
	    sec->myKeyCertFile);
    return REG_FAILURE;
  }

  sec->userDN[0] = '\0';
  while( fgets(bufline, 512, fp) ){
    if(strstr(bufline, "subject=")){
      /* Remove trailing new-line character */
      bufline[strlen(bufline)-1] = '\0';
      pChar = strchr(bufline, '=');
      snprintf(sec->userDN, MAX_LEN, "%s", pChar+1);
      break;
    }
  }

  printf("User's DN >>%s<<\n", sec->userDN);

  return 0;
}

