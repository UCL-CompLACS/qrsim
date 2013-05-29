GCC=g++
QRPATH=../..
INCLUDE1=$(QRPATH)/tcp-linux/build/download/protobuf-2.3.0/include
INCLUDE2=$(QRPATH)/tcp-linux/src/
INCLUDE3=$(QRPATH)/tcp-linux/proto_gen/
LIBS_DIR_CLIENT=$(QRPATH)/tcp-linux/lib
LIBS_DIR_PROTO=$(QRPATH)/tcp-linux/build/download/protobuf-2.3.0/lib
LIBS=-rdynamic $(LIBS_DIR_CLIENT)/libqrsimtcpclient.so -lgsl -lpthread $(LIBS_DIR_PROTO)/libprotobuf.so -lgslcblas -Wl,-rpath,$(LIBS_DIR_CLIENT):$(LIBS_DIR_PROTO)
OPTS=-O3 -Wall -fmessage-length=0 -fPIC

pi_qrsim: pi_qrsim.o PIController.o 
	$(GCC) -o pi_qrsim pi_qrsim.o PIController.o $(LIBS)

pi_qrsim.o: pi_qrsim.cpp 
	$(GCC) -I$(INCLUDE1) -I$(INCLUDE2) -I$(INCLUDE3) $(OPTS) -c pi_qrsim.cpp

PIController.o: PIController.cpp PIController.h
	$(GCC) -c PIController.cpp

clean:
	rm *o pi_qrsim

