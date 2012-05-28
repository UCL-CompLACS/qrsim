# project name
PROJECT(QRSIMTCP)
 
# minimum cmake version required
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

# keeps Eclipse happy about include files
SET(CMAKE_VERBOSE_MAKEFILE ON)

# the current version
set(PACKAGE_NAME 	"qrsimtcp")
set(PACKAGE_VERSION 	"0.0.1")
set(PACKAGE_BUGREPORT 	"r.denardi@cs.ucl.ac.uk")

# check for math library
FIND_PATH(CMATH_INCLUDEDIR math.h)
FIND_LIBRARY(CMATH_LIBRARYDIR NAMES m) 

INCLUDE(FindProtocolBuffers.cmake)
FIND_PACKAGE(Java)
INCLUDE(UseJava)

# output directory for binaries and libraries
SET(BIN ${CMAKE_SOURCE_DIR}/bin)
SET(LIB ${CMAKE_SOURCE_DIR}/lib)

# set the output directories
SET(LIBRARY_OUTPUT_PATH ${LIB} CACHE PATH "Output directory for the libraries")
SET(EXECUTABLE_OUTPUT_PATH ${BIN} CACHE PATH "Output directory for the executables")

# define header and library search paths
include_directories (
	${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/proto_gen
	${PROTOBUF_INCLUDE_DIR} 
)

# call protocol buffer pre-compiler
FILE(GLOB PROTO_FILES proto/*.proto)
WRAP_PROTO(PROTO_GENERATED ${PROTO_FILES})


# build the library
add_library(qrsimtcpclient SHARED
    ${PROTO_GENERATED}			
	src/QRSimTCPClient.cpp
)

# interface test binary
add_executable(testclient
	src/testclient.cpp
)

target_link_libraries(testclient
	qrsimtcpclient
	${PROTOBUF_LIBRARY} 
)

# example client binary
add_executable(exampleclient
	src/exampleclient.cpp
)

target_link_libraries(exampleclient
	qrsimtcpclient
	${PROTOBUF_LIBRARY} 
)

find_jar(PROTO_JAVA 
         protobuf-java 
)

if(JAVA_FOUND)
	set(CMAKE_JAVA_INCLUDE_PATH            
    	${PROTO_JAVA}
	)

	add_jar(qrsimtcpserver 
    	java/qrsimsrvcli/QrsSrvCliMsg.java
    	java/qrsimsrvcli/QRSimTCPServer.java
	)  
	
	install_jar(qrsimtcpserver /usr/share/java)  	
endif(JAVA_FOUND)

# make an uninstall target 
CONFIGURE_FILE(
 	"${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake.in"
  	"${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake"
  	IMMEDIATE @ONLY
)

ADD_CUSTOM_TARGET(uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake")


STRING(TOLOWER ${PROJECT_NAME}CLIENT LIBRARY_NAME)
  
#######################################################
## Define headers files associated with the install target 
SET(INSTALL_HEADERS 
	src/QRSimTCPClient.h 
	proto_gen/qrs_srv_cli_msg.pb.h
)

# install headers
INSTALL(FILES ${INSTALL_HEADERS} 
  DESTINATION ${CMAKE_INSTALL_PREFIX}/include/${LIBRARY_NAME}
)

# install library
INSTALL(TARGETS ${LIBRARY_NAME}
  RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
  LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
  ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
)  