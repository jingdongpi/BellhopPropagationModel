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
        // 预加载Python共享库以解决符号链接问题
        void* python_lib = dlopen("libpython3.9.so", RTLD_LAZY | RTLD_GLOBAL);
        if (!python_lib) {
            python_lib = dlopen("libpython3.9.so.1.0", RTLD_LAZY | RTLD_GLOBAL);
        }
        
        // 初始化Python解释器
        if (!Py_IsInitialized()) {
            Py_SetProgramName(L"BellhopPropagationModel");
            Py_Initialize();
            if (!Py_IsInitialized()) {
                std::cerr << "Failed to initialize Python interpreter" << std::endl;
                return false;
            }
            
            // 设置UTF-8编码环境
            PyRun_SimpleString("import sys, os");
            PyRun_SimpleString("os.environ['PYTHONIOENCODING'] = 'utf-8'");
            PyRun_SimpleString("sys.stdout.reconfigure(encoding='utf-8', errors='ignore')");
            PyRun_SimpleString("sys.stderr.reconfigure(encoding='utf-8', errors='ignore')");
        }
        
        // 自动添加lib目录到Python搜索路径
        // 通过dladdr获取当前动态库的路径，然后推断lib目录位置
        Dl_info dl_info;
        if (dladdr((void*)initialize_python_environment, &dl_info) && dl_info.dli_fname) {
            std::filesystem::path lib_path = std::filesystem::path(dl_info.dli_fname).parent_path();
            std::string python_code = "import sys; lib_path = r'" + lib_path.string() + 
                                    "'; lib_path not in sys.path and sys.path.insert(0, lib_path)";
            PyRun_SimpleString(python_code.c_str());
        }
        
        // 导入bellhop_wrapper模块（现在应该能从lib目录找到）
        bellhop_module = PyImport_ImportModule("bellhop_wrapper");
        if (!bellhop_module) {
            PyErr_Print();
            return false;
        }
        
        // 验证关键函数是否存在
        PyObject* solve_function = PyObject_GetAttrString(bellhop_module, "solve_bellhop_propagation");
        if (!solve_function || !PyCallable_Check(solve_function)) {
            if (solve_function) Py_DECREF(solve_function);
            return false;
        }
        Py_DECREF(solve_function);
        
        python_initialized = true;
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
        python_initialized = false;
    } catch (...) {
        python_initialized = false;
    }
}

/**
 * 主计算函数：Bellhop声传播模型求解
 */
extern "C" int SolveBellhopPropagationModel(const std::string& json, std::string& outJson) {
    try {
        // 确保Python环境已初始化
        if (!initialize_python_environment()) {
            outJson = R"({"error_code": 500, "error_message": "Failed to initialize Python environment"})";
            return 500;
        }
        
        // 验证输入参数
        if (json.empty()) {
            outJson = R"({"error_code": 400, "error_message": "Input JSON is empty"})";
            return 400;
        }
        
        // 获取Python函数
        PyObject* solve_function = PyObject_GetAttrString(bellhop_module, "solve_bellhop_propagation");
        if (!solve_function || !PyCallable_Check(solve_function)) {
            if (solve_function) Py_DECREF(solve_function);
            outJson = R"({"error_code": 500, "error_message": "solve_bellhop_propagation function not available"})";
            return 500;
        }
        
        // 准备Python参数
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
        
        // 处理调用结果
        if (!result) {
            PyErr_Print();
            outJson = R"({"error_code": 500, "error_message": "Python function call failed"})";
            return 500;
        }
        
        // 提取返回值
        if (PyUnicode_Check(result)) {
            const char* result_str = PyUnicode_AsUTF8(result);
            if (result_str) {
                outJson = std::string(result_str);
                Py_DECREF(result);
                return 200;
            } else {
                Py_DECREF(result);
                outJson = R"({"error_code": 500, "error_message": "Failed to convert Python result to UTF-8"})";
                return 500;
            }
        } else {
            Py_DECREF(result);
            outJson = R"({"error_code": 500, "error_message": "Python function returned non-string result"})";
            return 500;
        }
    } catch (...) {
        outJson = R"({"error_code": 500, "error_message": "Unknown C++ exception"})";
        return 500;
    }
}

/**
 * 获取库版本信息
 */
extern "C" const char* GetBellhopPropagationModelVersion() {
    return "1.0.0-nuitka";
}

/**
 * 库初始化函数
 */
extern "C" void __attribute__((constructor)) init_library() {
    // 库加载时的简单初始化
}

/**
 * 库清理函数
 */
extern "C" void __attribute__((destructor)) cleanup_library() {
    if (bellhop_module) {
        try {
            Py_DECREF(bellhop_module);
            bellhop_module = nullptr;
        } catch (...) {
            // 忽略清理时的异常
        }
    }
    python_initialized = false;
}
