#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Steerside_WSRF.h"
#include "ReG_Steer_Utils.h"
#include <unistd.h>
#include "signal.h"
#include "configFileParser.h"

/*------------------------------------------------------------*/

void sigpipe_handle(int x) { }

void printUsage();

/*------------------------------------------------------------*/

int main(int argc, char **argv){

  int    i, input;
  struct registry_contents content;
  char  containerAddr[REG_MAX_STRING_LENGTH];
  char  registryAddr[REG_MAX_STRING_LENGTH];
  char  inputLabel[REG_MAX_STRING_LENGTH];
  char  proxyAddress[REG_MAX_STRING_LENGTH];
  char  buf[1024];
  char *EPR;
  char *pChar = NULL;
  struct reg_job_details   job;
  struct reg_security_info sec;
  struct tool_conf         conf;
  int         proxyPort;
  struct soap mySoap;

  job.userName[0] = '\0';
  snprintf(job.group, REG_MAX_STRING_LENGTH, "RSS");
  job.lifetimeMinutes = 0;
  job.software[0] = '\0';
  job.purpose[0] = '\0';
  job.inputFilename[0] = '\0';
  job.checkpointAddress[0] = '\0';
  job.passphrase[0] = '\0';
  registryAddr[0] = '\0';
  inputLabel[0] = '\0';
  proxyAddress[0] = '\0';

  Wipe_security_info(&sec);

  if( (argc == 1) ){
    printUsage();
    return 1;
  }

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
    else if(strstr(argv[i], "--checkpoint=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(job.checkpointAddress, ++pChar, REG_MAX_STRING_LENGTH);
    }
    else if(strstr(argv[i], "--dataSource=")){
      if( !(pChar = strchr(argv[i], '=')) )continue;
      strncpy(inputLabel, ++pChar, REG_MAX_STRING_LENGTH);
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

  if(Get_tools_config(NULL, &conf) != REG_SUCCESS){
    printf("WARNING: Failed to read tools.conf config. file\n");
  }

  if(registryAddr[0] == '\0'){
    if(conf.registryEPR[0]){
      strncpy(registryAddr, conf.registryEPR, REG_MAX_STRING_LENGTH);
    }
    else{
      printf("No registry address supplied on cmd line or in config file. ");
      printUsage();
      return 1;
    }
  }
  if(!job.lifetimeMinutes){
    if(conf.lifetimeMinutes){
      job.lifetimeMinutes = conf.lifetimeMinutes;
    }
    else{
      printf("No job lifetime supplied on cmd line or in config file. ");
      printUsage();
      return 1;
    }
  }
  if(job.software[0] == '\0'){
    if(conf.appName[0]){
      strncpy(job.software, conf.appName, REG_MAX_STRING_LENGTH);
    }
    else{
      printf("No application name supplied on cmd line or in config file. ");
      printUsage();
      return 1;
    }
  }
  if(job.purpose[0] == '\0'){
    printf("No job purpose supplied. ");
    printUsage();
    return 1;
  }

  if(strstr(registryAddr, "https") == registryAddr){

    sec.use_ssl = 1;

    /* Read the location of certs etc. into global variables */
    if(Get_security_config(NULL, &sec) != REG_SUCCESS){
      printf("Failed to get security configuration\n");
      return 1;
    }
    snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", sec.userDN);

    /* Now get the user's passphrase for their key */
    if( !(pChar = getpass("Enter passphrase for key: ")) ){

      printf("Failed to get key passphrase from command line\n");
      return 1;
    }
    strncpy(sec.passphrase, pChar, REG_MAX_STRING_LENGTH);
  }
  else{
    /* Registry is not using SSL... */
    sec.use_ssl = 0;

    snprintf(buf, 1024, "Enter your username for registry [%s]: ", 
	     getenv("USER"));
    if( !(pChar = getpass(buf)) ){
      printf("Failed to get username from command line\n");
      return 1;
    }
    printf("\n");
    if(strlen(pChar) == 0){
      snprintf(sec.userDN, REG_MAX_STRING_LENGTH, "%s", getenv("USER"));
      snprintf(job.userName, REG_MAX_STRING_LENGTH, "%s", getenv("USER"));
    }
    else{
      strncpy(sec.userDN, pChar, REG_MAX_STRING_LENGTH);    
      strncpy(job.userName, pChar, REG_MAX_STRING_LENGTH);
    }

    if( !(pChar = getpass("Enter passphrase for registry: ")) ){
      printf("Failed to get registry passphrase from command line\n");
      return 1;
    }
    printf("\n");
    strncpy(sec.passphrase, pChar, REG_MAX_STRING_LENGTH);
  }

  /* Look up available Containers */
  if(Get_registry_entries_filtered_secure(registryAddr,
					  &sec, &content,
					  "Container registry") != REG_SUCCESS){
    printf("Search for registry of available containers failed\n");
    return 1;
  }

  if(content.numEntries != 1){
    printf("Search for registry of available containers failed: "
	   "returned %d entries\n", content.numEntries);
    return 1;
  }

  strncpy(containerAddr, content.entries[0].gsh, REG_MAX_STRING_LENGTH);
  Delete_registry_table(&content);

  if(Get_registry_entries_filtered_secure(containerAddr,
					  &sec, 
					  &content,
					  "Container") != REG_SUCCESS){
    printf("Search for available containers failed\n");
    return 1;
  }

  if(content.numEntries == 0){
    printf("No containers available :-(\n");
    return 1;
  }

  printf("Available containers:\n");
  for(i=0; i<content.numEntries; i++){
    if( !strcmp(content.entries[i].service_type, "Container") ){
      printf("  %d: EPR: %s\n", i, content.entries[i].gsh);
    }
  }
  printf("Enter container to use [0-%d]: ",content.numEntries-1);
  while(1){
    if((scanf("%d", &input) == 1) && 
       (input > -1 && input < content.numEntries))break;
    printf("\nInvalid choice, please select container: ");
  }
  strcpy(containerAddr, content.entries[input].gsh);
  Delete_registry_table(&content);

  EPR = Create_steering_service(&job, containerAddr,
				registryAddr, &sec);
  if(EPR){
    printf("\nAddress of SWS = %s\n", EPR);
  }
  else{
    printf("\nFAILED to create SWS :-(\n");
  }

  /* Finally, set it up with information on the data proxy if
     required */
  if(proxyAddress[0] != '\0'){
    i = snprintf(buf, 1024, "<dataSink><Proxy><address>%s</address>"
		 "<port>%d</port></Proxy></dataSink>",
		 proxyAddress, proxyPort);

    if(inputLabel[0]){
      snprintf(&(buf[i]), 1024, "<dataSource><Proxy><address>%s"
	       "</address><port>%d</port></Proxy><sourceLabel>%s"
	       "</sourceLabel></dataSource>",
	       proxyAddress, proxyPort, inputLabel);
    }

    soap_init(&mySoap);
    if(Set_resource_property(&mySoap, EPR, job.userName, job.passphrase,
			     buf) != REG_SUCCESS){
      fprintf(stderr, "Failed to initialize SWS with info. on data proxy :-(");

      if(Destroy_WSRP(EPR, &sec) == REG_SUCCESS){
	fprintf(stderr, "  => Destroyed %s\n", EPR);
      }
      else{
	fprintf(stderr, "    Also failed to clean-up the SWS %s\n", EPR);
      }
      soap_end(&mySoap);
      soap_done(&mySoap);
      return 1;
    }
    else{
      printf("\nSWS initialized with address of proxy OK :-)\n\n");
    }

    soap_end(&mySoap);
    soap_done(&mySoap);
  } /* end if(proxyAddress[0] != '\0') */

  return 0;
}

/*-------------------------------------------------------------------*/

void printUsage(){
  printf("Usage:\n"
	 "  createSWS --registry=address_of_registry"
	 " --lifetime=lifetime (min) --appName=name_of_application"
	 " --purpose=purpose_of_job [--passwd=passphrase_to_give_SWS]"
	 " [--checkpoint=checkpoint_EPR] [--dataSource=label_of_data_source]"
	 " [--proxy=address:port]\n");
}
