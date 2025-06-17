cmake_minimum_required(VERSION 3.10)
project(BellhopPropagationModel VERSION 1.0.0)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 构建选项
option(BUILD_EXECUTABLE "Build executable version" ON)
option(BUILD_SHARED_LIBS "Build shared library version" ON)

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

# 查找Python
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

# 打印Python信息
message(STATUS "Python3 version: ${Python3_VERSION}")
message(STATUS "Python3 executable: ${Python3_EXECUTABLE}")
message(STATUS "Python3 libraries: ${Python3_LIBRARIES}")
message(STATUS "Python3 include dirs: ${Python3_INCLUDE_DIRS}")

# 检查Python库类型并处理PIC问题，同时设置RPATH
if(Python3_LIBRARIES)
    foreach(lib ${Python3_LIBRARIES})
        if(EXISTS "${lib}")
            message(STATUS "Python library found: ${lib}")
            
            # 检查库类型
            get_filename_component(PYTHON_LIB_EXT "${lib}" EXT)
            if(PYTHON_LIB_EXT STREQUAL ".a")
                message(STATUS "  -> Static library detected, enabling PIC compilation")
            endif()
            
            # 检查是否为符号链接
            get_filename_component(real_lib "${lib}" REALPATH)
            if(NOT "${lib}" STREQUAL "${real_lib}")
                message(STATUS "  -> Symlink to: ${real_lib}")
            endif()
        else()
            message(WARNING "Python library not found: ${lib}")
        endif()
    endforeach()
    
    # 获取Python库目录用于RPATH设置
    get_filename_component(PYTHON_LIB_DIR "${Python3_LIBRARIES}" DIRECTORY)
    message(STATUS "Python library directory: ${PYTHON_LIB_DIR}")
endif()

# 在Linux系统上，设置RPATH以便运行时能找到动态库
if(UNIX AND NOT APPLE)
    # 启用RPATH
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    
    # 添加常见的Python库路径到RPATH
    list(APPEND CMAKE_INSTALL_RPATH 
        "/usr/lib/x86_64-linux-gnu"
        "/usr/lib64"
        "/usr/lib"
        "/usr/local/lib"
    )
    
    # 如果找到了Python库目录，也添加到RPATH
    if(PYTHON_LIB_DIR)
        list(APPEND CMAKE_INSTALL_RPATH "${PYTHON_LIB_DIR}")
    endif()
    
    message(STATUS "RPATH will include: ${CMAKE_INSTALL_RPATH}")
endif()

# 包含目录
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${Python3_INCLUDE_DIRS})

# 编译标志
add_compile_definitions(PY_SSIZE_T_CLEAN)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -finput-charset=UTF-8 -fexec-charset=UTF-8")

# 共享库需要位置无关代码
if(BUILD_SHARED_LIBS)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif()

# 添加额外的库链接
set(EXTRA_LIBS "")

# 添加必要的系统库支持
if(UNIX)
    # 查找动态链接库
    find_library(DL_LIBRARY dl)
    if(DL_LIBRARY)
        list(APPEND EXTRA_LIBS ${DL_LIBRARY})
    endif()
    
    # 添加pthread支持（Python 3.10+需要）
    find_package(Threads REQUIRED)
    if(Threads_FOUND)
        list(APPEND EXTRA_LIBS Threads::Threads)
        message(STATUS "Found Threads library: ${CMAKE_THREAD_LIBS_INIT}")
    endif()
    
    # 添加math库
    find_library(M_LIBRARY m)
    if(M_LIBRARY)
        list(APPEND EXTRA_LIBS ${M_LIBRARY})
    endif()
endif()

# 打印额外库信息
if(EXTRA_LIBS)
    message(STATUS "Extra libraries to link: ${EXTRA_LIBS}")
endif()

# 源文件（使用 Nuitka 版本）
set(LIB_SOURCES src/BellhopPropagationModel_nuitka.cpp)
set(EXE_SOURCES src/BellhopPropagationModel_exe_nuitka.cpp)

# 创建动态库
if(BUILD_SHARED_LIBS)
    add_library(BellhopPropagationModel SHARED ${LIB_SOURCES})
    target_link_libraries(BellhopPropagationModel ${Python3_LIBRARIES} ${EXTRA_LIBS})
    target_include_directories(BellhopPropagationModel PRIVATE ${Python3_INCLUDE_DIRS})
    
    # 设置输出目录
    set_target_properties(BellhopPropagationModel PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib
        POSITION_INDEPENDENT_CODE ON
    )
    
    # 设置RPATH以便运行时找到Python动态库
    if(UNIX AND Python3_LIBRARIES)
        get_filename_component(PYTHON_LIB_DIR ${Python3_LIBRARIES} DIRECTORY)
        set_target_properties(BellhopPropagationModel PROPERTIES
            INSTALL_RPATH "${PYTHON_LIB_DIR}"
            BUILD_WITH_INSTALL_RPATH TRUE
        )
    endif()
    
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

# 安装头文件
install(FILES include/BellhopPropagationModelInterface.h
    DESTINATION include
)

