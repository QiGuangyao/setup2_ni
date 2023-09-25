cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
set(CMAKE_CXX_STANDARD 17)

project(ni)

add_library(${PROJECT_NAME} STATIC)

function(configure_compiler_flags project)
    if(MSVC)
        target_compile_options(${project} PRIVATE /W4)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${project} PRIVATE -Wall -Wextra -pedantic)
    else()
        target_compile_options(${project} PRIVATE -Wall -Wextra -pedantic)
    endif()
endfunction(configure_compiler_flags)

if(NOT APPLE)
    set(NI_DIR "C:\\Program Files (x86)\\National Instruments\\Shared\\ExternalCompilerSupport\\C")

    target_include_directories(${PROJECT_NAME} PUBLIC
        ${NI_DIR}/include
    )

    target_link_directories(${PROJECT_NAME} PUBLIC
        ${NI_DIR}/lib64/msvc
    )

    target_link_libraries(${PROJECT_NAME} PUBLIC
         NIDAQmx
    )
endif()

target_sources(${PROJECT_NAME} PUBLIC
        ${CMAKE_SOURCE_DIR}/src/ni.hpp
        ${CMAKE_SOURCE_DIR}/src/ni.cpp
        ${CMAKE_SOURCE_DIR}/src/task_interface.hpp
        ${CMAKE_SOURCE_DIR}/src/task_interface.cpp
)

configure_compiler_flags(${PROJECT_NAME})

add_subdirectory(test/test_task)