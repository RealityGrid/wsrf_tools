CC = gcc
C_FLAGS = -g -Wall -DWITH_OPENSSL
INCLUDE_PATH = -I/usr/include/libxml2 -I${REG_STEER_HOME}/include
LIB_FLAGS = -L${REG_STEER_HOME}/lib32 -lReG_Steer_Utils -lReG_Steer \
-lxml2 -lm -lz -lssl -lcrypto 

.SUFFIXES: .o .c

.c.o:
	${CC} ${C_FLAGS} ${INCLUDE_PATH} -c $< -o $@

all: browseRegistry createSWS createVisSWS destroySWS globalParamCreate getResourcePropertyDoc 

createSWS: createSWS.o 
	${CC} ${C_FLAGS} createSWS.o ${LIB_FLAGS} -o $@

createVisSWS: createVisSWS.o 
	${CC} ${C_FLAGS} createVisSWS.o ${LIB_FLAGS} -o $@

browseRegistry: browseRegistry.o
	${CC} ${C_FLAGS} browseRegistry.o ${LIB_FLAGS} -o $@

destroySWS: destroySWS.o
	${CC} ${C_FLAGS} destroySWS.o ${LIB_FLAGS} -o $@

globalParamCreate: globalParamCreate.o
	${CC} ${C_FLAGS} globalParamCreate.o ${LIB_FLAGS} -o $@

getResourcePropertyDoc: getResourcePropertyDoc.o
	${CC} ${C_FLAGS} getResourcePropertyDoc.o ${LIB_FLAGS} -o $@

#getResourcePropertyDocSSL.o: getResourcePropertyDocSSL.c
#	${CC} ${C_FLAGS} -DWITH_OPENSSL  ${INCLUDE_PATH} -c getResourcePropertyDocSSL.c -o getResourcePropertyDocSSL.o

#getResourcePropertyDocSSL: getResourcePropertyDocSSL.o
#	${CC} ${C_FLAGS} getResourcePropertyDocSSL.o ${LIB_FLAGS} -lssl -lcrypto -o $@

clean:
	rm -f browseRegistry createSWS createVisSWS 
	rm -f destroySWS globalParamCreate getResourcePropertyDoc
	rm -f getResourcePropertyDocSSL
	rm -f *.o
	rm -f *~
