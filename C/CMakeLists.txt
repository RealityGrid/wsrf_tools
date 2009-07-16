#
#  CMake build machinery for the RealityGrid WSRF tools.
#
#  (C) Copyright 2004-2009, University of Manchester, United Kingdom,
#  all rights reserved.
#
#  This software is produced by the Supercomputing, Visualization and
#  e-Science Group, Manchester Computing, University of Manchester
#  as part of the RealityGrid project (http://www.realitygrid.org),
#  funded by the EPSRC under grants GR/R67699/01 and GR/R67699/02.
#
#  LICENCE TERMS
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS MATERIAL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. THE ENTIRE RISK AS TO THE QUALITY
#  AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE
#  DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
#  CORRECTION.
#
#  Author.........: Robert Haines
#----------------------------------------------------------------------

set(REG_WSRF_COMMON_SRCS
  configFileParser.c
)

# list of targets to build.
set(REG_WSRF_TARGETS
  addUser
  browseRegistry
  createChkTree
  createSWS
  createVisSWS
  destroySWS
  getResourceProperty
  getResourcePropertyDoc
  globalParamCreate
)

# list of targets that must be linked against the common code.
set(REG_WSRF_LINK_COMMON browseRegistry createChkTree createSWS createVisSWS)

# set up link line.
# if using static libs then this is complicated due to circular dependencies.
if(REG_USE_MODULAR_LIBS)
  set(TOOLS_LINK_LINE
    ${REG_MODULE_Samples_Sockets}
    ${REG_LINK_LIBRARIES}
    ${REG_MODULE_Steering_WSRF}
    ${REG_LINK_LIBRARIES}
  )

  if(NOT REG_USE_SHARED_LIBS)
    set(TOOLS_LINK_LINE ${TOOLS_LINK_LINE} ${TOOLS_LINK_LINE})
  endif(NOT REG_USE_SHARED_LIBS)

else(REG_USE_MODULAR_LIBS)
  set(TOOLS_LINK_LINE ${REG_LINK_LIBRARIES})
endif(REG_USE_MODULAR_LIBS)

# build all the targets.
foreach(target ${REG_WSRF_TARGETS})
  list(FIND REG_WSRF_LINK_COMMON ${target} link)
  if(${link} EQUAL -1)
    add_executable(${target} ${target}.c)
  else(${link} EQUAL -1)
    add_executable(${target} ${target}.c ${REG_WSRF_COMMON_SRCS})
  endif(${link} EQUAL -1)
  target_link_libraries(${target} ${TOOLS_LINK_LINE} ${REG_EXTERNAL_LIBS})
endforeach(target ${REG_WSRF_TARGETS})

# install
install(TARGETS ${REG_WSRF_TARGETS}
  RUNTIME DESTINATION ${REG_WSRF_TOOLS_BIN_INSTALL}
)
