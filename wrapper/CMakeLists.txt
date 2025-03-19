cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
project(torch_wrapper)

find_package(Torch REQUIRED)

add_library(torch_wrapper SHARED torch_wrapper.cpp)
target_link_libraries(torch_wrapper "${TORCH_LIBRARIES}")
target_include_directories(torch_wrapper PRIVATE ${TORCH_INCLUDE_DIRS})

set_property(TARGET torch_wrapper PROPERTY CXX_STANDARD 17)

