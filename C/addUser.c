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

int main(int argc, char **argv){

  char  passphrase[256];
  char  username[256];
  char  EPR[256];
  char  msg[1024];
  struct soap mySoap;

  if(argc != 4){
    printf("Usage:\n  addUser <address of SWS> <passphrase> <username to add>\n");
    return 1;
  }
  soap_init(&mySoap);

  strncpy(EPR, argv[1], 256);
  strncpy(passphrase, argv[2], 256);
  strncpy(username, argv[3], 256);
  snprintf(msg, 1024, "<user>%s</user>", username);

  /* If address of SWS begins with 'https' then initialize SSL context */
  if( (strstr(EPR, "https") == EPR) ){

    init_ssl_context(&mySoap,
		     REG_TRUE, /* Authenticate SWS */
		     NULL,/* user's cert. & key file */
		     NULL,/* Password to read key file */
		     "/etc/grid-security/certificates");
  }

  set_resource_property(&mySoap, EPR, getenv("USER"), 
                        passphrase, msg);

  soap_end(&mySoap);
  soap_done(&mySoap);

  return 0;
}
