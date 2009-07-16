This software is the C-based utilities for use with the WSRF-based
version of the RealityGrid Steering Library

Research Computing Services, IT Services, University of Manchester.

--------------------------------------------------------------------

Prerequisites:

RealityGrid Steering Library

CMake (see below) will find the Steering library on your machine if it
has been installed in /usr/local or if you set the environment
variable REG_HOME or REG_STEER_HOME to the path containing the lib and
bin directories of the install or build.

You can also input the path by hand into CMake.

The Steering Library *must* be built with the WSRF Steering Transport
enabled, either as a module or built into a monolithic library.

CMake

The Steering library wrappers are built with an Open Source tool
called CMake available from Kitware, Inc. It is available from here:
http://www.cmake.org/ and is provided in a number of different
flavours including Win32, Mac OS X, IRIX, AIX, Linux and source code.

The Steering Library Wrappers require CMake version 2.6 or later.

----------------------------------------------------------------------

How to build and install:

Please see the instructions that come with the Steering Library for
how to use CMake.

----------------------------------------------------------------------

The WSRF Tools build options:

REG_WSRF_TOOLS_INSTALL_TO_REG_DIR - default OFF

If this is set to ON CMake will set CMAKE_INSTALL_PREFIX to match that
which was used to install the Steering Library. This will ensure that
the tools are installed to the same locations as the Steering Library.

-------------------------------------------------------------------

Certificates:

If you are using security (your container address starts with 'https')
then gsoap requires that you combine your usercert.pem and userkey.pem
into usercertandkey.pem (just cat them together, any order). All need
to be in your ~/.globus directory.

--------------------------------------------------------------------

The tools:

---------------------
addUser

  Usage:
    addUser <address of SWS> <passphrase> <username to add>

  Allow another user access to the specified SWS.  The passphrase
  securing the SWS must be specified, along with the username of the
  new user.

---------------------
browseRegistry

  Usage:
    browseRegistry [--registry=EPR of Registry]  [--pattern=pattern to filter on]

  Browse a specified registry (WSRF ServiceGroup).  If either argument
  is not specified, the file ~/.realitygrid/tools.conf will be checked
  for appropriate values.

---------------------
createChkTree

  Usage:
    createChkTree [--factory=address of checkpoint tree factory]
                  <--label=description of work to be recorded in this tree>

  Creates a new CheckpointTree using the specified factory and with a 
  label containing the specified descriptive text.  If no factory is specified 
  then the file ~/.realitygrid/tools.conf will be checked for a valid factory EPR.

---------------------
createSWS

  Usage:
    createSWS [--registry=address of registry] [--lifetime=lifetime (min)]
              [--appName=name of application] [--purpose=purpose of job] 
              [--checkpoint=EPR of starting checkpoint if any]
              [--dataSource=label of source IOType]
              [--proxy=address:port]

  Create a Steering Web Service.  This takes four mandatory arguments
  (address of the 'top level registry', run-time of the job in minutes,
  the name of the application being run and some [quoted] text
  describing its purpose) and three optional arguments. The first of these
  is the EPR of a node in a checkpoint tree from which the job is being 
  restarted. The second and third are only applicable when an ioProxy is being
  used for data IO (as opposed to files or direct socket connections). If the 
  application is to emit data via an ioProxy then it must be given the location
  of the proxy via the --proxy option.  If it is to consume data via a proxy
  then, in addition to this, the label of the data source must be specified
  using the --dataSource option. 

  If the mandatory arguments are not given on the command line, the file 
  ~/.realitygrid/tools.conf will be checked for appropriate values.

---------------------
createVisSWS

  As for createSWS but for use when the associated app. is a visualization
  and thus must be supplied with a data source.  The simulation that will
  act as a data source must be up and running before using this utility.

---------------------
destroySWS

  Usage:
    destroySWS <EPR of SWS 1> [<EPR of SWS 2>...]

  Destroys one or more specified SWSs.

---------------------
getResourceProperty

  Usage:
    getResourceProperty <EPR of SWS> <name of ResourceProperty>

  Retrieves the value of the specified ResourceProperty from the SWS at the
  specified address.

---------------------
getResourcePropertyDoc

  Usage:
    getResourcePropertyDoc <EPR of SWS>

  Retrieves the complete ResourceProperties document from the SWS at the
  specified address.

---------------------
globalParamCreate

  Usage: 
    globalParamCreate <EPR of parent>

  Use to create 'global' steered parameters for a steered couple model.  
  Takes a single argument consisting of the EPR of the parent SWS representing
  the complete coupled model.  This SWS is interrogated to get the EPRs of
  its children and its parameter defintions.  These parameters are
  then displayed to the user who can choose which to link together in order 
  to create a 'global' parameter.  Once done, the definitions of the global 
  parameters are passed back to the parent EPR.

  N.B. This requires that the parent SWS have the parameter definitions from
  all of its children which in turn requires that all the children be up
  and running before this tool is used. 

----------------------------------------------------------------------

Any comments, enquiries or pleas for explanation should be directed to
the comp-steering mailing list.  Details available from:

http://listserv.manchester.ac.uk/cgi-bin/wa?A0=COMP-STEERING
