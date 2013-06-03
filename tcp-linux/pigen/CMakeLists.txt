# project name
PROJECT(PI)
 
# minimum cmake version required
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# the current version
set(PACKAGE_NAME 	"pi")
set(PACKAGE_VERSION 	"0.0.1")
set(PACKAGE_BUGREPORT 	"v.gomez@science.ru.nl")

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS "-O3 -Wall -fmessage-length=0 -fPIC")

# output directory for binaries
set(BIN ${CMAKE_SOURCE_DIR}/bin)

# set the output directories
set(EXECUTABLE_OUTPUT_PATH ${BIN} CACHE PATH "Output directory for the executables")

# find needed libraries
find_path(CMATH_INCLUDEDIR math.h)
find_library(CMATH_LIBRARYDIR NAMES m) 

# make available to cmake the needed project specific modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# specify the protobuf version
set(PBV "2.3.0")

# find pthread
find_package(Threads)
# find GSL
find_package(GSL)
# find Boost
find_package(Boost) # 1.34 COMPONENTS date_time filesystem iostreams ... )

# give cmake a good hint about the local protocol buffers path
set(ENV{PROTOBUF_PATH} ${QRSIMTCPLINUX_DIR}/build/download/protobuf-${PBV}/)

# get cmake to find the local protocolbuffer library 
FIND_PACKAGE(ProtocolBuffers)


# the following should be in a FindQRSimTCPClient.cmake 
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
	${GSL_INCLUDE_DIRS}
        ${QRSIMTCPCLIENT_INCLUDE_DIR}
	${PROTOBUF_ROOT_INCLUDE_DIR} 
	${Boost_INCLUDE_DIR}
)


set(LIST_EXEC Catmouse Circular)

foreach(example ${LIST_EXEC})

    set(MODEL src/Model${example}.cpp)
    set(EXEC pi_${example})
    
    # interface test binary
    add_executable(${EXEC}
	    src/PIController.cpp
         src/pi_qrsim.cpp
         ${MODEL}
    )

    target_link_libraries(${EXEC}
    	${QRSIMTCPCLIENT_LIBRARY}
    	${GSL_LIBRARIES} 
    	${CMAKE_THREAD_LIBS_INIT}
    	${PROTOBUF_LIBRARY} 
    	${Boost_LIBRARIES}
    )

endforeach(example)


