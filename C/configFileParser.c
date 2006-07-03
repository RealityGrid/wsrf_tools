#include <stdio.h>
#include <string.h>
#include "configFileParser.h"
#include "ReG_Steer_types.h"
#include "libxml/parser.h"

int Get_tools_config(char *file,
		     struct tool_conf *conf){
  int        len;
  xmlDocPtr  doc;
  xmlNodePtr cur;
  xmlNodePtr child;
  xmlChar   *attrValue;
  char       buf[REG_MAX_STRING_LENGTH];
  char      *pChar;

  memset(conf->registryEPR, '\0', REG_MAX_STRING_LENGTH);
  memset(conf->filterPattern, '\0', REG_MAX_STRING_LENGTH);
  memset(conf->appName, '\0', REG_MAX_STRING_LENGTH);
  memset(conf->appPasswd, '\0', REG_MAX_STRING_LENGTH);
  memset(conf->proxyAddress, '\0', REG_MAX_STRING_LENGTH);
  conf->proxyPort = 0;

  if(file){
    strncpy(buf, file, REG_MAX_STRING_LENGTH);
  }
  else{
    sprintf(buf, "%s/.realitygrid/tools.conf", getenv("HOME"));
  }

  doc = xmlParseFile(buf);
  if( !(cur = xmlDocGetRootElement(doc)) ){
    printf("Error parsing xml from %s: empty document\n", buf);
    xmlFreeDoc(doc);
    xmlCleanupParser();
    return REG_FAILURE;
  }
  if (xmlStrcmp(cur->name, (const xmlChar *) "ReGToolsConfig")){
    printf("Error parsing xml from tools.conf: root element "
           "is not 'ReGToolsConfig'\n");
    return REG_FAILURE;
  }
  cur = cur->xmlChildrenNode;

  /* Walk the tree - search for first non-blank node */
  while ( cur ){
    if(xmlIsBlankNode ( cur ) ){
      cur = cur -> next;
      continue;
    }

    if( !xmlStrcmp(cur->name, (const xmlChar *)"Registry") ){
      /* Drop down into Registry section */
      child = cur->xmlChildrenNode;
      while ( child ){
	if(xmlIsBlankNode ( child ) ){
	  child = child -> next;
	  continue;
	}

	if( !xmlStrcmp(child->name, (const xmlChar *)"address") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(conf->registryEPR, (char *)attrValue, len);
	    conf->registryEPR[len] = '\0';
	    printf("registryEPR >>%s<<\n", conf->registryEPR);
	    xmlFree(attrValue);
	  }
	}
	else if( !xmlStrcmp(child->name, (const xmlChar *)"filterPattern") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(conf->filterPattern, (char *)attrValue, len);
	    conf->filterPattern[len] = '\0';
	    printf("filterPattern >>%s<<\n", conf->filterPattern);
	    xmlFree(attrValue);
	  }
	}
	child = child->next;
      } /* while (child) */
    }
    else if( !xmlStrcmp(cur->name, (const xmlChar *)"SWSDefaults") ){
      /* Drop down into SWSDefaults section */
      child = cur->xmlChildrenNode;
      while ( child ){
	if(xmlIsBlankNode ( child ) ){
	  child = child -> next;
	  continue;
	}

	if( !xmlStrcmp(child->name, (const xmlChar *)"lifetime") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(buf, (char *)attrValue, len);
	    buf[len] = '\0';
	    conf->lifetimeMinutes = atoi(buf);
	    xmlFree(attrValue);
	  }
	}
	else if( !xmlStrcmp(child->name, (const xmlChar *)"appName") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(conf->appName, (char *)attrValue, len);
	    conf->appName[len] = '\0';
	    xmlFree(attrValue);
	  }
	}
	else if( !xmlStrcmp(child->name, (const xmlChar *)"appPasswd") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(conf->appPasswd, (char *)attrValue, len);
	    conf->appPasswd[len] = '\0';
	    xmlFree(attrValue);
	  }
	}
	else if( !xmlStrcmp(child->name, (const xmlChar *)"proxyAddress") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(buf, (char *)attrValue, len);
	    buf[len] = '\0';
	    if( (pChar = strchr(buf, ':')) ){
	      pChar++;
	      conf->proxyPort = atoi(pChar);
	      *(--pChar) = '\0';
	      strncpy(conf->proxyAddress, buf, REG_MAX_STRING_LENGTH);
	    }
	    xmlFree(attrValue);
	  }
	}
	child = child->next;
      }
    }
    else if( !xmlStrcmp(cur->name, (const xmlChar *)"CheckPointTree") ){

      attrValue = xmlGetProp(cur, "value");
      if(attrValue){
	len = xmlStrlen(attrValue);
	strncpy(conf->checkPointTree, (char *)attrValue, len);
	conf->appPasswd[len] = '\0';
	xmlFree(attrValue);
      }
    }
    cur = cur -> next;
  }

  return REG_SUCCESS;
}

int Update_tools_config(char *file,
			struct tool_conf *conf){
  return REG_SUCCESS;
}

