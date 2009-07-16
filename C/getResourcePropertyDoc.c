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

#include "ReG_Steer_Tools.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  struct soap mySoap;
  char       *rpDoc;
  char       *passPtr;
  const int   MAX_LEN = 1024;
  char        input[MAX_LEN];
  char        username[MAX_LEN];

  signal(SIGPIPE, sigpipe_handle); 

  if(argc != 2){
    printf("Usage:\n  getResourcePropertyDoc <EPR of SWS>\n");
    return 1;
  }
  snprintf(username, MAX_LEN, "%s", getenv("USER"));

  soap_init(&mySoap);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(argv[1], "https") == argv[1]) ){

    /* - don't bother with mutually-authenticated SSL
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get passphrase from command line\n");
      return 1;
    }
    strncpy(input, passPtr, MAX_LEN);
    */

    REG_Init_ssl_context(&mySoap,
			 REG_TRUE,
			 NULL,/* user's cert. & key file */
			 NULL,/* Password to read key file */
			 "/etc/grid-security/certificates");
  }

  if( !(passPtr = getpass("Enter SWS password: ")) ){

    fprintf(stderr, "Failed to get SWS password from command line\n");
    return 1;
  }

  get_resource_property_doc(&mySoap,
			    argv[1],
			    username,
			    passPtr,
			    &rpDoc);
	 
  fprintf(stdout, "\n\n%s\n\n", rpDoc);

  /* Explicitly wipe the passphrase from memory */
  memset((void *)(input), '\0', MAX_LEN);

  soap_end(&mySoap);
  soap_done(&mySoap);
  return 0;
}
