#include "ReG_Steer_types.h"

struct tool_conf {
  char registryEPR[REG_MAX_STRING_LENGTH];
  char filterPattern[REG_MAX_STRING_LENGTH];
};

int Get_tools_config(char *file,
		     struct tool_conf *conf);
