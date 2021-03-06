
include_directories(BEFORE ${CMAKE_CURRENT_LIST_DIR})
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME library)

#----------------------------------------------------------------------------------------#
#
#                       JUMP AND STUBS LIBRARIES
#
#----------------------------------------------------------------------------------------#

message(STATUS "Adding source/jump...")
add_subdirectory(jump)

message(STATUS "Adding source/stubs...")
add_subdirectory(stubs)

#----------------------------------------------------------------------------------------#
# Locate sources and headers for this project
# - headers are included so they will show up in IDEs
#
file(GLOB c_headers                      ${CMAKE_CURRENT_LIST_DIR}/timemory/*.h)
file(GLOB cxx_headers                    ${CMAKE_CURRENT_LIST_DIR}/timemory/*.hpp)
file(GLOB cxx_headers_variadic           ${CMAKE_CURRENT_LIST_DIR}/timemory/variadic/*.hpp)
file(GLOB_RECURSE cxx_headers_backends   ${CMAKE_CURRENT_LIST_DIR}/timemory/backends/*.hpp)
file(GLOB_RECURSE cxx_headers_components ${CMAKE_CURRENT_LIST_DIR}/timemory/components/*.hpp)
file(GLOB cxx_headers_mpl           ${CMAKE_CURRENT_LIST_DIR}/timemory/mpl/*.hpp)
file(GLOB cxx_headers_general       ${CMAKE_CURRENT_LIST_DIR}/timemory/general/*.hpp)
file(GLOB cxx_headers_data          ${CMAKE_CURRENT_LIST_DIR}/timemory/data/*.hpp)
file(GLOB cxx_headers_utility       ${CMAKE_CURRENT_LIST_DIR}/timemory/utility/*.hpp)
file(GLOB cxx_headers_bits          ${CMAKE_CURRENT_LIST_DIR}/timemory/bits/*.hpp
                                    ${CMAKE_CURRENT_LIST_DIR}/timemory/bits/*.h
                                    ${CMAKE_CURRENT_LIST_DIR}/timemory/bits/*.icpp)
file(GLOB compat_headers            ${CMAKE_CURRENT_LIST_DIR}/timemory/compat/*.h
                                    ${CMAKE_CURRENT_LIST_DIR}/timemory/compat/*.hpp)
file(GLOB_RECURSE cereal_headers    ${CMAKE_CURRENT_LIST_DIR}/cereal/include/*.hpp
                                    ${CMAKE_CURRENT_LIST_DIR}/cereal/include/*.h
                                    ${CMAKE_CURRENT_LIST_DIR}/cereal/include/*.hh)
file(GLOB c_sources                 ${CMAKE_CURRENT_LIST_DIR}/*.c)
file(GLOB cxx_sources               ${CMAKE_CURRENT_LIST_DIR}/*.cpp)

set(_CATEGORIES backends mpl utility variadic)
# bits folder
set(cxx_headers_category_bits)
foreach(_CATEGORY ${_CATEGORIES})
    file(GLOB cxx_headers_${_CATEGORY}_bits
        ${CMAKE_CURRENT_LIST_DIR}/timemory/${_CATEGORY}/bits/*.h
        ${CMAKE_CURRENT_LIST_DIR}/timemory/${_CATEGORY}/bits/*.hpp
        ${CMAKE_CURRENT_LIST_DIR}/timemory/${_CATEGORY}/bits/*.icpp)
    list(APPEND cxx_headers_category_bits ${cxx_headers_${_CATEGORY}_bits})
endforeach()

# all the headers
set(timemory_glob_headers
    ${c_headers} ${cxx_headers} ${cxx_headers_variadic}
    ${cxx_headers_backends} ${cxx_headers_components} ${cxx_headers_mpl}
    ${cxx_headers_utility} ${cxx_headers_bits} ${cxx_headers_data}
    ${cxx_headers_category_bits} ${cxx_headers_general} ${compat_headers})

if(TIMEMORY_SOURCE_GROUP)
    source_group(TREE ${CMAKE_CURRENT_LIST_DIR} FILES ${timemory_glob_headers})
endif()

# this is only needed for windows
file(GLOB pyheaders ${CMAKE_CURRENT_LIST_DIR}/python/*.hpp)
file(GLOB pysources ${CMAKE_CURRENT_LIST_DIR}/python/*.cpp)

#----------------------------------------------------------------------------------------#
# build library setup
#
# directly compile sources
set(C_LIBRARY_SOURCES       ${c_sources}   ${c_headers})
set(CXX_LIBRARY_SOURCES     ${cxx_sources} ${timemory_glob_headers} ${cereal_headers})

#----------------------------------------------------------------------------------------#
# build the C++ libraries
#
set(_USE_EXTERN TIMEMORY_USE_EXTERN)
if(WIN32)
    set(_USE_EXTERN )
endif()

set(_ARCH_LIBRARY )
if(TIMEMORY_USE_ARCH)
    set(_ARCH_LIBRARY timemory-arch)
endif()

set(_ANALYSIS_TOOLS timemory-analysis-tools)
if(NOT _GPERF_IN_LIBRARY)
    set(_ANALYSIS_TOOLS)
endif()

set(_LINKER_LANGUAGE CXX)
if(TIMEMORY_USE_CUDA AND CMAKE_CUDA_COMPILER)
    set(_LINKER_LANGUAGE CUDA)
endif()

#----------------------------------------------------------------------------------------#
#
#                   Intermediate libraries
#
#----------------------------------------------------------------------------------------#

message(STATUS "Adding source/timemory...")
add_subdirectory(timemory)


#----------------------------------------------------------------------------------------#
#
#                       MASTER CXX libraries
#
#----------------------------------------------------------------------------------------#

get_property(CXX_EXTRA_SOURCES GLOBAL PROPERTY TIMEMORY_CXX_LIBRARY_SOURCES)

timemory_get_property_depends(TIMEMORY_SHARED_GLOBAL_LIBRARIES SHARED GLOBAL)
timemory_get_property_depends(TIMEMORY_STATIC_GLOBAL_LIBRARIES STATIC GLOBAL)
timemory_get_property_depends(TIMEMORY_SHARED_EXTERN_LIBRARIES SHARED EXTERN)
timemory_get_property_depends(TIMEMORY_STATIC_EXTERN_LIBRARIES STATIC EXTERN)
timemory_get_property_depends(TIMEMORY_SHARED_COMPONENT_LIBRARIES SHARED COMPONENT)
timemory_get_property_depends(TIMEMORY_STATIC_COMPONENT_LIBRARIES STATIC COMPONENT)
timemory_get_property_depends(TIMEMORY_SHARED_USER_BUNDLE_LIBRARIES SHARED USER_BUNDLE)
timemory_get_property_depends(TIMEMORY_STATIC_USER_BUNDLE_LIBRARIES STATIC USER_BUNDLE)
timemory_get_property_depends(TIMEMORY_SHARED_FACTORY_LIBRARIES SHARED FACTORY)
timemory_get_property_depends(TIMEMORY_STATIC_FACTORY_LIBRARIES STATIC FACTORY)

if(CMAKE_CUDA_COMPILER)
    set_source_files_properties(${cxx_sources} PROPERTIES
        LANGUAGE CUDA
        LINKER_LANGUAGE CUDA)
endif()

if(_BUILD_SHARED_CXX)
    build_library(
        PIC
        TYPE                SHARED
        TARGET_NAME         timemory-cxx-shared
        OUTPUT_NAME         timemory
        LANGUAGE            CXX
        LINKER_LANGUAGE     ${_LINKER_LANGUAGE}
        OUTPUT_DIR          ${PROJECT_BINARY_DIR}
        SOURCES             ${CXX_LIBRARY_SOURCES}
                            ${CXX_EXTERN_TARGETS}
                            ${CXX_EXTRA_SOURCES}
        CXX_COMPILE_OPTIONS ${${PROJECT_NAME}_CXX_COMPILE_OPTIONS}
        COMPILE_DEFINITIONS ${_USE_EXTERN})

    target_link_libraries(timemory-cxx-shared PUBLIC
        timemory-external-shared
        timemory-vector
        timemory-extern
        timemory-headers
        ${TIMEMORY_SHARED_GLOBAL_LIBRARIES}
        ${TIMEMORY_SHARED_EXTERN_LIBRARIES}
        ${TIMEMORY_SHARED_COMPONENT_LIBRARIES}
        ${TIMEMORY_SHARED_USER_BUNDLE_LIBRARIES}
        ${TIMEMORY_SHARED_FACTORY_LIBRARIES})

    target_link_libraries(timemory-cxx-shared PRIVATE
        timemory-compile-options
        timemory-develop-options
        # timemory-hidden-visibility
        ${_ANALYSIS_TOOLS}
        ${_ARCH_LIBRARY})

    target_compile_definitions(timemory-cxx-shared PUBLIC ${_USE_EXTERN})

    if(TIMEMORY_BUILD_C)
        target_compile_definitions(timemory-cxx-shared PRIVATE TIMEMORY_BUILD_C)
    endif()

    target_include_directories(timemory-cxx-shared PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>)

    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        target_compile_definitions(timemory-cxx-shared PRIVATE DEBUG)
    endif()
endif()

if(_BUILD_STATIC_CXX)

    build_library(
        TYPE                STATIC
        TARGET_NAME         timemory-cxx-static
        OUTPUT_NAME         timemory
        LANGUAGE            CXX
        LINKER_LANGUAGE     ${_LINKER_LANGUAGE}
        OUTPUT_DIR          ${PROJECT_BINARY_DIR}
        SOURCES             ${CXX_LIBRARY_SOURCES}
                            ${CXX_EXTERN_TARGETS}
                            ${CXX_EXTRA_SOURCES}
        CXX_COMPILE_OPTIONS ${${PROJECT_NAME}_CXX_COMPILE_OPTIONS}
        COMPILE_DEFINITIONS ${_USE_EXTERN})

    target_link_libraries(timemory-cxx-static PUBLIC
        timemory-external-static
        timemory-vector
        timemory-extern
        timemory-headers
        ${TIMEMORY_STATIC_GLOBAL_LIBRARIES}
        ${TIMEMORY_STATIC_EXTERN_LIBRARIES}
        ${TIMEMORY_STATIC_COMPONENT_LIBRARIES}
        ${TIMEMORY_STATIC_USER_BUNDLE_LIBRARIES}
        ${TIMEMORY_STATIC_FACTORY_LIBRARIES})

    target_link_libraries(timemory-cxx-static PRIVATE
        timemory-compile-options
        timemory-develop-options
        # timemory-hidden-visibility
        ${_ANALYSIS_TOOLS}
        ${_ARCH_LIBRARY})

    if(TIMEMORY_BUILD_C)
        target_compile_definitions(timemory-cxx-static PRIVATE TIMEMORY_BUILD_C)
    endif()

    target_include_directories(timemory-cxx-static PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>)

    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        target_compile_definitions(timemory-cxx-static PRIVATE DEBUG)
    endif()
endif()

if(WIN32)
    if(_BUILD_SHARED_CXX AND _BUILD_STATIC_CXX)
        # make sure on Windows, static is built first. There is something weird
        # happening here when built in parallel...
        add_dependencies(timemory-cxx-shared timemory-cxx-static)
    endif()
    if(_BUILD_SHARED_CXX)
        target_compile_definitions(timemory-cxx-shared
            PRIVATE TIMEMORY_DLL_EXPORT INTERFACE TIMEMORY_DLL_IMPORT)
    endif()
endif()

#----------------------------------------------------------------------------------------#
#
#                       EXTERN C libraries
#
#----------------------------------------------------------------------------------------#

if(TIMEMORY_BUILD_C)

    if(_BUILD_SHARED_CXX)
        build_library(
            PIC
            TYPE                SHARED
            TARGET_NAME         timemory-c-shared
            OUTPUT_NAME         ctimemory
            LANGUAGE            C
            LINKER_LANGUAGE     ${_LINKER_LANGUAGE}
            OUTPUT_DIR          ${PROJECT_BINARY_DIR}
            SOURCES             ${C_LIBRARY_SOURCES}
            C_COMPILE_OPTIONS   ${${PROJECT_NAME}_C_COMPILE_OPTIONS}
            LINK_LIBRARIES      timemory-external-shared
                                PRIVATE
                                    timemory-compile-options
                                    timemory-develop-options
                                    # timemory-hidden-visibility
                                    timemory-cxx-shared
                                    ${_ANALYSIS_TOOLS}
                                    ${_ARCH_LIBRARY})
                                  
        target_include_directories(timemory-c-shared PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>)
        
        if(WIN32)
            target_compile_definitions(timemory-c-shared
                PRIVATE TIMEMORY_CDLL_EXPORT INTERFACE TIMEMORY_CDLL_IMPORT)
        endif()
    endif()

    if(_BUILD_STATIC_CXX)

        build_library(
            TYPE                STATIC
            TARGET_NAME         timemory-c-static
            OUTPUT_NAME         ctimemory
            LANGUAGE            C
            LINKER_LANGUAGE     ${_LINKER_LANGUAGE}
            OUTPUT_DIR          ${PROJECT_BINARY_DIR}
            SOURCES             ${C_LIBRARY_SOURCES}
            C_COMPILE_OPTIONS   ${${PROJECT_NAME}_C_COMPILE_OPTIONS}
            LINK_LIBRARIES      timemory-external-static
	                        PRIVATE
                                    timemory-compile-options
                                    timemory-develop-options
                                    # timemory-hidden-visibility
                                    timemory-cxx-static
                                    ${_ANALYSIS_TOOLS}
                                    ${_ARCH_LIBRARY})

        target_include_directories(timemory-c-static PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>)
    endif()

    if(WIN32 AND _BUILD_SHARED_CXX AND _BUILD_STATIC_CXX)
        add_dependencies(timemory-c-shared timemory-c-static)
    endif()
endif()


#----------------------------------------------------------------------------------------#
#
#                       TOOL executables and libraries
#
#----------------------------------------------------------------------------------------#
#
# timem wrapper tool, mpip, etc.
#
message(STATUS "Adding source/tools...")
add_subdirectory(tools)

set(_OMPT_LIB)
if(TARGET timemory-ompt-static)
    set(_OMPT_LIB timemory-ompt-static)
    list(APPEND TIMEMORY_TOOL_LIBRARIES timemory-ompt-static)
endif()

if(TARGET timemory-ompt-shared)
    set(_OMPT_LIB timemory-ompt-shared)
    list(APPEND TIMEMORY_TOOL_LIBRARIES timemory-ompt-shared)
endif()

if(TARGET timemory-mpip-shared)
    target_compile_definitions(timemory-mpip-library INTERFACE TIMEMORY_USE_MPIP_LIBRARY)
    target_link_libraries(timemory-mpip-library INTERFACE timemory-mpip-shared)
    list(APPEND TIMEMORY_TOOL_LIBRARIES timemory-mpip-shared)
else()
    inform_empty_interface(timemory-mpip-library "MPIP standalone instrumentation library")
endif()

if(_OMPT_LIB)
    target_compile_definitions(timemory-ompt-library INTERFACE TIMEMORY_USE_OMPT_LIBRARY)
    target_link_libraries(timemory-ompt-library INTERFACE timemory-ompt ${_OMPT_LIB})
else()
    inform_empty_interface(timemory-ompt-library "OpenMP stand-alone instrumentation library")
endif()

#----------------------------------------------------------------------------------------#
#
#                       INSTALL and EXPORT
#
#----------------------------------------------------------------------------------------#

list(REMOVE_DUPLICATES TIMEMORY_COMPILED_LIBRARIES)

# C/C++ compiled libraries
install(
    TARGETS ${TIMEMORY_COMPILED_LIBRARIES} ${TIMEMORY_TOOL_LIBRARIES}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
    EXPORT ${PROJECT_NAME}-library-depends)

get_property(timemory_headers GLOBAL PROPERTY TIMEMORY_HEADERS)
get_property(timemory_sources GLOBAL PROPERTY TIMEMORY_SOURCES)

list(APPEND timemory_headers ${timemory_sources} ${timemory_glob_headers})
list(REMOVE_DUPLICATES timemory_headers)

install_header_files(${timemory_headers})

# Install the export set for use with the install-tree
install(EXPORT ${PROJECT_NAME}-library-depends
    DESTINATION ${CMAKE_INSTALL_CONFIGDIR}
    NAMESPACE ${PROJECT_NAME}::)

get_property(TIMEMORY_INTERMEDIATE_LIBRARIES GLOBAL PROPERTY TIMEMORY_INTERMEDIATE_TARGETS)

set(LIBRARIES ${TIMEMORY_COMPILED_LIBRARIES}
              ${TIMEMORY_INTERFACE_LIBRARIES}
              ${TIMEMORY_INTERMEDIATE_LIBRARIES}
              ${TIMEMORY_PACKAGE_LIBRARIES}
              ${TIMEMORY_TOOL_LIBRARIES})

export(TARGETS  ${LIBRARIES}
    NAMESPACE   ${PROJECT_NAME}::
    FILE        ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-build.cmake)


#----------------------------------------------------------------------------------------#
#
#                       PYTHON Bindings
#
#----------------------------------------------------------------------------------------#
#
# Python bindings
#
message(STATUS "Adding source/python...")
add_subdirectory(python)

#
# install the plotting.py module as a Python executable
# named 'timemory-plotter' as C++ JSON outputs can use this
# to generate plots
#
if((TIMEMORY_BUILD_PYTHON OR TIMEMORY_USE_PYTHON) AND NOT SKBUILD)
    configure_file(${PROJECT_SOURCE_DIR}/timemory/plotting/__main__.py
        ${PROJECT_BINARY_DIR}/timemory-plotter @ONLY)

    configure_file(${PROJECT_SOURCE_DIR}/timemory/roofline/__main__.py
        ${PROJECT_BINARY_DIR}/timemory-roofline @ONLY)

    install(
        FILES
            ${PROJECT_BINARY_DIR}/timemory-plotter
            ${PROJECT_BINARY_DIR}/timemory-roofline
        DESTINATION
            ${CMAKE_INSTALL_BINDIR}
        PERMISSIONS
            OWNER_EXECUTE OWNER_READ OWNER_WRITE
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ)
endif()

#----------------------------------------------------------------------------------------#
#
#                       Package setup
#
#----------------------------------------------------------------------------------------#

message(STATUS "Configuring packaging...")
include(PackageConfigure)

#----------------------------------------------------------------------------------------#
#
#                       TESTING -- Unit tests
#
#----------------------------------------------------------------------------------------#

message(STATUS "Adding source/tests...")
add_subdirectory(tests)

set(TIMEMORY_MAKEFILE_COMPILED_LIBRARIES
    ${TIMEMORY_COMPILED_LIBRARIES}
    PARENT_SCOPE)

set(TIMEMORY_MAKEFILE_INTERFACE_LIBRARIES
    ${TIMEMORY_INTERFACE_LIBRARIES}
    ${${PROJECT_NAME_UC}_INTERFACE_LIBRARIES}
    PARENT_SCOPE)
