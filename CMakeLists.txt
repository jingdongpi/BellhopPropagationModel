cmake_minimum_required(VERSION 3.10)
project(BellhopPropagationModel VERSION 1.0.0)

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)
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

# 改进Python库查找策略，优先使用动态库
set(PYTHON_LIB_DIRS "")
set(PYTHON_RUNTIME_LIBS "")

if(Python3_LIBRARIES)
    # 获取Python库目录
    get_filename_component(PYTHON_LIB_DIR "${Python3_LIBRARIES}" DIRECTORY)
    list(APPEND PYTHON_LIB_DIRS "${PYTHON_LIB_DIR}")
    message(STATUS "Primary Python library directory: ${PYTHON_LIB_DIR}")
    
    # 检测Python可执行文件路径，推断可能的库路径
    if(Python3_EXECUTABLE)
        get_filename_component(PYTHON_BIN_DIR "${Python3_EXECUTABLE}" DIRECTORY)
        get_filename_component(PYTHON_PREFIX "${PYTHON_BIN_DIR}" DIRECTORY)
        
        # 常见的Python库路径模式
        set(POTENTIAL_LIB_DIRS
            "${PYTHON_PREFIX}/lib"
            "${PYTHON_PREFIX}/lib64"  
            "${PYTHON_BIN_DIR}/../lib"
            "${PYTHON_BIN_DIR}/../lib64"
        )
        
        foreach(potential_dir ${POTENTIAL_LIB_DIRS})
            if(EXISTS "${potential_dir}" AND NOT "${potential_dir}" IN_LIST PYTHON_LIB_DIRS)
                list(APPEND PYTHON_LIB_DIRS "${potential_dir}")
                message(STATUS "Additional Python library directory: ${potential_dir}")
            endif()
        endforeach()
    endif()
    
    # 查找Python动态库
    set(PYTHON_SO_NAMES 
        "libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.so"
        "libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.so.1.0"
        "libpython${Python3_VERSION_MAJOR}.so"
        "libpython.so"
    )
    
    foreach(lib_dir ${PYTHON_LIB_DIRS})
        foreach(so_name ${PYTHON_SO_NAMES})
            set(potential_so "${lib_dir}/${so_name}")
            if(EXISTS "${potential_so}")
                list(APPEND PYTHON_RUNTIME_LIBS "${potential_so}")
                message(STATUS "Found Python shared library: ${potential_so}")
                break()
            endif()
        endforeach()
    endforeach()
    
    # 检查现有Python库类型
    foreach(lib ${Python3_LIBRARIES})
        if(EXISTS "${lib}")
            message(STATUS "Python library found: ${lib}")
            
            # 检查库类型
            get_filename_component(PYTHON_LIB_EXT "${lib}" EXT)
            if(PYTHON_LIB_EXT STREQUAL ".a")
                message(STATUS "  -> Static library detected, enabling PIC compilation")
            elseif(PYTHON_LIB_EXT STREQUAL ".so")
                message(STATUS "  -> Shared library detected")
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
endif()

# 在Linux系统上，设置RPATH以便运行时能找到动态库
if(UNIX AND NOT APPLE)
    # 启用RPATH
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    
    # 添加检测到的Python库路径到RPATH
    if(PYTHON_LIB_DIRS)
        foreach(lib_dir ${PYTHON_LIB_DIRS})
            list(APPEND CMAKE_INSTALL_RPATH "${lib_dir}")
        endforeach()
    endif()
    
    # 添加常见的系统库路径到RPATH
    list(APPEND CMAKE_INSTALL_RPATH 
        "/usr/lib/x86_64-linux-gnu"
        "/usr/lib/aarch64-linux-gnu"  # ARM64 support
        "/usr/lib64"
        "/usr/lib"
        "/usr/local/lib"
        "/usr/local/lib64"
        "$ORIGIN/../lib"               # 相对路径，程序所在目录的lib目录
        "$ORIGIN"                      # 程序所在目录
    )
    
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
    if(UNIX AND PYTHON_LIB_DIRS)
        # 将所有Python库目录添加到RPATH
        string(REPLACE ";" ":" PYTHON_RPATH "${PYTHON_LIB_DIRS}")
        set_target_properties(BellhopPropagationModel PROPERTIES
            INSTALL_RPATH "${PYTHON_RPATH}:$ORIGIN:$ORIGIN/../lib"
            BUILD_WITH_INSTALL_RPATH TRUE
        )
        message(STATUS "BellhopPropagationModel RPATH: ${PYTHON_RPATH}:$ORIGIN:$ORIGIN/../lib")
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
    
    # 设置RPATH以便运行时找到Python动态库
    if(UNIX AND PYTHON_LIB_DIRS)
        # 将所有Python库目录添加到RPATH
        string(REPLACE ";" ":" PYTHON_RPATH "${PYTHON_LIB_DIRS}")
        set_target_properties(BellhopPropagationModel_exe PROPERTIES
            INSTALL_RPATH "${PYTHON_RPATH}:$ORIGIN:$ORIGIN/../lib"
            BUILD_WITH_INSTALL_RPATH TRUE
        )
        message(STATUS "BellhopPropagationModel_exe RPATH: ${PYTHON_RPATH}:$ORIGIN:$ORIGIN/../lib")
    endif()
    
    # 安装规则
    install(TARGETS BellhopPropagationModel_exe
        RUNTIME DESTINATION bin
    )
endif()

# 安装头文件
install(FILES include/BellhopPropagationModelInterface.h
    DESTINATION include
)

