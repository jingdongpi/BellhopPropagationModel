/**
 * Bellhop传播模型 - Nuitka版本动态库实现
 * 
 * 使用Nuitka编译的Python模块实现声传播计算
 * 符合声传播模型接口规范
 */

#include <Python.h>
#include <string>
#include <iostream>
#include <filesystem>
#include <dlfcn.h>
#include "BellhopPropagationModelInterface.h"

// 全局Python解释器状态
static bool python_initialized = false;
static PyObject* bellhop_module = nullptr;

/**
 * 初始化Python环境和Nuitka模块
 */
bool initialize_python_environment() {
    if (python_initialized) {
        return true;
    }
    
    try {
        // 初始化Python解释器
        if (!Py_IsInitialized()) {
            // 设置Python程序名和编码
            Py_SetProgramName(L"BellhopPropagationModel");
            
            Py_Initialize();
            if (!Py_IsInitialized()) {
                std::cerr << "Failed to initialize Python interpreter" << std::endl;
                return false;
            }
            
            // 设置UTF-8编码
            PyRun_SimpleString("import sys");
            PyRun_SimpleString("import io");
            PyRun_SimpleString("import os");
            PyRun_SimpleString("os.environ['PYTHONIOENCODING'] = 'utf-8'");
            PyRun_SimpleString("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')");
            PyRun_SimpleString("sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')");
        }
        
        // 添加当前目录和相关目录到Python路径
        PyRun_SimpleString("import sys");
        PyRun_SimpleString("import os");
        
        // 使用硬编码的绝对路径（临时解决方案）
        PyRun_SimpleString("project_root = '/home/shunli/AcousticProjects/BellhopPropagationModel'");
        PyRun_SimpleString("lib_dir = os.path.join(project_root, 'lib')");
        PyRun_SimpleString("wrapper_dir = os.path.join(project_root, 'python_wrapper')");
        PyRun_SimpleString("core_dir = os.path.join(project_root, 'python_core')");
        
        // 打印路径信息用于调试
        PyRun_SimpleString("print(f'使用项目根目录: {project_root}')");
        PyRun_SimpleString("print(f'库目录: {lib_dir}')");
        PyRun_SimpleString("print(f'库目录存在: {os.path.exists(lib_dir)}')");
        
        // 添加到Python路径
        PyRun_SimpleString("if lib_dir not in sys.path: sys.path.insert(0, lib_dir)");
        PyRun_SimpleString("if wrapper_dir not in sys.path: sys.path.insert(0, wrapper_dir)");
        PyRun_SimpleString("if core_dir not in sys.path: sys.path.insert(0, core_dir)");
        
        // 尝试导入Nuitka编译的包装器模块
        bellhop_module = PyImport_ImportModule("bellhop_wrapper");
        if (!bellhop_module) {
            PyErr_Print();
            std::cerr << "Failed to import Nuitka bellhop_wrapper module, trying fallback..." << std::endl;
            
            // 回退到原始Python包装器模块
            bellhop_module = PyImport_ImportModule("bellhop_wrapper");
            if (!bellhop_module) {
                PyErr_Print();
                std::cerr << "Failed to import fallback bellhop_wrapper module" << std::endl;
                return false;
            }
        }
        
        python_initialized = true;
        std::cout << "✓ Python environment and Nuitka modules initialized successfully" << std::endl;
        return true;
        
    } catch (const std::exception& e) {
        std::cerr << "Exception during Python initialization: " << e.what() << std::endl;
        return false;
    }
}

/**
 * 清理Python环境
 */
void cleanup_python_environment() {
    try {
        if (bellhop_module) {
            Py_DECREF(bellhop_module);
            bellhop_module = nullptr;
        }
        
        // 注意：Py_Finalize() 可能导致段错误，特别是在使用编译模块时
        // 在某些情况下，最好不调用 Py_Finalize()，让操作系统清理
        if (Py_IsInitialized()) {
            // 可选：不调用 Py_Finalize() 来避免段错误
            // Py_Finalize();
            std::cout << "Python 环境保持初始化状态（避免段错误）" << std::endl;
        }
        
        python_initialized = false;
        
    } catch (...) {
        std::cerr << "Exception during Python cleanup, ignoring..." << std::endl;
        python_initialized = false;
    }
}

/**
 * 主计算函数：Bellhop声传播模型求解
 * 
 * @param json 输入JSON字符串
 * @param outJson 输出JSON字符串（引用传递）
 * @return 错误码：200成功，500失败
 */
extern "C" int SolveBellhopPropagationModel(const std::string& json, std::string& outJson) {
    try {
        // 初始化Python环境
        if (!initialize_python_environment()) {
            outJson = R"({"error_code": 500, "error_message": "Failed to initialize Python environment"})";
            return 500;
        }
        
        // 获取Python函数
        PyObject* solve_function = PyObject_GetAttrString(bellhop_module, "solve_bellhop_propagation");
        if (!solve_function) {
            PyErr_Print();
            outJson = R"({"error_code": 500, "error_message": "Failed to get solve_bellhop_propagation function"})";
            return 500;
        }
        
        // 准备参数
        PyObject* input_json = PyUnicode_FromString(json.c_str());
        if (!input_json) {
            Py_DECREF(solve_function);
            outJson = R"({"error_code": 500, "error_message": "Failed to create input JSON string"})";
            return 500;
        }
        
        // 调用Python函数
        PyObject* result = PyObject_CallFunctionObjArgs(solve_function, input_json, NULL);
        
        // 清理参数
        Py_DECREF(input_json);
        Py_DECREF(solve_function);
        
        if (!result) {
            PyErr_Print();
            outJson = R"({"error_code": 500, "error_message": "Python function call failed"})";
            return 500;
        }
        
        // 获取返回值
        if (PyUnicode_Check(result)) {
            const char* result_str = PyUnicode_AsUTF8(result);
            if (result_str) {
                outJson = std::string(result_str);
                Py_DECREF(result);
                return 200;
            }
        }
        
        Py_DECREF(result);
        outJson = R"({"error_code": 500, "error_message": "Invalid return type from Python function"})";
        return 500;
        
    } catch (const std::exception& e) {
        outJson = R"({"error_code": 500, "error_message": "C++ exception: )" + std::string(e.what()) + R"("})";
        return 500;
    } catch (...) {
        outJson = R"({"error_code": 500, "error_message": "Unknown C++ exception"})";
        return 500;
    }
}

/**
 * 库初始化函数（可选）
 */
extern "C" void __attribute__((constructor)) init_library() {
    // 库加载时自动初始化
    initialize_python_environment();
}

/**
 * 库清理函数（可选）
 */
extern "C" void __attribute__((destructor)) cleanup_library() {
    // 注意：在析构函数中调用 Python 清理可能导致段错误
    // 特别是使用 Nuitka 编译的模块时
    // 暂时禁用自动清理，让操作系统处理
    // cleanup_python_environment();
    
    // 只清理模块引用，不调用 Py_Finalize
    if (bellhop_module) {
        try {
            Py_DECREF(bellhop_module);
            bellhop_module = nullptr;
        } catch (...) {
            // 忽略清理时的异常
        }
    }
}
