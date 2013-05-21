# project name
PROJECT(QRSIMTCP)
 
# minimum cmake version required
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

set(CLIENT_ONLY OFF CACHE BOOL "set to ON to build only the C++ client library")
set(MATLABROOT "" CACHE PATH "Matlab installation directory i.e. output of command matlabroot")

# keeps Eclipse happy about include files
set(CMAKE_VERBOSE_MAKEFILE ON)

# the current version
set(PACKAGE_NAME 	"qrsimtcp")
set(PACKAGE_VERSION 	"0.1.1")
set(PACKAGE_BUGREPORT 	"r.denardi@cs.ucl.ac.uk")

# output directory for binaries and libraries
set(BIN ${CMAKE_SOURCE_DIR}/bin)
set(LIB ${CMAKE_SOURCE_DIR}/lib)

# set the output directories
set(LIBRARY_OUTPUT_PATH ${LIB} CACHE PATH "Output directory for the libraries")
set(EXECUTABLE_OUTPUT_PATH ${BIN} CACHE PATH "Output directory for the executables")

# specify the protobuf version and MD5
set(PBV "2.3.0")
set(PBMD5 "65dba2c04923595b6f0a6a44d8106f0a")

# get matlab jre version strings, and check if it has pb
if(${MATLABROOT} STREQUAL "") 
  message(FATAL_ERROR  
    "MATLABROOT variable not specified"
  )
else()
  if(CMAKE_SYSTEM_PROCESSOR STREQUAL i386)
    set(MATLABARCH glnx86)
  elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL x86_64)
    set(MATLABARCH glnxa64)
  else()
    message(FATAL_ERROR  "You do not appeart to be on a Linux machine, this TCP interface is linux only")
  endif()

  # somehow java spits out the version on the error stream, go figure
  execute_process(
    COMMAND ./java -version
    WORKING_DIRECTORY ${MATLABROOT}/sys/java/jre/${MATLABARCH}/jre/bin
    ERROR_VARIABLE MATLABJREVERSTR
  )

  string( REGEX REPLACE ".* version \"([0-9]+)\\.[0-9]+.*" "\\1" MATLABJREVERMAJOR "${MATLABJREVERSTR}")
  string( REGEX REPLACE ".* version \"[0-9]+\\.([0-9]+).*" "\\1" MATLABJREVERMINOR "${MATLABJREVERSTR}")

  message(STATUS  "Matlab JRE version = ${MATLABJREVERMAJOR}.${MATLABJREVERMINOR}")

  if (EXISTS "${MATLABROOT}/java/jarext/protobuf.jar") 
    set(MATLABHASPB, ON)
  else()
    set(MATLABHASPB, OFF)
  endif()
endif()


# find needed libraries
find_path(CMATH_INCLUDEDIR math.h)
find_library(CMATH_LIBRARYDIR NAMES m) 
find_package(Threads)


# make available to cmake the needed project specific modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# look for java only if we building the server part of the library
if(NOT CLIENT_ONLY)
  find_package(Java ${MATLABJREVERMAJOR}.${MATLABJREVERMINOR} REQUIRED)
  include(UseJava)
  find_program(MAVEN_EXECUTABLE NAMES mvn)
  
  if(${MAVEN_EXECUTABLE} STREQUAL "")
    message(FATAL_ERROR  
      "cmake is not able to find maven in your system, in Ubuntu you can install it with sudo apt-get install maven2"
    ) 
  endif()

  if(JAVA_FOUND)
    message(STATUS 
      "Both the C++ client code and the java server code will be compiled"
    ) 
  else()
    message(FATAL_ERROR  
      "cmake is not able to find Java, aborting. If you meant to only compile the C++ client code run cmake .. -DCLIENT_ONLY=ON"
    ) 
  endif()
else()
  message(STATUS "Only the C++ client side code will be compiled") 
endif()


# clean wrong versions of the protocol buffer source code
if (EXISTS "${CMAKE_BINARY_DIR}/download/protobuf-${PBV}.tar.gz") 
  execute_process(
    COMMAND md5sum ./protobuf-${PBV}.tar.gz
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/
    OUTPUT_VARIABLE PBMD5TESTOUTSTR
  )
  string( REGEX REPLACE "([0-9a-f])  .*" "\\1" PBMD5TESTOUT "${PBMD5TESTOUTSTR}")

  if(NOT (${PBMD5TESTOUT} STREQUAL ${PBMD5}))  
    execute_process(
      COMMAND cmake -E remove -f protobuf-${PBV}.tar.gz
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/
    )
    execute_process(
      COMMAND cmake -E remove_directory protobuf-${PBV}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/
    )
  endif()	
endif()

# download protocol buffer archive
if ((NOT EXISTS "${CMAKE_BINARY_DIR}/download/protobuf-${PBV}.tar.gz"))
  file(DOWNLOAD 
    "http://protobuf.googlecode.com/files/protobuf-${PBV}.tar.gz" 
    "${CMAKE_BINARY_DIR}/download/protobuf-${PBV}.tar.gz"
    INACTIVITY_TIMEOUT 30
    STATUS "Downloading protobuf-${PBV}.tar.gz"
    SHOW_PROGRESS
  )
  execute_process(
    COMMAND md5sum ./protobuf-${PBV}.tar.gz
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/
    OUTPUT_VARIABLE PBMD5DTESTOUTSTR
  )
  string( REGEX REPLACE "([0-9a-f])  .*" "\\1" PBMD5DTESTOUT "${PBMD5DTESTOUTSTR}")

  if(NOT (${PBMD5DTESTOUT} STREQUAL ${PBMD5}))  
    message( FATAL_ERROR 
      "The downloaded archive for protobuf-${PBV}.tar.gz has an unespected md5sum, rerun cmake to redownload it" 
    )
  endif()  
endif()

# if needed unpack protocol buffer archive
if (NOT EXISTS "${CMAKE_BINARY_DIR}/download/protobuf-${PBV}")
  execute_process(
    COMMAND tar xzf ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}.tar.gz
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/
  )
endif()

# configure
execute_process(
  COMMAND ./configure --prefix=${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}
)

# clean
execute_process(
  COMMAND make clean
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}
)

# compile C, C++ library
execute_process(
  COMMAND make
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}
)

# install C, C++ library locally
execute_process(
  COMMAND make install
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}
)

# compile java library
if(JAVA_FOUND AND NOT CLIENT_ONLY)

  execute_process(
    COMMAND mvn package
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java
  )
  
  if (EXISTS "${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target/protobuf-java.jar")
    execute_process(
      COMMAND rm "protobuf-java.jar"
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target
  )
  endif()

  execute_process(
    COMMAND ln -s ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target/protobuf-java-${PBV}.jar ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target/protobuf-java.jar
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target/
  )
endif()

# give cmake a good hint about the path
set(ENV{PROTOBUF_PATH} ${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/)
# get cmake to find the protocolbuffer library 
FIND_PACKAGE(ProtocolBuffers)

# define header and library search paths
include_directories (
	${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/proto_gen
	${PROTOBUF_ROOT_INCLUDE_DIR} 
)


# call protocol buffer pre-compiler
FILE(GLOB PROTO_FILES proto/*.proto)
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/proto_gen")
  execute_process(
    COMMAND rm -rf proto_gen
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
endif()
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
	${CMAKE_THREAD_LIBS_INIT}
	${PROTOBUF_LIBRARY} 
)

# example client binary
add_executable(exampleclient
	src/exampleclient.cpp
)

target_link_libraries(exampleclient
	qrsimtcpclient
	${CMAKE_THREAD_LIBS_INIT}
	${PROTOBUF_LIBRARY} 
)

if(JAVA_FOUND AND NOT CLIENT_ONLY)

  find_jar(PROTO_JAVA NAMES protobuf-java
    PATHS
    $ENV{PROTOBUF_PATH}/java/target
  )

  if(NOT "${PROTO_JAVA}" STREQUAL "PROTO_JAVA-NOTFOUND")
    set(CMAKE_JAVA_INCLUDE_PATH            
      ${PROTO_JAVA}
    )

    get_filename_component(PROTO_JAVA_DIR ${PROTO_JAVA} PATH)
    message(STATUS "jar files will be installed in "${PROTO_JAVA_DIR})
    
    add_jar(qrsimtcpserver 
    	java/qrsimsrvcli/QrsSrvCliMsg.java
        java/qrsimsrvcli/QRSimTCPServer.java
    )  
	
    install_jar(qrsimtcpserver ${PROTO_JAVA_DIR}) 

    # add the right paths to the Matlab server code 
    set(THE_FOLLOWING_IS_TURNED_INTO_ACTUAL_MATLAB_CODE_BY_CMAKE "% Do not edit! Part of this code is automatically generated by cmake, edit QRSimTCPServer.m.in and rerun cmake") 

    if(${MATLABHASPB})
      set(PROTO_JAVA_DYNAMIC_LOAD_STATEMENT "")
    else()
      set(PROTO_JAVA_DYNAMIC_LOAD_STATEMENT "javaaddpath('${CMAKE_BINARY_DIR}/download/protobuf-${PBV}/java/target/protobuf-java.jar');")
    endif()

    configure_file(
      "${CMAKE_SOURCE_DIR}/matlab/QRSimTCPServer.m.in"
      "${CMAKE_SOURCE_DIR}/matlab/QRSimTCPServer.m"
      IMMEDIATE @ONLY
    )
  else()
    message(WARNING "cmake is not able to find the Java protcol buffers library in your system make sure it is installed, for now only the C++ client side code will be compiled") 
  endif()
else()
  if(NOT CLIENT_ONLY)
    message(WARNING "cmake is not able to find Java in your system, only the C++ client side code will be compiled")
  endif()
endif()

# make an uninstall target 
configure_file(
  "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake.in"
  "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake"
  IMMEDIATE @ONLY
)

add_custom_target(uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake"
)


string(TOLOWER ${PROJECT_NAME}CLIENT LIBRARY_NAME)
  
#######################################################
## Define headers files associated with the install target 
set(INSTALL_HEADERS 
	src/QRSimTCPClient.h 
	proto_gen/qrs_srv_cli_msg.pb.h
)

# install headers
install(FILES ${INSTALL_HEADERS} 
  DESTINATION ${CMAKE_INSTALL_PREFIX}/include/${LIBRARY_NAME}
)

# install library
install(TARGETS ${LIBRARY_NAME}
  RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
  LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
  ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
)  
