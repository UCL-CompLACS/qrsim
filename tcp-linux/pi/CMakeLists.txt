# project name
PROJECT(PI)
 
# minimum cmake version required
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# the current version
set(PACKAGE_NAME 	"pi")
set(PACKAGE_VERSION 	"0.0.1")
set(PACKAGE_BUGREPORT 	"v.gomez@science.ru.nl")

# output directory for binaries
set(BIN ${CMAKE_SOURCE_DIR}/bin)

# set the output directories
set(EXECUTABLE_OUTPUT_PATH ${BIN} CACHE PATH "Output directory for the executables")

# find needed libraries
find_path(CMATH_INCLUDEDIR math.h)
find_library(CMATH_LIBRARYDIR NAMES m) 
find_package(Threads)

# make available to cmake the needed project specific modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# specify the protobuf version
set(PBV "2.3.0")

# give cmake a good hint about the local protocol buffers path
set(ENV{PROTOBUF_PATH} ${QRSIMTCPLINUX_DIR}/build/download/protobuf-${PBV}/)

# get cmake to find the local protocolbuffer library 
FIND_PACKAGE(ProtocolBuffers)


# find libqrsimtcpclient include
FIND_PATH(QRSIMTCPCLIENT_INCLUDE_DIR QRSimTCPClient.h
    HINTS 
    ${QRSIMTCPLINUX_DIR}
    PATH_SUFFIXES include/qrsimtcpclient
)

# find qrsimtcpclient library
FIND_LIBRARY(QRSIMTCPCLIENT_LIBRARY NAMES qrsimtcpclient
    HINTS
    ${QRSIMTCPLINUX_DIR} 
    PATH_SUFFIXES lib
)


# define header and library search paths
include_directories (
	${CMAKE_SOURCE_DIR}/src
        ${QRSIMTCPCLIENT_INCLUDE_DIR}
	${PROTOBUF_ROOT_INCLUDE_DIR} 
)

# interface test binary
add_executable(pi_qrsim
	src/pi_qrsim.cpp
)

target_link_libraries(pi_qrsim
	${CMAKE_THREAD_LIBS_INIT}
	${PROTOBUF_LIBRARY} 
	${QRSIMTCPCLIENT_LIBRARY} 
)

