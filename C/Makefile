include ${REG_STEER_HOME}/Makefile.include
include ${REG_STEER_HOME}/make/Makefile.${ARCH}


INCLUDE_PATH = ${STEER_INCLUDES}
#C_FLAGS = ${C_FLAGS} -DDEBUG
LIB_FLAGS = securityUtils.o  ${STEER_LIBS} -lReG_Steer_Utils \
            -lReG_Steer ${STEER_LDFLAGS} 

.SUFFIXES: .o .c

.c.o:
	${CC} ${C_FLAGS} ${INCLUDE_PATH} -c $< -o $@

TARGETS = addUser browseRegistry createSWS createVisSWS destroySWS \
          globalParamCreate getResourcePropertyDoc

all: ${TARGETS} 

addUser: addUser.o
	${CC} ${C_FLAGS} addUser.o ${LIB_FLAGS} -o $@

createSWS: createSWS.o securityUtils.o
	${CC} ${C_FLAGS} createSWS.o ${LIB_FLAGS} -o $@

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

clean:
	rm -f browseRegistry createSWS createVisSWS 
	rm -f destroySWS globalParamCreate getResourcePropertyDoc
	rm -f addUser
	rm -f *.o
	rm -f *~

${TARGETS}: securityUtils.o
