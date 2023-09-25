project(ni_task_test)

add_executable(${PROJECT_NAME} main.cpp)
configure_compiler_flags(${PROJECT_NAME})
target_link_libraries(${PROJECT_NAME} ni)