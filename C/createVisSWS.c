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

void printUsage();

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  char  containerAddr[REG_MAX_STRING_LENGTH];
  char  registryAddr[REG_MAX_STRING_LENGTH];
  char  proxyAddress[REG_MAX_STRING_LENGTH];
  char  dataSource[REG_MAX_STRING_LENGTH];
  char  iodef_label[REG_MAX_STRING_LENGTH];
  char *EPR;
  char *passPtr;
  char *pChar;
  int                      i, j, count;
  int                      proxyPort, status;
  struct registry_contents content;
  struct reg_job_details   job;
  struct reg_security_info registrySec;
  struct reg_security_info jobSec;
  struct reg_iotype_list   iotypeList;
  struct tool_conf         conf;

  Wipe_security_info(&registrySec);
  Wipe_security_info(&jobSec);

  if(argc == 1){
    printUsage();
    return 1;
  }

  snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", getenv("USER"));
  snprintf(job.group, REG_MAX_STRING_LENGTH, "RSS");
  job.lifetimeMinutes = 0;
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';
  registryAddr[0] = '\0';
  proxyAddress[0] = '\0';
  iodef_label[0] = '\0';

  for(i=0; i<argc; i++){
    if(strstr(argv[i], "--registry=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
     strncpy(registryAddr, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--lifetime=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      sscanf(++pChar, "%d", &(job.lifetimeMinutes));
    }
    else if(strstr(argv[i], "--appName=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(job.software, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--purpose=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(job.purpose, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--passwd=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(job.passphrase, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--proxy=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(proxyAddress, ++pChar, REG_MAX_STRING_LENGTH);
      if( !(pChar = strchr(proxyAddress, ':')) )continue;
      proxyPort = atoi(++pChar);
      pChar--; *pChar = '\0'; /* Terminate proxyAddress */
      printf("Using IOProxy on %s, port %d\n", proxyAddress, proxyPort);
    }
  }

  if(get_tools_config(NULL, &conf) != REG_SUCCESS){
    printf("WARNING: Failed to read tools.conf config. file\n");
  }

  if(registryAddr[0] == '\0'){
    if(conf.registryEPR[0]){
      strncpy(registryAddr, conf.registryEPR, REG_MAX_STRING_LENGTH);
    }
    else{
      printf("No registry address supplied. ");
      printUsage();
      return 1;
    }
  }
  else if(!job.lifetimeMinutes){
    if(conf.lifetimeMinutes){
      job.lifetimeMinutes = conf.lifetimeMinutes;
    }
    else{
      printf("No job lifetime supplied. ");
      printUsage();
      return 1;
    }
  }
  else if(job.software[0] == '\0'){
    if(conf.appName[0]){
      strncpy(job.software, conf.appName, REG_MAX_STRING_LENGTH);
    }
    else{
      printf("No application name supplied. ");
      printUsage();
      return 1;
    }
  }
  else if(job.purpose[0] == '\0'){
    printf("No job purpose supplied. ");
    printUsage();
    return 1;
  }

  if(strstr(registryAddr, "https") == registryAddr){

    registrySec.use_ssl = REG_TRUE;

    /* Read the location of certs etc. into global variables */
    if(Get_security_config(NULL, &registrySec)){
      printf("Failed to get security configuration\n");
      return 1;
    }
    snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", registrySec.userDN);

    /* Now get the user's passphrase for their key */
    if( !(passPtr = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    strncpy(registrySec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
  }
  else{
    registrySec.use_ssl = REG_FALSE;

    if( !(passPtr = getpass("Enter your username for registry: ")) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(registrySec.userDN, passPtr, REG_MAX_STRING_LENGTH);    
    
    if( !(passPtr = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
    }
    strncpy(registrySec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
  }
  printf("\n");

  /* Look for available SWSs and get user to choose which one to
     use as a data source */
  if(Get_registry_entries_filtered_secure(registryAddr,
					  &registrySec,  
					  &content,
					  "SWS") != REG_SUCCESS){
    fprintf(stderr, "\nNo jobs to use as data source found in registry!\n");
    return 1;
  }
  printf("\nAvailable jobs:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "SWS") ){
      printf("  %d:      EPR: %s\n", i, content.entries[i].gsh);
      printf("           App: %s\n", content.entries[i].application);
      printf("  User & group: %s, %s\n", 
	     content.entries[i].user, content.entries[i].group);
      printf("    Start time: %s\n", content.entries[i].start_date_time);
      printf("   Description: %s\n\n", content.entries[i].job_description);
    }
  }
  fprintf(stdout, "Select job to use as data source [0-%d]: ",
	  content.numEntries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < content.numEntries))break;
    fprintf(stderr, "\nInvalid choice, please select job [0-%d]: ", 
	    content.numEntries-1);
  }
  strncpy(dataSource, content.entries[count].gsh, REG_MAX_STRING_LENGTH);
  Delete_registry_table(&content);

  if(strstr(dataSource, "https") == dataSource){

    /* Read the location of certs etc. into global variables */
    if(Get_security_config(NULL, &jobSec)){
      printf("Failed to get security configuration\n");
      return 1;
    }
  }
  else{
    /* Ask the user to specify the (WSSE) password for access to 
       this SWS */
    if( !(passPtr = getpass("Enter password for this SWS: ")) ){

      printf("Failed to get password from command line\n");
      return 1;
    }
    strncpy(jobSec.passphrase, passPtr, REG_MAX_STRING_LENGTH);
    strncpy(job.passphrase, passPtr, REG_MAX_STRING_LENGTH);
    strncpy(jobSec.userDN, getenv("USER"), REG_MAX_STRING_LENGTH);    
  }

  /* Obtain the IOTypes from the data source */
  Get_IOTypes(dataSource, &jobSec, &iotypeList);

  if( iotypeList.numEntries < 1 ){
    fprintf(stderr, "Got no IOType definitions from data source\n");
    return 1;
  }

  fprintf(stdout, "Available IOTypes:\n");
  count = 0;
  for(i=0; i<iotypeList.numEntries; i++){
    if(iotypeList.iotype[i].direction == REG_IO_OUT){
      fprintf(stdout, "  %d: %s\n", count, iotypeList.iotype[i].label);
      count++;
    }
  }
  count--;

  fprintf(stdout, "\nEnter IOType to use as data source [0-%d]: ", count);
  while(1){
    if(scanf("%d", &i) == 1)break;
  }
  fprintf(stdout, "\n");

  count = 0;
  for(j=0; j<iotypeList.numEntries; j++){
    if(iotypeList.iotype[j].direction == REG_IO_OUT){
      if(count == i){
	strncpy(iodef_label, iotypeList.iotype[j].label, 
		REG_MAX_STRING_LENGTH);
	break;
      }
      count++;
    }
  }
  Delete_iotype_list(&iotypeList);

  /* Get the list of available Containers and ask the user to 
     choose one */
  if(Get_registry_entries_filtered_secure(registryAddr, 
					  &registrySec,
					  &content, 
					  "Container registry") != REG_SUCCESS){
    fprintf(stderr, 
	    "Search for registry of available containers failed\n");
    return 1;
  }

  if(content.numEntries != 1){
    fprintf(stderr, "Search for registry of available containers failed: "
	    "returned %d entries\n", content.numEntries);
    return 1;
  }

  strcpy(containerAddr, content.entries[0].gsh);
  Delete_registry_table(&content);

  if(Get_registry_entries_filtered_secure(containerAddr,
 					  &registrySec,
					  &content, "Container") != REG_SUCCESS){
    fprintf(stderr, "Search for available containers failed\n");
    return 1;
  }

  if(content.numEntries == 0){
    fprintf(stderr, "No containers available :-(\n");
    return 1;
  }

  fprintf(stdout, "Available containers:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "Container") ){
      fprintf(stdout, "  %d: EPR: %s\n", i, content.entries[i].gsh);
    }
  }
  printf("\nEnter container to use [0-%d]: ",content.numEntries-1);
  while(1){
    if((scanf("%d", &count) == 1) && 
       (count > -1 && count < content.numEntries))break;
    fprintf(stderr, "\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, content.entries[count].gsh);
  Delete_registry_table(&content);

  /* Now create SWS for the vis */
  if( !(EPR = Create_steering_service(&job, containerAddr, 
				      registryAddr, &registrySec)) ){
    printf("FAILED to create SWS for %s :-(\n", job.software);
    return 1;
  }
  fprintf(stdout, "\nAddress of SWS = %s\n", EPR);

  /* Finally, set it up with information on the data source*/
  if(proxyAddress[0] == '\0'){
    /* No proxy being used */
    status = Set_service_data_source(EPR, dataSource, 0, 
				     iodef_label, &jobSec);
  }
  else{
    status = Set_service_data_source(EPR, proxyAddress, proxyPort, 
				     iodef_label, &jobSec);
  }

  if(status != REG_SUCCESS){

    fprintf(stderr, "Failed to initialize SWS with info. on data source :-(");

    if(destroy_WSRP(EPR, &jobSec) == REG_SUCCESS){
      fprintf(stderr, "  => Destroyed %s\n", EPR);
    }
    else{
      fprintf(stderr, "    Also failed to clean-up the SWS %s\n", EPR);
    }

    return 1;
  }

  return 0;
}

/*-------------------------------------------------------------------*/

void printUsage(){
  printf("Usage:\n"
	 "  createVisSWS --registry=address_of_registry"
	 " --lifetime=lifetime (min) --appName=name_of_application"
	 " --purpose=purpose_of_job [--passwd=passphrase_to_give_SWS]"
	 " [--dataSource=label_of_data_source] [--proxy=address:port]\n");
}
