cmake_minimum_required(VERSION 3.10)
project(BellhopPropagationModel)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 指定Python的具体路径（pyenv环境）
set(Python3_ROOT_DIR "/home/shunli/.pyenv/versions/3.9.19")
set(Python3_EXECUTABLE "/home/shunli/.pyenv/versions/3.9.19/bin/python3")

# 查找Python
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

# 打印Python信息用于调试
message(STATUS "Python3_FOUND: ${Python3_FOUND}")
message(STATUS "Python3_INCLUDE_DIRS: ${Python3_INCLUDE_DIRS}")
message(STATUS "Python3_LIBRARIES: ${Python3_LIBRARIES}")
message(STATUS "Python3_VERSION: ${Python3_VERSION}")
message(STATUS "Python3_EXECUTABLE: ${Python3_EXECUTABLE}")

# 验证Python路径
if(NOT Python3_FOUND)
    message(FATAL_ERROR "Python3 not found. Please check your pyenv installation.")
endif()

# 包含目录
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${Python3_INCLUDE_DIRS})

# 编译标志
add_compile_definitions(PY_SSIZE_T_CLEAN)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -finput-charset=UTF-8 -fexec-charset=UTF-8")

# 源文件
set(LIB_SOURCES src/BellhopPropagationModel.cpp)
set(EXE_SOURCES src/BellhopPropagationModel_exe.cpp)

# 创建动态库
add_library(BellhopPropagationModel SHARED ${LIB_SOURCES})
target_link_libraries(BellhopPropagationModel ${Python3_LIBRARIES})
target_include_directories(BellhopPropagationModel PRIVATE ${Python3_INCLUDE_DIRS})

# 创建可执行文件
add_executable(BellhopPropagationModel_exe ${EXE_SOURCES})
target_link_libraries(BellhopPropagationModel_exe ${Python3_LIBRARIES})
target_include_directories(BellhopPropagationModel_exe PRIVATE ${Python3_INCLUDE_DIRS})

# 设置输出目录
set_target_properties(BellhopPropagationModel PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib
)

set_target_properties(BellhopPropagationModel_exe PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/examples
    OUTPUT_NAME BellhopPropagationModel
)

# 安装规则
install(TARGETS BellhopPropagationModel
    LIBRARY DESTINATION lib
)

install(TARGETS BellhopPropagationModel_exe
    RUNTIME DESTINATION bin
)