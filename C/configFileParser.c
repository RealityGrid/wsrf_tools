#include <stdio.h>
#include <string.h>
#include "configFileParser.h"
#include "ReG_Steer_types.h"

int Get_tools_config(char *file,
		     struct tool_conf *conf){
  FILE *fp;
  char  buf[REG_MAX_STRING_LENGTH];
  char *pchar;
  memset(conf->registryEPR, '\0', REG_MAX_STRING_LENGTH);
  memset(conf->filterPattern, '\0', REG_MAX_STRING_LENGTH);

  if(file){
    strncpy(buf, file, REG_MAX_STRING_LENGTH);
  }
  else{
    sprintf(buf, "%s/.realitygrid/tools.conf", getenv("HOME"));
  }

  if( !(fp = fopen(buf, "r")) ){
    fprintf(stderr, "Get_tools_config: failed to open file >>%s<<\n",
	    buf);
    return REG_FAILURE;
  }

  while(fgets(buf, REG_MAX_STRING_LENGTH, fp)){

    printf("%s\n", buf);
    if( !(pchar = strchr(buf, ':')) ){
      fprintf(stderr, "Get_tools_config: line read from config file does not"
	      " contain colon >>%s<<\n", buf);
      continue;
    }

    if(strstr(buf, "topLevelRegistry")){
      strncpy(conf->registryEPR, ++pchar, REG_MAX_STRING_LENGTH);
      /* Remove trailing new-line character */
      if( (pchar = strchr(conf->registryEPR, '\n')) ){
	*pchar = '\0';
      }
    }
    else if(strstr(buf, "filterPattern")){
      strncpy(conf->filterPattern, ++pchar, REG_MAX_STRING_LENGTH);
      /* Remove trailing new-line character */
      if( (pchar = strchr(conf->filterPattern, '\n')) ){
	*pchar = '\0';
      }
    }
  }
  fclose(fp);

  return REG_SUCCESS;
}
