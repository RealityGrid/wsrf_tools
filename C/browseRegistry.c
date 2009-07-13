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
#include <string.h>
#include <ReG_Steer_types.h>
#include <ReG_Steer_Browser.h>
#include <unistd.h>
#include "signal.h"
#include "configFileParser.h"

#include "libxml/xmlmemory.h"
#include "libxml/parser.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char   registryEPR[REG_MAX_STRING_LENGTH];
  char   filterString[REG_MAX_STRING_LENGTH];
  char   buf[256];
  char  *passPtr;
  int    i;
  struct registry_contents content;
  struct reg_security_info sec;
  struct tool_conf         conf;

  memset(filterString, '\0', REG_MAX_STRING_LENGTH);
  memset(registryEPR, '\0', REG_MAX_STRING_LENGTH);
  printf("\n");

  for(i=0; i<argc; i++){
    if(strstr(argv[i], "--registry=")){
      if( !(passPtr = strchr(argv[i], '=')) )continue;
     strncpy(registryEPR, ++passPtr, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--pattern=")){
      if( !(passPtr = strchr(argv[i], '=')) )continue;
     strncpy(filterString, ++passPtr, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--help")){
      printf("Usage:\n  browseRegistry [--registry=EPR of Registry] "
	     " [--pattern=pattern to filter on]\n");
      printf("\nIf either argument is not specified, the file "
	     "~/.realitygrid/tools.conf will be\nchecked for "
	     "appropriate values.\n");
      return 1;
    }
  }

  if(Get_tools_config(NULL, &conf) != REG_SUCCESS){
    printf("WARNING: Failed to read tools.conf config. file\n");
  }

  if(!registryEPR[0]){
    strncpy(registryEPR, conf.registryEPR, REG_MAX_STRING_LENGTH);
  }
  if(!filterString[0]){
    strncpy(filterString, conf.filterPattern, REG_MAX_STRING_LENGTH);
  }

  Wipe_security_info(&sec);

  if(strstr(registryEPR, "https") == registryEPR){

    if(Get_security_config(NULL, &sec)){
      printf("Failed to get security configuration\n");
      return 1;
    }

    /* Now get the user's passphrase for their key */
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
    sec.use_ssl = REG_TRUE;
  }
  else{

    /* No SSL - get the passphrase for the registry */
    snprintf(buf, 256, "Enter your username [%s]: ", getenv("USER"));
    if( !(passPtr = getpass(buf)) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    if(strlen(passPtr) > 0){
      strncpy(sec.userDN, passPtr, REG_MAX_STRING_LENGTH);
    }
    else{
      strncpy(sec.userDN, getenv("USER"), REG_MAX_STRING_LENGTH);
    }

    printf("\n");
    if( !(passPtr = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
    }
    strncpy(sec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
    sec.use_ssl = REG_FALSE;
  }

  /* Finally, we can contact the registry */
  if(filterString[0]){
    if(Get_registry_entries_filtered_secure(registryEPR, &sec,
					    &content,
					    filterString) != REG_SUCCESS){
      printf("Get_registry_entries_filtered_secure failed\n");
      return 1;
    }
  }
  else{
    if(Get_registry_entries_secure(registryEPR,
				   &sec, 
				   &content) != REG_SUCCESS){
      printf("Get_registry_entries_secure failed\n");
      return 1;
    }
  }

  printf("\n");
  printf("Entries found in %s:\n\n", registryEPR);
  for(i=0; i<content.numEntries; i++){
    printf("Entry %d - type: %s\n", i, content.entries[i].service_type);
    printf("           EPR: %s\n", content.entries[i].gsh);
    printf("     Entry EPR: %s\n", content.entries[i].entry_gsh);
    printf("           App: %s\n", content.entries[i].application);
    printf("  User & group: %s, %s\n", 
	   content.entries[i].user, content.entries[i].group);
    printf("    Start time: %s\n", content.entries[i].start_date_time);
    printf("   Description: %s\n\n", content.entries[i].job_description);
  }
  Delete_registry_table(&content);

  return 0;
}
