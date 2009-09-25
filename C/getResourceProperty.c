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
