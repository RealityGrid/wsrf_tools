include ${REG_STEER_HOME}/Makefile.include
include ${REG_STEER_HOME}/make/Makefile.${ARCH}


INCLUDE_PATH = ${STEER_INCLUDES}
LIB_FLAGS = securityUtils.o  ${STEER_LIBS} -lReG_Steer_Utils \
            -lReG_Steer ${STEER_LDFLAGS} 

.SUFFIXES: .o .c

# Have to make sure we define the REG_WITH_OPENSSL flag as set when
# building library because these utilites use gSoap directly and
# thus it is essential that WITH_OPENSSL is defined consistently.
.c.o:
	${CC} ${C_FLAGS} -DREG_WITH_OPENSSL=${REG_WITH_OPENSSL_FLAG} \
${INCLUDE_PATH} -c $< -o $@

TARGETS = addUser browseRegistry createSWS createSWSProxy createVisSWS \
          destroySWS \
          globalParamCreate getResourcePropertyDoc getResourceProperty \
          testSteerLib

all: ${TARGETS} 

addUser: addUser.o
	${CC} ${C_FLAGS} addUser.o ${LIB_FLAGS} -o $@

createSWS: createSWS.o securityUtils.o
	${CC} ${C_FLAGS} createSWS.o ${LIB_FLAGS} -o $@

createSWSProxy: createSWSProxy.o 
	${CC} ${C_FLAGS} createSWSProxy.o ${LIB_FLAGS} -o $@

createVisSWS: createVisSWS.o securityUtils.o
	${CC} ${C_FLAGS} createVisSWS.o ${LIB_FLAGS} -o $@

browseRegistry: browseRegistry.o securityUtils.o
	${CC} ${C_FLAGS} browseRegistry.o ${LIB_FLAGS} -o $@

destroySWS: destroySWS.o
	${CC} ${C_FLAGS} destroySWS.o ${LIB_FLAGS} -o $@

globalParamCreate: globalParamCreate.o
	${CC} ${C_FLAGS} globalParamCreate.o ${LIB_FLAGS} -o $@

getResourcePropertyDoc: getResourcePropertyDoc.o
	${CC} ${C_FLAGS} getResourcePropertyDoc.o ${LIB_FLAGS} -o $@

getResourceProperty: getResourceProperty.o
	${CC} ${C_FLAGS} getResourceProperty.o ${LIB_FLAGS} -o $@

#testSteerLib: testSteerLib.o
#	${CC} ${C_FLAGS} testSteerLib.o ${LIB_FLAGS} -o $@

clean:
	rm -f browseRegistry createSWS createVisSWS 
	rm -f destroySWS globalParamCreate getResourcePropertyDoc
	rm -f addUser getResourceProperty testSteerLib
	rm -f *.o
	rm -f *~

${TARGETS}: securityUtils.o
