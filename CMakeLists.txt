cmake_minimum_required(VERSION 3.10)
project(BellhopPropagationModel VERSION 1.0.0)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 构建选项
option(BUILD_EXECUTABLE "Build executable version" ON)
option(BUILD_SHARED_LIBS "Build shared library version" ON)
option(USE_CYTHON "Use Cython optimized version" OFF)
option(USE_NUITKA "Use Nuitka compiled modules" ON)
option(BUILD_PYTHON_WRAPPER "Build Python wrapper" ON)
option(PRODUCTION_MODE "Build production version with source code protection" OFF)

# 设置默认构建类型
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# 生产版本的编译优化
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -DNDEBUG")
    if(UNIX)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s")  # Strip symbols
    endif()
endif()

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

# 选择源文件版本
if(PRODUCTION_MODE)
    message(STATUS "Building PRODUCTION version with source code protection")
    set(LIB_SOURCES src/BellhopPropagationModel_production.cpp)
    set(EXE_SOURCES src/BellhopPropagationModel_exe_production.cpp)
    add_compile_definitions(PRODUCTION_MODE=1)
elseif(USE_NUITKA)
    message(STATUS "Building with Nuitka compiled modules")
    set(LIB_SOURCES src/BellhopPropagationModel_nuitka.cpp)
    set(EXE_SOURCES src/BellhopPropagationModel_exe_nuitka.cpp)
    add_compile_definitions(USE_NUITKA=1)
elseif(USE_CYTHON)
    message(STATUS "Building with Cython optimization")
    set(LIB_SOURCES src/BellhopPropagationModel_cython.cpp)
    set(EXE_SOURCES src/BellhopPropagationModel_exe_cython.cpp)
    add_compile_definitions(USE_CYTHON=1)
else()
    message(STATUS "Building with standard Python integration")
    set(LIB_SOURCES src/BellhopPropagationModel.cpp)
    set(EXE_SOURCES src/BellhopPropagationModel_exe.cpp)
endif()

# 源文件
# set(LIB_SOURCES src/BellhopPropagationModel.cpp)
# set(EXE_SOURCES src/BellhopPropagationModel_exe.cpp)

# 添加动态链接库支持（用于dlopen等）
if(UNIX)
    find_library(DL_LIBRARY dl)
    if(DL_LIBRARY)
        set(EXTRA_LIBS ${DL_LIBRARY})
    endif()
endif()

# 添加动态链接库支持（用于dlopen等）
if(UNIX)
    find_library(DL_LIBRARY dl)
    if(DL_LIBRARY)
        set(EXTRA_LIBS ${DL_LIBRARY})
    endif()
endif()

# 创建动态库时添加额外库
if(BUILD_SHARED_LIBS)
    add_library(BellhopPropagationModel SHARED ${LIB_SOURCES})
    target_link_libraries(BellhopPropagationModel ${Python3_LIBRARIES} ${EXTRA_LIBS})
    target_include_directories(BellhopPropagationModel PRIVATE ${Python3_INCLUDE_DIRS})
    
    # 设置输出目录
    set_target_properties(BellhopPropagationModel PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib
    )
    
    # 安装规则
    install(TARGETS BellhopPropagationModel
        LIBRARY DESTINATION lib
    )
endif()

# 创建可执行文件
if(BUILD_EXECUTABLE)
    add_executable(BellhopPropagationModel_exe ${EXE_SOURCES} ${LIB_SOURCES})
    target_link_libraries(BellhopPropagationModel_exe ${Python3_LIBRARIES} ${EXTRA_LIBS})
    target_include_directories(BellhopPropagationModel_exe PRIVATE ${Python3_INCLUDE_DIRS})
    
    # 设置输出目录和名称
    set_target_properties(BellhopPropagationModel_exe PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
        OUTPUT_NAME BellhopPropagationModel
    )
    
    # 安装规则
    install(TARGETS BellhopPropagationModel_exe
        RUNTIME DESTINATION bin
    )
endif()

# 添加Nuitka编译目标（可选）
if(USE_NUITKA AND NOT PRODUCTION_MODE)
    # 提示用户手动编译 Nuitka 模块
    message(STATUS "")
    message(STATUS "=== Nuitka 模块编译提示 ===")
    message(STATUS "请确保已运行 Nuitka 编译脚本:")
    message(STATUS "  python scripts/setup_nuitka_simple.py")
    message(STATUS "或者运行完整版本:")
    message(STATUS "  python scripts/setup_nuitka.py")
    message(STATUS "编译的 .so 文件应位于 lib/ 目录")
    message(STATUS "========================")
    message(STATUS "")
    
    # 可选：自动编译（如果需要的话）
    # add_custom_target(nuitka_modules
    #     COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/setup_nuitka_simple.py
    #     WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    #     COMMENT "Building Nuitka modules"
    #     VERBATIM
    # )
    
    # 可选：添加依赖关系（如果启用自动编译）
    # if(BUILD_SHARED_LIBS)
    #     add_dependencies(BellhopPropagationModel nuitka_modules)
    # endif()
    # if(BUILD_EXECUTABLE)
    #     add_dependencies(BellhopPropagationModel_exe nuitka_modules)
    # endif()
endif()

# 添加Cython编译目标
if(USE_CYTHON AND NOT PRODUCTION_MODE)
    add_custom_target(cython_modules
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/setup_cython.py build_ext
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Building Cython modules"
        VERBATIM
    )
    
    # 确保在构建C++目标之前编译Cython模块
    if(BUILD_SHARED_LIBS)
        add_dependencies(BellhopPropagationModel cython_modules)
    endif()
    if(BUILD_EXECUTABLE)
        add_dependencies(BellhopPropagationModel_exe cython_modules)
    endif()
endif()

# 添加生产级Cython编译目标
if(PRODUCTION_MODE)
    add_custom_target(production_modules
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/setup_fixed_cython.py build_ext
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Building production Cython modules with fixed dependencies"
        VERBATIM
    )
    
    # 确保在构建C++目标之前编译生产模块
    if(BUILD_SHARED_LIBS)
        add_dependencies(BellhopPropagationModel production_modules)
    endif()
    if(BUILD_EXECUTABLE)
        add_dependencies(BellhopPropagationModel_exe production_modules)
    endif()
endif()

# 安装头文件
install(FILES include/BellhopPropagationModelInterface.h
    DESTINATION include
)

