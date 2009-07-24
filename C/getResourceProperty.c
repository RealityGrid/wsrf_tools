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

  const int   MAX_LEN = 1024;
  struct soap mySoap;
  char       *passPtr;
  /*char        input[MAX_LEN];*/
  char        rpName[MAX_LEN];
  char        username[MAX_LEN];
  char       *rpOut;

  signal(SIGPIPE, sigpipe_handle); 

  if(argc != 3){
    printf("Usage:\n  getResourceProperty <EPR of SWS> <name of RP>\n");
    return 1;
  }
  strncpy(rpName, argv[2], MAX_LEN);
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

    init_ssl_context(&mySoap,
		     REG_TRUE,
		     NULL,/* user's cert. & key file */
		     NULL,/* Password to read key file */
		     "/etc/grid-security/certificates");
  }

  if( !(passPtr = getpass("Enter SWS password: ")) ){

    printf("Failed to get SWS password from command line\n");
    return 1;
  }


  get_resource_property (&mySoap,
			 argv[1],
			 username,
			 passPtr,
			 rpName,
			 &rpOut);
	 
  fprintf(stdout, "Resource property %s:\n>>%s<<\n", rpName, rpOut);

  /* Explicitly wipe the passphrase from memory
     memset((void *)(input), '\0', MAX_LEN);*/

  soap_end(&mySoap);
  soap_done(&mySoap);
  return 0;
}
