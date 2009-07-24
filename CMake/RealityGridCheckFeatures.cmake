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

macro(require_module rm_type rm_provides)
  if(NOT REG_MODULE_${rm_type}_${rm_provides})
    if(REG_USE_MODULAR_LIBS)
      message(FATAL_ERROR "These tools require that the "
	"ReG_Steer_${rm_type}_${rm_provides} module has been built for your "
	"RealityGrid Steering Library."
      )
    else(REG_USE_MODULAR_LIBS)
      message(FATAL_ERROR "These tools require that the ${rm_type} "
	"${rm_provides} code has been built into your RealityGrid "
	"Steering Library."
      )
    endif(REG_USE_MODULAR_LIBS)
  endif(NOT REG_MODULE_${rm_type}_${rm_provides})
endmacro(require_module)
