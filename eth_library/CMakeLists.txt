cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(eth_library VERSION 1.0.0 LANGUAGES C)
add_library(eth_library SHARED sendeth.c sendeth.def)
add_executable(sendeth_test sendeth.c)

set_target_properties(eth_library PROPERTIES
    PUBLIC_HEADER sendeth.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "eth"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)
