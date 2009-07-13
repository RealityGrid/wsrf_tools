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
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils_WSRF.h"

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int i;
  struct reg_security_info sec;
  Wipe_security_info(&sec);

  if(argc < 3 || ((argc-1)%2 != 0) ){
    printf("Usage:\n  destroySWS <EPR of SWS 1> <passphrase of SWS 1> "
	   "[<EPR of SWS 2> <passphrase of SWS2>...]\n");
    printf("\ne.g.: ./destroySWS http://localhost:5000/854884847 secretsanta\n");
    printf("or, if the service has no passphrase: ./destroySWS "
	   "http://localhost:5000/854884847 \"\" \n\n");
    return 1;
  }
  printf("\n");

  strncpy(sec.userDN, getenv("USER"), REG_MAX_STRING_LENGTH);
  sec.use_ssl = 0;

  for(i=1; i<argc; i+=2){

    strncpy(sec.passphrase, argv[i+1], REG_MAX_STRING_LENGTH);
    if(Destroy_WSRP(argv[i], &sec) == REG_SUCCESS){
      printf("Destroyed %s\n", argv[i]);
    }
  }
  printf("\n");
	 
  return 0;
}
