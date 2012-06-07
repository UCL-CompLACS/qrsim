# Try to find protocol buffers (protobuf)
#
# Use as FIND_PACKAGE(ProtocolBuffers)
#
#  PROTOBUF_FOUND - system has the protocol buffers library
#  PROTOBUF_INCLUDE_DIR - the zip include directory
#  PROTOBUF_INCLUDE_DIRECTORIES - should work when the former doesn't (Luke Teacy)
#  PROTOBUF_LIBRARY - Link this to use the zip library
#  PROTOBUF_PROTOC_EXECUTABLE - executable protobuf compiler
#
# And the following command
#
#  WRAP_PROTO(VAR input1 input2 input3..)
#
# Which will run protoc on the input files and set VAR to the names of the created .cc files,
# ready to be added to ADD_EXECUTABLE/ADD_LIBRARY. E.g,
#
#  WRAP_PROTO(PROTO_SRC myproto.proto external.proto)
#  ADD_EXECUTABLE(server ${server_SRC} {PROTO_SRC})
#
# Author: Esben Mose Hansen <esben at ange.dk>, (C) Ange Optimization ApS 2008
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

IF (PROTOBUF_LIBRARY AND PROTOBUF_INCLUDE_DIR AND PROTOBUF_PROTOC_EXECUTABLE)
  # in cache already
  SET(PROTOBUF_FOUND TRUE)
ELSE (PROTOBUF_LIBRARY AND PROTOBUF_INCLUDE_DIR AND PROTOBUF_PROTOC_EXECUTABLE)

  FIND_PATH(PROTOBUF_ROOT_INCLUDE_DIR google/protobuf/stubs/common.h
    HINTS ENV PROTOBUF_PATH
  )

  FIND_PATH(PROTOBUF_INCLUDE_DIR stubs/common.h
    PATH_SUFFIXES google/protobuf
    HINTS ENV PROTOBUF_PATH
  )

  SET(PROTOBUF_INCLUDE_DIRECTORIES ${PROTOBUF_INCLUDE_DIR} ${PROTOBUF_ROOT_INCLUDE_DIR})

  FIND_LIBRARY(PROTOBUF_LIBRARY NAMES protobuf
    PATHS
    ENV PROTOBUF_PATH
    ${GNUWIN32_DIR}/lib
  )

  FIND_PROGRAM(PROTOBUF_PROTOC_EXECUTABLE protoc HINTS ENV PROTOBUF_PATH)

  INCLUDE(FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(protobuf DEFAULT_MSG PROTOBUF_INCLUDE_DIR PROTOBUF_LIBRARY PROTOBUF_PROTOC_EXECUTABLE)

  # ensure that they are cached
  SET(PROTOBUF_INCLUDE_DIR ${PROTOBUF_INCLUDE_DIR} CACHE INTERNAL "The protocol buffers include path")
  SET(PROTOBUF_LIBRARY ${PROTOBUF_LIBRARY} CACHE INTERNAL "The libraries needed to use protocol buffers library")
  SET(PROTOBUF_PROTOC_EXECUTABLE ${PROTOBUF_PROTOC_EXECUTABLE} CACHE INTERNAL "The protocol buffers compiler")

ENDIF (PROTOBUF_LIBRARY AND PROTOBUF_INCLUDE_DIR AND PROTOBUF_PROTOC_EXECUTABLE)


IF (PROTOBUF_FOUND)
  # Define the WRAP_PROTO function
  FUNCTION(WRAP_PROTO VAR)

    IF (NOT ARGN)
      MESSAGE(SEND_ERROR "Error: WRAP PROTO called without any proto files")
      RETURN()
    ENDIF(NOT ARGN)

    SET(INCL)
    SET(${VAR})
    SET(PROTO_OUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/proto_gen)
    SET(PROTO_JAVA_OUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/java)
    FILE(MAKE_DIRECTORY ${PROTO_OUT_DIR})
    FILE(MAKE_DIRECTORY ${PROTO_JAVA_OUT_DIR})
    FOREACH(FIL ${ARGN})
      GET_FILENAME_COMPONENT(ABS_FIL ${FIL} ABSOLUTE)
      GET_FILENAME_COMPONENT(FIL_WE ${FIL} NAME_WE)
      SET(CURRENT_SRC "${PROTO_OUT_DIR}/${FIL_WE}.pb.cc")
      SET(CURRENT_HEADER "${PROTO_OUT_DIR}/${FIL_WE}.pb.h")
      LIST(APPEND ${VAR} ${CURRENT_SRC})
      LIST(APPEND INCL ${CURRENT_HEADER})

      MESSAGE("src: ${CURRENT_SRC}\nincl: ${CURRENT_HEADER}")
      
      ADD_CUSTOM_COMMAND(
        OUTPUT ${CURRENT_SRC} ${CURRENT_HEADER}
        COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
        ARGS --cpp_out  ${PROTO_OUT_DIR} --proto_path ${CMAKE_CURRENT_SOURCE_DIR}/proto ${ABS_FIL}
        DEPENDS ${ABS_FIL}
        COMMENT "Running protocol buffer CPP compiler on ${FIL}"
        VERBATIM )
	
       EXECUTE_PROCESS(
        	COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE} --java_out  ${PROTO_JAVA_OUT_DIR} --proto_path ${CMAKE_CURRENT_SOURCE_DIR}/proto ${ABS_FIL}
        )
    ENDFOREACH(FIL)

    SET(${VAR} ${${VAR}} PARENT_SCOPE)

  ENDFUNCTION(WRAP_PROTO)
ENDIF(PROTOBUF_FOUND)
