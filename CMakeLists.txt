# Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.20)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD 99)
project(D3D12UBench LANGUAGES CXX C)

if (CMAKE_COMPILER_IS_GNUCXX OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Clang"))
    set(D3D12_UBENCH_CXX_FLAGS -Wshadow -Wall -Wextra -Wno-comment -Wno-missing-field-initializers -Wno-empty-body)
    if (${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
        set(D3D12_UBENCH_CXX_FLAGS ${D3D12_UBENCH_CXX_FLAGS} -Wno-backslash-newline-escape)
    endif()
    if (NOT (${CMAKE_BUILD_TYPE} MATCHES "Release"))
        message("Disabling frame pointer for profiling/debug.")
        set(D3D12_UBENCH_CXX_FLAGS ${D3D12_UBENCH_CXX_FLAGS} -fno-omit-frame-pointer)
    endif()
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "(x86)|(X86)|(amd64)|(AMD64)")
        message("Enabling SSE3 support.")
        set(D3D12_UBENCH_CXX_FLAGS ${D3D12_UBENCH_CXX_FLAGS} -msse3)
    endif()
elseif (MSVC)
    set(D3D12_UBENCH_CXX_FLAGS /D_CRT_SECURE_NO_WARNINGS /wd4267 /wd4244 /wd4309 /wd4005 /MP /DNOMINMAX)
endif()

add_subdirectory(shaders EXCLUDE_FROM_ALL)

add_library(d3d12-device STATIC device.cpp device.hpp renderdoc_app.h)
target_compile_options(d3d12-device PRIVATE ${D3D12_UBENCH_CXX_FLAGS})
target_include_directories(d3d12-device PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

if (NOT WIN32)
    target_link_libraries(d3d12-device PRIVATE dl)
endif()

if (VKD3D_PROTON_FOUND)
    message("Using system vkd3d-proton install.")
    target_link_libraries(d3d12-device PUBLIC PkgConfig::VKD3D_PROTON)
    target_compile_definitions(d3d12-device PUBLIC VKD3D_PROTON_SYSTEM)
else()
    message("Dynamically loading D3D12 implementation in runtime.")
    # Use vendored headers and dynamically load.
    target_include_directories(d3d12-device PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
endif()

add_executable(d3d12-ubench d3d12_ubench.cpp
        cli_parser.cpp cli_parser.hpp
        path_utils.cpp path_utils.hpp
        string_helpers.cpp string_helpers.hpp
        logging.cpp logging.hpp)
target_compile_options(d3d12-ubench PRIVATE ${D3D12_UBENCH_CXX_FLAGS})
target_link_libraries(d3d12-ubench PRIVATE dxil-shaders d3d12-device)

include(FindPkgConfig)
pkg_check_modules(VKD3D_PROTON IMPORTED_TARGET libvkd3d-proton-d3d12)

install(TARGETS d3d12-ubench)
if (WIN32 AND CMAKE_COMPILER_IS_GNUCXX)
    target_link_libraries(d3d12-ubench PRIVATE -static gcc stdc++ winpthread)
endif()

