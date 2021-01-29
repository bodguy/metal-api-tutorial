cmake_minimum_required(VERSION 3.10)
project(glfw-metal VERSION 0.0.1)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake/")

find_library(COCOA_LIBS Cocoa REQUIRED)
find_library(QUARTZCORE_LIBRARY QuartzCore REQUIRED)
find_library(METAL_LIBRARY Metal REQUIRED)
find_package(GLFW3 REQUIRED)

if(NOT GLFW3_FOUND)
  message(SEND_ERROR ">>> GLFW not found")
endif()

add_executable(${CMAKE_PROJECT_NAME} "main.mm")

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${GLFW3_INCLUDE_DIR})
set(EXTRA_LIB_DIR ${COCOA_LIBS} ${QUARTZCORE_LIBRARY} ${METAL_LIBRARY} ${GLFW3_LIBRARY})
target_link_libraries(${CMAKE_PROJECT_NAME} ${EXTRA_LIB_DIR})
