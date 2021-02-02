cmake_minimum_required(VERSION 3.10)
project(metal-gpgpu VERSION 0.0.1)

set(CMAKE_CXX_STANDARD 17)

find_library(COCOA_LIBS Cocoa REQUIRED)
find_library(METAL_LIBRARY Metal REQUIRED)

add_executable(${CMAKE_PROJECT_NAME} "main.mm")

set(EXTRA_LIB_DIR ${COCOA_LIBS} ${METAL_LIBRARY})
target_link_libraries(${CMAKE_PROJECT_NAME} ${EXTRA_LIB_DIR})
