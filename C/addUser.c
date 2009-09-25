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
