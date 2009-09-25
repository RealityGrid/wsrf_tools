#
#  The RealityGrid Steering Library WSRF Tools
#
#  Copyright (c) 2002-2009, University of Manchester, United Kingdom.
#  All rights reserved.
#
#  This software is produced by Research Computing Services, University
#  of Manchester as part of the RealityGrid project and associated
#  follow on projects, funded by the EPSRC under grants GR/R67699/01,
#  GR/R67699/02, GR/T27488/01, EP/C536452/1, EP/D500028/1,
#  EP/F00561X/1.
#
#  LICENCE TERMS
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#    * Neither the name of The University of Manchester nor the names
#      of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written
#      permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Robert Haines

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
