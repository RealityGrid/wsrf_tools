CC = distcc
C_FLAGS = -g -Wall -DWITH_OPENSSL -DDEBUG
INCLUDE_PATH = -I/usr/include/libxml2 -I${REG_STEER_HOME}/include
LIB_FLAGS = securityUtils.o -L${REG_STEER_HOME}/lib32 \
            -lReG_Steer_Utils -lReG_Steer \
            -lxml2 -lm -lz -lssl -lcrypto 

.SUFFIXES: .o .c

.c.o:
	${CC} ${C_FLAGS} ${INCLUDE_PATH} -c $< -o $@

all: addUser browseRegistry createSWS createVisSWS destroySWS globalParamCreate getResourcePropertyDoc testSSL

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

testSSL: testSSL.o
	${CC} ${C_FLAGS} testSSL.o ${LIB_FLAGS} -o $@

clean:
	rm -f browseRegistry createSWS createVisSWS 
	rm -f destroySWS globalParamCreate getResourcePropertyDoc
	rm -f addUser testSSL
	rm -f *.o
	rm -f *~
