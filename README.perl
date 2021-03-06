This software is the perl-based utilities for use with the WSRF-based
version of the RealityGrid Steering Library

Research Computing Services, IT Services, University of Manchester.

--------------------------------------------------------------------

Prerequisites:

The majority of the scripts require that WSRF::Lite (available from
CPAN, http://code.google.com/p/wsrflite or
http://www.rcs.manchester.ac.uk/research/wsrflite) and its associated
dependencies be installed.  See the WSRF::Lite README for details.

You need to set this environment variable first:

export WSRF_LOCATION=/path/to/WSRF-Lite/lib

The scripts:

Due to the rather complex perl dependencies of these scripts they are
intended for use in administration rather than day-to-day activities.
The C-based tools may be better for doing the sorts of tasks that the
average user might wish to undertake.

Below we describe each of the scripts (which are listed in
alphabetical order).

---------------------

addChkNode.pl <EPR of checkpoint node to add to>
-------------
TESTING: A script for testing a checkpoint tree.  It calls the addNode
method of the supplied node and passes example XML for the checkpoint
meta-data, logged steering commands, input file and node meta-data.

addUserToEntry.pl <EPR of registry entry> <username>
-----------------
TESTING: Script to add the specified username to the list of people
able to access the specified registry entry.

appLauncher.pl
--------------
Creates a SWS for use by a steerable application.

Reads the address of the top-level registry (and any associated password)
from reg_registry_info.sh;
Queries registry for registry of containers;
Queries that registry and presents list of available containers;
User chooses a container;
Prompts user for a passphrase to protect the SWS;
Calls the factory in the chosen container to create the SWS;
Registers the new SWS with the top-level registry.

avsLauncher.pl
--------------
TESTING: a test version of visLauncher.pl

coupledAppLauncher.pl <EPR of parent> <no. of children>
---------------------
Use to create tree of SWSs for a coupled model

createChkTree.pl <URL> <CP Data> <Input file> <Meta-data>
----------------
Create a new CheckPointTree by calling the createNewTree method of the 
factory at address URL.  <Meta-data> is the description (label) to give
the tree - e.g. describing the experiment for which it will hold data.
The other two arguments can be empty ("").

createReGFramework.pl <EPR of container> [passphrase]
--------------------- 
This script sets up the registries used by the steering system.  Once
you have a WSRF::Lite container up and running then executing this
script is your next step.  Its one mandatory argument specifies the
address of the container (e.g. http://localhost:50000/) in which to
create the registries.  A passphrase to protect access to the new
registries can be specified if desired. (Note that this passphrase
will be passed over the network in clear text during this
configuration phase unless the chosen container is using SSL.)
This script reads a list of avalailable containers from the 
container_addresses.txt file and a list of available ioProxies from the 
ioproxy_addresses.txt file.  Therefore you will probably want to edit
these before running the script.

createRegistry.pl <EPR of container> [passphrase]
-----------------
Simple script to create a registry in the specified container.

createSWSResource.pl <EPR of factory> <Namespace of factory>
--------------------
Simple script to create a SWS.

destroyChkNode.pl <EPR of node> 
----------------- 
TESTING: Destroys a single node from a checkpoint tree. Any child
nodes of the destroyed node become children of its parent.  Similarly,
any log of steering commands associated with the destroyed node are
added to the logs of each of its children.

This functionality is now implemented within the Destroy method of the
CheckPointTreeNode service itself.

destroyChkTree.pl <EPR of root node>
-----------------
Destroys a complete checkpoint tree by calling the Destroy method
of the specified node.

Destroy.pl <EPR of WS-Resource to destroy>
----------
Calls Destroy on the specified service. It uses the WSRL namespace and
therefore works for a variety of types of service including SWSs and
regServiceGroupEntries.  Prompts for the passphrase used to protect
the service.

Detach.pl <EPR of SWS>
---------
Calls the Detach method of the specified Steering Web Service.  For use
in case of problems with a steering client.

getRegistryEntries.pl <EPR of registry> [registry passphrase]
---------------------
Queries the specified registry and prints out all entries.

getResourcePropertyDoc.pl <EPR of service>
-------------------------
Gets the complete ResourceProperty document from the service at the
specified endpoint.

globalParamCreate.pl <EPR of parent>
--------------------
Allows the user to construct 'global' parameters for a coupled model.
This script queries the parameters defined by each child of the supplied
service.  The user can then specify which parameters are in fact
equivalent resulting in the creation of a new, 'global' parameter for the
parent service.  This new parameter replaces all of its constituents in
the list of parameters defined by the parent service (i.e. as seen by
a steering client connecting to that service).

pruneChkTree.pl <ID or GSH of starting node>
---------------
For removing whole branches of a checkpoint tree.  Deletes every node
below (and including) the one specified.

testHarness.pl
--------------
TESTING: performs various operations, purely for testing/code development.

visLauncher.pl
--------------
Similar to appLauncher.pl but queries the top-level registry for existing 
SWSs and then prompts the user to choose which one to use as a data source.
(The chosen SWS must represent an application that is _running_.)
The script then queries the chosen SWS for its data channels and again
the user is prompted to choose the channel to use.  An SWS is then created
for a visualization job and initialized with the necessary data.

wsrf_getResourceProperties.pl <EPR of service> <Name of ResourceProperty>
-----------------------------
Query the specified service and return the value of the named 
ResourceProperty.

wsrf_insertResourceProperty.pl <EPR of service> <Name of ResourceProperty> <value>
------------------------------
Script to insert a ResourceProperty into a WS-Resource.

wsrf_ServiceGroupAddContainer.pl <ServiceGroup EPR> <Container URL> <ServiceGroup passphrase>
--------------------------------
Registers the Container with the specified ServiceGroup.

wsrf_ServiceGroupAddSG.pl <EPR of registry> <EPR of ServiceGroup to register>
-------------------------
This script adds a WS-Resource to a ServiceGroup.

wsrf_ServiceGroupAddSWS.pl <EPR of registry> <EPR of SWS>
--------------------------
This script adds an SWS to a ServiceGroup (registry).

wsrf_updateResourceProperty.pl <EPR of service> <Property name> <New value> 
------------------------------
Script to update the value of an existing ResourceProperty of a
WS-Resource.

----------------------------------------------------------------------

Any comments, enquiries or pleas for explanation should be directed to
the comp-steering mailing list.  Details available from:

http://listserv.manchester.ac.uk/cgi-bin/wa?A0=COMP-STEERING
