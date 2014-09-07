# - Find Resiprocate include dirs and libraries
# Use this module by invoking find_package with the form:
#  find_package(Resiprocate
#    [version] [EXACT]      # Minimum or EXACT version e.g. 1.9
#    [REQUIRED]             # Fail with error if Resiprocate is not found
#    [COMPONENTS <libs>...] # Resiprocate libraries by their canonical name
#    )                      # e.g. "resip" for "libresip"
# This module finds headers and requested component libraries OR a CMake
# package configuration file provided by a "Resiprocate CMake" build.  For the
# latter case skip to the "Resiprocate CMake" section below.  For the former
# case results are reported in variables:
#  Resiprocate_FOUND            - True if headers and requested libraries were found
#  Resiprocate_INCLUDE_DIRS     - Resiprocate include directories
#  Resiprocate_LIBRARY_DIRS     - Link directories for Resiprocate libraries
#  Resiprocate_LIBRARIES        - Resiprocate component libraries to be linked
#  Resiprocate_<C>_FOUND        - True if component <C> was found (<C> is upper-case)
#  Resiprocate_<C>_LIBRARY      - Libraries to link for component <C> (may include

# This module reads hints about search locations from variables:
#  Resiprocate_ROOT             - Preferred installation prefix
#   (or ResiprocateROOT)
#  Resiprocate_ADDITIONAL_VERSIONS
#                         - List of Resiprocate versions not known to this module
#                           (Resiprocate install locations may contain the version)

cmake_minimum_required(VERSION 2.8)

if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
    set(Platform "x64")
else()
    set(Platform "Win32")
endif()

# If Resiprocate_DIR is not set, look for ResiprocateROOT and Resiprocate_ROOT
# as alternatives, since these are more conventional for Resiprocate.
if ("$ENV{Resiprocate_DIR}" STREQUAL "")
    if (NOT "$ENV{Resiprocate_ROOT}" STREQUAL "")
        set(ENV{Resiprocate_DIR} $ENV{Resiprocate_ROOT})
    elseif (NOT "$ENV{ResiprocateROOT}" STREQUAL "")
        set(ENV{Resiprocate_DIR} $ENV{ResiprocateROOT})
    endif()
endif()
mark_as_advanced(Resiprocate_DIR)
set(Resiprocate_ROOT_DIR $ENV{Resiprocate_DIR})

# Check the version of Resiprocate against the requested version.
if(Resiprocate_FIND_VERSION AND NOT Resiprocate_FIND_VERSION_MINOR)
    message(SEND_ERROR "When requesting a specific version of Resiprocate, you must provide at least the major and minor version numbers, e.g., 1.9")
endif()


if (Resiprocate_FIND_VERSION_EXACT)
    # The version may appear in a directory with or without the patch
    # level, even when the patch level is non-zero.
    set(_Resiprocate_TEST_VERSIONS
        "${Resiprocate_FIND_VERSION_MAJOR}.${Resiprocate_FIND_VERSION_MINOR}.${Resiprocate_FIND_VERSION_PATCH}"
        "${Resiprocate_FIND_VERSION_MAJOR}.${Resiprocate_FIND_VERSION_MINOR}")
else()
    # The user has not requested an exact version.  Among known
    # versions, find those that are acceptable to the user request.
    set (_Resiprocate_KNOWN_VERSIONS
        "1.0" "1.0.1" "1.0.3"
        "1.1"
        "1.2" "1.2.2" "1.2.3"
        "1.3" "1.3.1" "1.3.2" "1.3.3" "1.3.4"
        "1.4" "1.4.1"
        "1.5"
        "1.6"
        "1.7"
        "1.8" "1.8.0" "1.8.1" "1.8.2" "1.8.3" "1.8.4" "1.8.5" "1.8.6" "1.8.7" "1.8.8" "1.8.9" "1.8.10" "1.8.11" "1.8.12" "1.8.13" "1.8.14"
        "1.9" "1.9.0" "1.9.1" "1.9.2" "1.9.3" "1.9.4" "1.9.5" "1.9.6" "1.9.7")
    if(Resiprocate_FIND_VERSION)
        set(_Resiprocate_FIND_VERSION_SHORT "${Resiprocate_FIND_VERSION_MAJOR}.${Resiprocate_FIND_VERSION_MINOR}")
        # Select acceptable versions.
        set(_Resiprocate_TEST_VERSIONS)
        foreach(version ${_Resiprocate_KNOWN_VERSIONS})
            if(NOT "${version}" VERSION_LESS "${Resiprocate_FIND_VERSION}")
                # This version is high enough.
                list(APPEND _Resiprocate_TEST_VERSIONS "${version}")
            elseif("${version}.99" VERSION_EQUAL "${_Resiprocate_FIND_VERSION_SHORT}.99")
                # This version is a short-form for the requested version with the patch level dropped.
                list(APPEND _Resiprocate_TEST_VERSIONS "${version}")
            endif()
        endforeach()
    else()
        # Any version is acceptable.
        set(_Resiprocate_TEST_VERSIONS "${_Resiprocate_KNOWN_VERSIONS}")
    endif()
endif()
list(SORT _Resiprocate_TEST_VERSIONS)
list(REVERSE _Resiprocate_TEST_VERSIONS)

macro(_Resiprocate_FIND_LIBRARY_BY_NAME _component _known_names output_is_found output_library_name)
    list(FIND Resiprocate_FIND_COMPONENTS _component _using_component)
    if (NOT Resiprocate_FIND_COMPONENTS OR _using_component GREATER -1)
        set(_search_names "")
        foreach (version ${_Resiprocate_TEST_VERSIONS})
            foreach(known_name ${_known_names})
                list(APPEND _search_names "${known_name}-${version}")
            endforeach()
        endforeach()
        list(APPEND _search_names ${_known_names})
        # TODO: find libraries under Resiprocate_ROOT_DIR when it set
        find_library(${output_library_name} NAMES ${_search_names} PATHS ${Resiprocate_LIBRARY_SEARCH_PATHS})
        if ("${${output_library_name}}" STREQUAL "${output_library_name}-NOTFOUND")
            set(${output_is_found} 0)
            list(APPEND _Resiprocate_ATLEAST_ONE_COMPONENT_NOT_FOUND "${component}")
        else()
            set(${output_is_found} 1)
            list(APPEND _Resiprocate_COMPONENTS_FOUND ${_component})
            list(APPEND Resiprocate_LIBRARIES "${${output_library_name}}")
        endif()
        if (Resiprocate_DEBUG)
            message(STATUS "[${${output_is_found}}] ${_component}: ${${output_library_name}} (${_search_names})")
        endif()
    endif()
endmacro()

if (Resiprocate_LIBRARY_DIR)
    set(Resiprocate_LIBRARY_SEARCH_PATHS ${Resiprocate_LIBRARY_DIR} NO_DEFAULT_PATH)
else()
    set(Resiprocate_LIBRARY_SEARCH_PATHS "")
    if (Resiprocate_LIBRARYDIR)
        list(APPEND Resiprocate_LIBRARY_SEARCH_PATHS ${Resiprocate_LIBRARYDIR})
    endif()
    if (Resiprocate_ROOT_DIR)
        list(APPEND Resiprocate_LIBRARY_SEARCH_PATHS
            ${Resiprocate_ROOT_DIR}/lib
            ${Resiprocate_ROOT_DIR}/../lib
            ${Resiprocate_ROOT_DIR}/../lib/${CMAKE_LIBRARY_ARCHITECTURE})
    endif()

    if(Resiprocate_NO_SYSTEM_PATHS)
        list(APPEND Resiprocate_LIBRARY_SEARCH_PATHS NO_CMAKE_SYSTEM_PATH)
    else()
        list(APPEND Resiprocate_LIBRARY_SEARCH_PATHS
            c:/resiprocate/${Platform}/${CMAKE_CFG_INTDIR}
            /sw/local/lib)
    endif()
endif()


if (WIN32)
    if ("${Resiprocate_ROOT_DIR}" STREQUAL "")
        set (Resiprocate_ROOT_DIR d:/Development/git/resiprocate-1.9.7)
    endif()
    set (Resiprocate_INCLUDE_DIR "${RESIPROCATE_ROOT_DIR}")
    set (Resiprocate_LIBRARY_DIR "${RESIPROCATE_ROOT_DIR}/${Platform}/${CMAKE_CFG_INTDIR}")
    set (Resiprocate_LIBRARIES resiprocate rutil reprolib dum)
elseif(UNIX)
    if (NOT "${Resiprocate_ROOT_DIR}" STREQUAL "")
        set (Resiprocate_INCLUDE_DIR "${Resiprocate_ROOT_DIR}")
    endif()
    _Resiprocate_FIND_LIBRARY_BY_NAME(rutil  "rutil"             Resiprocate_Rutil_FOUND   Resiprocate_Rutil_LIBRARY_NAME)
    _Resiprocate_FIND_LIBRARY_BY_NAME(resip  "resip;resiprocate" Resiprocate_Resip_FOUND   Resiprocate_Resip_LIBRARY_NAME)
    _Resiprocate_FIND_LIBRARY_BY_NAME(repro  "repro"             Resiprocate_Repro_FOUND   Resiprocate_Repro_LIBRARY_NAME)
    _Resiprocate_FIND_LIBRARY_BY_NAME(dum    "dum"               Resiprocate_Dum_FOUND     Resiprocate_Dum_LIBRARY_NAME)
    _Resiprocate_FIND_LIBRARY_BY_NAME(recon  "recon"             Resiprocate_Recon_FOUND   Resiprocate_Recon_LIBRARY_NAME)
    _Resiprocate_FIND_LIBRARY_BY_NAME(reflow "reflow"            Resiprocate_Reflow_FOUND  Resiprocate_Reflow_LIBRARY_NAME)

    if (NOT "${_Resiprocate_ATLEAST_ONE_COMPONENT_NOT_FOUND}" STREQUAL "")
        set(Resiprocate_FOUND 0)
        message(STATUS "Resiprocate components not found:")
        foreach(item ${_Resiprocate_ATLEAST_ONE_COMPONENT_NOT_FOUND})
            message(STATUS "    ${item}")
        endforeach()
    elseif (NOT "${_Resiprocate_COMPONENTS_FOUND}" STREQUAL "")
        set(Resiprocate_FOUND 1)
        message(STATUS "Resiprocate components found:")
        foreach(item ${_Resiprocate_COMPONENTS_FOUND})
            message(STATUS "    ${item}")
        endforeach()
    else()
        set(Resiprocate_FOUND 0)
        message(STATUS "Resiprocate: no components found")
    endif()
endif()

set (Resiprocate_INCLUDE_DIRS ${RESIPROCATE_INCLUDE_DIR})
set (Resiprocate_LIBRARY_DIRS ${RESIPROCATE_LIBRARY_DIR})

if (Resiprocate_DEBUG)
    message(STATUS "Resiprocate testing versions= ${_Resiprocate_TEST_VERSIONS}")
    message(STATUS "Resiprocate_ROOT_DIR        = ${Resiprocate_ROOT_DIR}")
    message(STATUS "Resiprocate_FOUND           = ${Resiprocate_FOUND}")
    message(STATUS "Resiprocate_LIBRARIES       = ${Resiprocate_LIBRARIES}")
    message(STATUS "Resiprocate_INCLUDE_DIRS    = ${Resiprocate_INCLUDE_DIRS}")
    message(STATUS "Resiprocate_LIBRARY_DIRS    = ${Resiprocate_LIBRARY_DIRS}")
    message(STATUS "_Resiprocate_ATLEAST_ONE_COMPONENT_NOT_FOUND = '${_Resiprocate_ATLEAST_ONE_COMPONENT_NOT_FOUND}'")
    message(STATUS "_Resiprocate_COMPONENTS_FOUND = '${_Resiprocate_COMPONENTS_FOUND}'")
    message(STATUS "Resiprocate_LIBRARY_SEARCH_PATHS = '${Resiprocate_LIBRARY_SEARCH_PATHS}'")
endif()
