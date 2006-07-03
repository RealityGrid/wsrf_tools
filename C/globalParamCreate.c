/*---------------------------------------------------------------------------
  (C) Copyright 2006, University of Manchester, United Kingdom,
  all rights reserved.

  This software was developed by the RealityGrid project
  (http://www.realitygrid.org), funded by the EPSRC under grants
  GR/R67699/01 and GR/R67699/02.

  LICENCE TERMS

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  THIS MATERIAL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. THE ENTIRE RISK AS TO THE QUALITY
  AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE
  DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
  CORRECTION.
---------------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "soapH.h"

/*----------------------------------------------------------*/

int main(int argc, char **argv){

  const int            MAX_LEN = 256;
  char                *parentEPR;
  char                *paramDefs;
  char                *pchar;
  char                *pend;
  char                *childrenTxt;
  char                *appName;
  char                *passPtr;
  struct soap          mySoap;
  struct msg_struct   *msg;
  struct param_struct *param_ptr;
  const int            MAX_CHILDREN = 10;
  char                 childEPR[MAX_CHILDREN][MAX_LEN];
  char                 paramSet[MAX_CHILDREN][MAX_LEN];
  const int            MAX_PARAMS = 30;
  struct param_struct *childParams[MAX_CHILDREN][MAX_PARAMS];
  char                 nameTxt[MAX_LEN];
  char                *username;
  char                 couplingConfig[1024*1024];
  int                  count;
  int                  childParamCount[MAX_CHILDREN];
  int                  i, j, numInSet;
  struct wsrp__SetResourcePropertiesResponse response;

  if( argc != 3 ){
    printf("Usage: globalParamCreate <EPR of parent> <username>\n");
    return 1;
  }
  parentEPR = argv[1];
  username = argv[2];

  if( !(passPtr = getpass("Enter SWS password for parent: ")) ){

    printf("Failed to get SWS password from command line\n");
    return 1;
  }

  soap_init(&mySoap);
  if( Get_resource_property (&mySoap,
                             parentEPR,
			     username,
			     passPtr,
                             "paramDefinitions",
                             &paramDefs) != REG_SUCCESS ){

    printf("Call to get paramDefinitions ResourceProperty on %s failed\n",
           parentEPR);
    return 1;
  }

  printf("Parameter definitions:\n%s\n", paramDefs);

  if( !(pchar = strstr(paramDefs, "<sws:paramDefinitions")) ){
    printf("Got no paramDefinitions from %s (is job running?)\n",
	   parentEPR);
    return 1;
  }

  if( !(pchar = strstr(paramDefs, "<ReG_steer_message")) ){
    printf("paramDefinitions does not contain '<ReG_steer_message' :-(\n");
    return 1;
  }
  pend = strstr(pchar, "</sws:paramDefinitions>");
  *pend = '\0'; /* Terminate string early so parser doesn't see the 
		   paramDefinitions closing tag */

  msg = New_msg_struct();
  Parse_xml_buf(pchar, strlen(pchar), msg, NULL);
  *pend = '<'; /* Remove early terminating character in case it hinders
		  clean-up */
  Print_msg(msg);
  if(msg->msg_type != PARAM_DEFS){
    printf("Error, result of parsing paramDefinitions is NOT a "
	   "PARAM_DEFS message\n");
    return 1;
  }
  if( !(msg->status) || !(msg->status->first_param)){
    printf("Error, message has no param elements\n");
    return 1;
  }

  /* Now get details of the parent's children */
  if( Get_resource_property (&mySoap,
                             parentEPR,
			     username,
			     passPtr,
                             "childService",
                             &childrenTxt) != REG_SUCCESS ){

    printf("Call to get childService ResourceProperty on %s failed\n",
           parentEPR);
    return 1;
  }
  printf("Children:\n%s\n", childrenTxt);

  if( !(pchar = strstr(childrenTxt, "<sws:childService")) ){

    printf("No children found :-(\n");
    return 1;
  }

  count = 0;
  while(pchar && (count < MAX_CHILDREN)){
    pchar = strchr(pchar, '>');
    pchar++;
    pend = strchr(pchar, '<');
    strncpy(childEPR[count], pchar, (pend-pchar));
    childEPR[count][(pend-pchar)] = '\0';
    count++;
    pchar = strstr(pend, "<sws:childService");
  }

  /* Loop over children */
  for(i=0; i<count; i++){
    printf("Child %d EPR = %s\n", i, childEPR[i]);

    if( Get_resource_property (&mySoap,
			       childEPR[i],
			       username,
			       passPtr,
			       "applicationName",
			       &appName) != REG_SUCCESS ){

      printf("Call to get applicationName ResourceProperty on "
	     "child %s failed\n", childEPR[i]);
      return 1;
    }
    if( !(pchar = strstr(appName, "<sws:applicationName")) ){

      printf("applicationName RP does not contain "
	     "'<sws:applicationName'\n");
      return 1;
    }
    pchar = strchr(pchar, '>');
    pchar++;
    pend = strchr(pchar, '<');
    *pend = '\0';
    printf("       name = >>%s<<\n", pchar);
    sprintf(nameTxt, "%s/", pchar);
    *pend = '<';

    param_ptr = msg->status->first_param;
    childParamCount[i] = 0;
    while(param_ptr){


      /* We don't want internal parameters */
      if(!xmlStrcmp(param_ptr->is_internal, (const xmlChar *)"TRUE")){
	param_ptr = param_ptr->next;
	continue;
      }

      /* Nor do we want monitored parameters */
      if(!xmlStrcmp(param_ptr->steerable, (const xmlChar *)"0")){
	param_ptr = param_ptr->next;
	continue;
      }

      /* Check to see whether this parameter is from the current
	 child - if it is then it will have the application name and
         a forward slash prepended to its label */
      if(strstr((char *)(param_ptr->label), nameTxt) ==
	 (char *)(param_ptr->label) ){

	childParams[i][childParamCount[i]] = param_ptr;
	childParamCount[i]++;

	fprintf(stderr, "Param no. %d:\n", childParamCount[i]);
	if(param_ptr->handle) fprintf(stderr, "   Handle = %s\n", 
				  (char *)(param_ptr->handle));
	if(param_ptr->label) fprintf(stderr, "   Label  = %s\n", 
				  (char *)(param_ptr->label));
	if(param_ptr->value)      fprintf(stderr, "   Value  = %s\n", 
					(char *)(param_ptr->value));
	if(param_ptr->steerable)  fprintf(stderr, "   Steerable = %s\n", 
					(char *)(param_ptr->steerable));
	if(param_ptr->type)       fprintf(stderr, "   Type   = %s\n", 
					(char *)(param_ptr->type));
	if(param_ptr->is_internal)fprintf(stderr, "   Internal = %s\n", 
					(char *)(param_ptr->is_internal));
      }
      param_ptr = param_ptr->next;
    }
  }

  /* Now loop over parameter sets from each child and allow
     user to construct a set of parameters that are in fact
     global. */
  pend = couplingConfig;
  pend += sprintf(pend, "<couplingConfig>\n<Global_param_list>\n");

  while(1){
    numInSet = 0;

    /* Loop over children */
    for(i=0; i<count; i++){
      printf("EPR = %s\n", childEPR[i]);
      for(j=0; j<childParamCount[i]; j++){
	printf("  Label %d = %s\n", j, (char*)(childParams[i][j]->label));
      }

      printf("Select parameter to add to set or <return> for none: ");

      if(scanf("%d", &j) != 1){
	continue;
      }

      strcpy(paramSet[numInSet++], childEPR[i]);
      strcpy(paramSet[numInSet++], (char*)(childParams[i][j]->label));
    }

    printf("Set consists of: \n");
    for(i=0; i<numInSet; i+=2){
      printf("%s: %s\n", paramSet[i], paramSet[i+1]);
    }
    printf("\nEnter name for this set/global parameter: ");
    scanf("%255s", nameTxt);
    pend += sprintf(pend, "  <Global_param name=\"%s\">\n", nameTxt);
    for(i=0; i<numInSet; i+=2){
      pend += sprintf(pend, "<Child_param id=\"%s\" label=\"%s\"/>\n", 
		      paramSet[i], paramSet[i+1]);
    }
    pend += sprintf(pend, "  </Global_param>\n");

    printf("\nConstruct another set (y/n)? ");
    while(1){
      scanf("%c", nameTxt);
      if(nameTxt[0] != '\n' && nameTxt[0] != ' ')break;
    }
    if (nameTxt[0] == 'n' || nameTxt[0] == 'N') break;
    printf("\n");
  }
  sprintf(pend, "</Global_param_list>\n</couplingConfig>\n");

  printf("Coupling config:\n%s\n", couplingConfig);

  if(soap_call_wsrp__SetResourceProperties(&mySoap, parentEPR, 
					   "", couplingConfig, 
					   &response) != SOAP_OK){
    soap_print_fault(&mySoap, stderr);
    return 1;
  }

  Delete_msg_struct(&msg);
  soap_end(&mySoap);
  soap_done(&mySoap);

  printf("Done\n");

  return 0;
}
