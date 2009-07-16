/*---------------------------------------------------------------------------
  (C) Copyright 2009, University of Manchester, United Kingdom,
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

#define WITH_CDATA /* To ensure gSoap retains CDATA sections */
#include "ReG_Steer_Config.h"
#include "ReG_Steer_types.h"
#include "ReG_Steer_Browser.h"
#include "ReG_Steer_Utils.h"
#include "ReG_Steer_Steering_Transport_WSRF.h"
#include "soapH.h"

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

int get_tools_config(char *file, struct tool_conf *conf);
int update_tools_config(char *file, struct tool_conf *conf);
