#include "ReG_Steer_types.h"

struct tool_conf {
  char registryEPR[REG_MAX_STRING_LENGTH];
  char filterPattern[REG_MAX_STRING_LENGTH];
  int  lifetimeMinutes;
  char appName[REG_MAX_STRING_LENGTH];
  char appPasswd[REG_MAX_STRING_LENGTH];
  char proxyAddress[REG_MAX_STRING_LENGTH];
  int  proxyPort;
  char checkPointTree[REG_MAX_STRING_LENGTH];
};

int Get_tools_config(char *file,
		     struct tool_conf *conf);
