CC = gcc
C_FLAGS = -g
INCLUDE_PATH = -I/usr/include/libxml2 -I${REG_STEER_HOME}/include
LIB_FLAGS = -L${REG_STEER_HOME}/lib32 -lReG_Steer_Utils -lReG_Steer -lxml2 -lm -lz

.SUFFIXES: .o .c

.c.o:
	${CC} ${C_FLAGS} ${INCLUDE_PATH} -c $< -o $@

all: createSWS browseRegistry destroySWS createVisSWS

createSWS: createSWS.o 
	${CC} ${C_FLAGS} createSWS.o ${LIB_FLAGS} -o $@

createVisSWS: createVisSWS.o 
	${CC} ${C_FLAGS} createVisSWS.o ${LIB_FLAGS} -o $@

browseRegistry: browseRegistry.o
	${CC} ${C_FLAGS} browseRegistry.o ${LIB_FLAGS} -o $@

destroySWS: destroySWS.o
	${CC} ${C_FLAGS} destroySWS.o ${LIB_FLAGS} -o $@

clean:
	rm -f browseRegistry createSWS createVisSWS destroySWS
	rm -f *.o
	rm -f *~
