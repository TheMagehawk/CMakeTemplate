cmake_minimum_required(VERSION 3.12)    # Min Version for C++20 Support

set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
if (POLICY CMP0025)
    cmake_policy(SET CMP0025 NEW)
endif ()

set(CMAKE_CXX_STANDARD 20)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Android NDK Setup
if(CMAKE_BUILD_ANDROID AND NOT BUILD_ANDROID_GRADLE)
    if(NOT ANDROID_NDK_PATH)
        message("No Android NDK Path set! Using environment variable: " $ENV{ANDROID_NDK_HOME})
        set(ANDROID_NDK_PATH $ENV{ANDROID_NDK_HOME})
        STRING(REGEX REPLACE "\\\\" "/" ANDROID_NDK_PATH ${ANDROID_NDK_PATH} )
    endif()
endif()

# Android Toolchain Setup
if(CMAKE_BUILD_ANDROID AND ANDROID_NDK_PATH AND NOT BUILD_ANDROID_GRADLE)
    set(CMAKE_SYSTEM_NAME Android)
    set(CMAKE_SYSTEM_VERSION 24) # API Level
    set(CMAKE_ANDROID_ARCH_ABI "arm64-v8a")
    set(CMAKE_ANDROID_API_MIN 24)
    set(ANDROID_PLATFORM 24)
    set(CMAKE_ANDROID_NDK ${ANDROID_NDK_PATH})
    set(CMAKE_ANDROID_NDK_DEPRECATED_HEADERS False)
    set(CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION "clang")
    set(CMAKE_TOOLCHAIN_FILE ${CMAKE_ANDROID_NDK}/build/cmake/android.toolchain.cmake)
    set(CMAKE_ANDROID_STL_TYPE "c++_static")
endif()

# Set Version info
set(PROJECT_NAME "CMakeTemplate")
set(PROJECT_VERSION 0.1.0)
set(PROJECT_DESCRIPTION "A flexible, extensible and cross-platform CMake Template")

# Set output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(ASSEMBLY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/asm)

# Set include directories
set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(RESOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/resources)
set(LIBS_LOCAL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/external)

set(WINDOWS_ICON_RESOURCE ${RESOURCES_DIR}/icon.rc)
set(USE_WINDOWS_ICON TRUE)

if(WIN32)
    set(WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
endif()

project(${PROJECT_NAME} VERSION ${PROJECT_VERSION} DESCRIPTION ${PROJECT_DESCRIPTION} LANGUAGES CXX C)

if(APPLE)
    enable_language(OBJC)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(FindPackageHandleStandardArgs)

message(${PROJECT_NAME} " " ${PROJECT_VERSION})

message(STATUS "CMake Version: ${CMAKE_VERSION}")
message(STATUS "System: " ${CMAKE_SYSTEM_NAME})
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Target Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message("")

set(BUILD_SHARED_LIBS FALSE)
set(POSITION_INDEPENDENT_CODE TRUE)

list(APPEND LIBS "")
list(APPEND LIBS_MINIMUM_VERSION "")
list(APPEND LIBS_SHARED "")	# Mainly for LGPL-Licensed Libraries
list(APPEND FOUND_PACKAGES "")
list(APPEND NOT_FOUND_PACKAGES "")

set(HAVE_CUSTOM_CMAKE FALSE)    # Custom CMake Targets written in a custom CMakeLists.txt in the external directory
list(APPEND LIBS_CUSTOM_CMAKE "")

if(NOT ANDROID)
    list(APPEND LIBS "")
    list(APPEND LIBS_MINIMUM_VERSION "")

    if(NOT EMSCRIPTEN)
        list(APPEND LIBS "")
        list(APPEND LIBS_MINIMUM_VERSION "")
    endif()
endif()

foreach(LIB_SHARED ${LIBS_SHARED})
    set(${LIB_SHARED}_USE_SHARED TRUE)
endforeach()

if(COMPILE_LIBS)
    message("Compiling all libraries from source...")
    list(APPEND NOT_FOUND_PACKAGES ${LIBS})
else()
    foreach(LIB ${LIBS})
        set(CHECK_LIB ${LIB})

        set(LIB_NAME "EMPTY")
        set(LIB_MIN_VERSION "0.0.0")

        if(NOT WIN32)
            foreach(LIB_PAIR ${LIBS_MINIMUM_VERSION})
                string(FIND "${LIB_PAIR}" ":" POS)
                math(EXPR POS2 ${POS}+1)
                string(SUBSTRING ${LIB_PAIR} 0 ${POS} LIB_NAME)
                string(SUBSTRING ${LIB_PAIR} ${POS2} -1 LIB_MIN_VERSION)

                if(${LIB} STREQUAL ${LIB_NAME})
                    break()
                endif()
            endforeach()

            if(${LIB_MIN_VERSION} STREQUAL "0.0.0")
                find_package(${CHECK_LIB} QUIET)
            else()
                find_package(${CHECK_LIB} ${LIB_MIN_VERSION} QUIET)
            endif()
        endif()

        if(WIN32 OR NOT ${${CHECK_LIB}_FOUND})
            if(WIN32 OR ${LIB_MIN_VERSION} STREQUAL "0.0.0")
                message("Could not find library " ${CHECK_LIB})
            else()
                message("Could not find library " ${CHECK_LIB} " or version unsupported! (Min Version required: " ${LIB_MIN_VERSION} ")")
            endif()

            message("Need to build library " ${CHECK_LIB} " from source!")
            list(APPEND NOT_FOUND_PACKAGES ${LIB})
        else()
            message("Found library " ${CHECK_LIB} "! (Version: " ${${CHECK_LIB}_VERSION} ")")
            message("Using System Library " ${CHECK_LIB} "!")
            list(APPEND FOUND_PACKAGES ${CHECK_LIB})
        endif()
    endforeach()
endif()

# Add CMake Configuration for missing libraries
foreach(package ${NOT_FOUND_PACKAGES})
    if(package IN_LIST LIBS_CUSTOM_CMAKE)
        continue()
    endif()

    message("Adding local package ${package}")

    if(${package}_USE_SHARED)
        set(BUILD_SHARED_LIBS TRUE)
    else()
        set(BUILD_SHARED_LIBS FALSE)
    endif()
        
    add_subdirectory(${LIBS_LOCAL_INCLUDE_DIR}/${package} EXCLUDE_FROM_ALL)
endforeach()

if(HAVE_CUSTOM_CMAKE)
    add_subdirectory(${LIBS_LOCAL_INCLUDE_DIR} EXCLUDE_FROM_ALL)
endif()

if(ANDROID)
    find_library( # Sets the name of the path variable.
            log-lib

            # Specifies the name of the NDK library that
            # you want CMake to locate.
            log)
endif()

list(APPEND SOURCE_FILES
    ${SRC_DIR}/Main.cpp # C++ Example
    #${SRC_DIR}/Main.c   # C Example
)

if(WIN32 AND USE_WINDOWS_ICON)
    add_executable(${PROJECT_NAME}
        ${SOURCE_FILES}
        ${WINDOWS_ICON_RESOURCE}
    )
else()
    add_executable(${PROJECT_NAME}
        ${SOURCE_FILES}
    )
endif()

target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${SRC_DIR}
    ${LIBS_LOCAL_INCLUDE_DIR}
    PUBLIC
    #${SRC_DIR}
    ${LIBS_LOCAL_INCLUDE_DIR}
)

if(LIBS)
    message("")
endif()

foreach(package ${FOUND_PACKAGES})
    set(PACKAGE_UPPER "")
    string(TOUPPER ${package} PACKAGE_UPPER)

    message("Including System Libary " ${package} ": " ${${PACKAGE_UPPER}_INCLUDE_DIRS} " " ${${PACKAGE_UPPER}_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME} PUBLIC
        ${${PACKAGE_UPPER}_INCLUDE_DIRS}
        ${${PACKAGE_UPPER}_INCLUDE_DIR}
    )

    message("Linking System Library " ${package} ": " ${${PACKAGE_UPPER}_LIBRARIES})
        target_link_libraries(${PROJECT_NAME} PUBLIC
            ${${PACKAGE_UPPER}_LIBRARIES}
        )
endforeach()

foreach(package ${NOT_FOUND_PACKAGES})
    set(PACKAGE_INCLUDE_DIR "")
    string(TOUPPER ${package} PACKAGE_INCLUDE_DIR)

    message("Including and Linking Local Library " ${package} ": " ${${PACKAGE_INCLUDE_DIR}_LOCAL_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME}
        PUBLIC
        ${${PACKAGE_INCLUDE_DIR}_LOCAL_INCLUDE_DIR}
    )

    target_link_libraries(${PROJECT_NAME} PUBLIC
            ${package}
    )
endforeach()

if(UNIX)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
endif()

find_package(Threads QUIET)

if(${Threads_FOUND})
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        Threads::Threads
    )
endif()

    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        ${CMAKE_DL_LIBS}
    )

if(ANDROID)
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        android
        ${log-lib}
        EGL
        GLESv3
    )
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${PROJECT_NAME} PRIVATE IS_DEBUG=1)
endif()

# Ignore warning for using "insecure" functions on Visual Studio/Windows e.g. fopen instead of fopen_s
if(WIN32)
    target_compile_definitions(${PROJECT_NAME} PRIVATE _CRT_SECURE_NO_WARNINGS=1)
endif()

if(CMAKE_BUILD_ANDROID AND NOT BUILD_ANDROID_GRADLE)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USING_ANDROID_NDK=1)
endif()

if(EMSCRIPTEN)
    set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS ${LINK_FLAGS} "-s EMCC_DEBUG=1")
endif()

# Set C++ Version for target/executable
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 20)

set_target_properties(${PROJECT_NAME} PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(${PRJECT_NAME} PROPERTIES SOVERSION 1)
set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

set_target_properties(${PROJECT_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
set_target_properties(${PROJECT_NAME} PROPERTIES C_VISIBILITY_PRESET hidden)

if(APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES OBJC_VISIBILITY_PRESET hidden)
endif()

if(LIBS)
    message("")
endif()

# Generation completion notice
message(STATUS "Generated ${PROJECT_NAME} for ${CMAKE_CXX_COMPILER_ID} in ${CMAKE_BUILD_TYPE} mode!")
message(STATUS "Release Flags: ${CMAKE_CXX_FLAGS_RELEASE}")
message(STATUS "Debug Flags: ${CMAKE_CXX_FLAGS_DEBUG}")
