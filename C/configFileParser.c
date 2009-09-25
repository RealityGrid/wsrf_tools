/*
  The RealityGrid Steering Library WSRF Tools

  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
  All rights reserved.

  This software is produced by Research Computing Services, University
  of Manchester as part of the RealityGrid project and associated
  follow on projects, funded by the EPSRC under grants GR/R67699/01,
  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
  EP/F00561X/1.

  LICENCE TERMS

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

    * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of The University of Manchester nor the names
      of its contributors may be used to endorse or promote products
      derived from this software without specific prior written
      permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

  Author: Andrew Porter
          Robert Haines
 */

#include "ReG_Steer_Tools.h"

int get_tools_config(char *file, struct tool_conf *conf) {
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
    fprintf(stderr, "get_tools_config: error parsing xml from %s: "
	    "empty document\n", buf);
    xmlFreeDoc(doc);
    xmlCleanupParser();
    return REG_FAILURE;
  }
  if (xmlStrcmp(cur->name, (const xmlChar *) "ReGToolsConfig")){
    fprintf(stderr, "get_tools_config: error parsing xml from "
	    "tools.conf: root element is not 'ReGToolsConfig'\n");
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
	    /*printf("registryEPR >>%s<<\n", conf->registryEPR);*/
	    xmlFree(attrValue);
	  }
	}
	else if( !xmlStrcmp(child->name, (const xmlChar *)"filterPattern") ){
	  attrValue = xmlGetProp(child, "value");
	  if(attrValue){
	    len = xmlStrlen(attrValue);
	    strncpy(conf->filterPattern, (char *)attrValue, len);
	    conf->filterPattern[len] = '\0';
	    /*printf("filterPattern >>%s<<\n", conf->filterPattern);*/
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

/*-----------------------------------------------------------------*/

int update_tools_config(char *file, struct tool_conf *conf) {
  return REG_SUCCESS;
}
