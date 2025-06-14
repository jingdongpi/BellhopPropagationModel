#include "BellhopPropagationModelInterface.h"
#include <Python.h>
#include <iostream>
#include <stdexcept>
#include <filesystem>
#include <dlfcn.h>

class CythonEnvironment {
private:
    bool initialized;
    std::string project_dir;
    void* cython_module_handle;
    
public:
    CythonEnvironment() : initialized(false), cython_module_handle(nullptr) {
        if (!Py_IsInitialized()) {
            Py_Initialize();
            if (!Py_IsInitialized()) {
                throw std::runtime_error("Failed to initialize Python");
            }
        }
        initialized = true;
        
        // 获取项目目录 - 从可执行文件路径推断
        try {
            auto exe_path = std::filesystem::read_symlink("/proc/self/exe");
            project_dir = exe_path.parent_path().parent_path();  // 从 examples/ 目录向上一级
        } catch (...) {
            project_dir = std::filesystem::current_path();
        }
        
        // 添加模块路径
        PyRun_SimpleString("import sys");
        
        std::string python_core_path = project_dir + "/python_core";
        std::string python_wrapper_path = project_dir + "/python_wrapper";
        std::string lib_path = project_dir + "/lib";  // Cython编译的.so文件在lib目录
        
        std::string add_path_cmd = 
            "sys.path.insert(0, '" + lib_path + "')\n"  // 添加lib目录以找到编译好的Cython模块
            "sys.path.insert(0, '" + project_dir + "')\n"  // 添加根目录
            "sys.path.insert(0, '" + python_wrapper_path + "')\n"
            "sys.path.insert(0, '" + python_core_path + "')";
        
        PyRun_SimpleString(add_path_cmd.c_str());
        
        // 导入numpy（Cython模块需要）
        PyRun_SimpleString("import numpy");
        
        // 尝试加载编译好的Cython模块
        loadCythonModule();
    }
    
    ~CythonEnvironment() {
        if (cython_module_handle) {
            dlclose(cython_module_handle);
        }
        if (initialized && Py_IsInitialized()) {
            // 生产环境不调用Py_Finalize()避免问题
        }
    }
    
    bool isInitialized() const {
        return initialized && Py_IsInitialized();
    }
    
    const std::string& getProjectDir() const {
        return project_dir;
    }
    
private:
    void loadCythonModule() {
        // 尝试加载编译好的Cython扩展（静默模式）
        try {
            PyRun_SimpleString("import bellhop_cython_core");
            // Cython模块加载成功（不输出信息）
        } catch (...) {
            // 如果Cython模块不可用，静默回退到原始Python模块
        }
    }
};

// 全局环境实例
static CythonEnvironment* g_cython_env = nullptr;

static void initializeCython() {
    if (!g_cython_env) {
        try {
            g_cython_env = new CythonEnvironment();
        } catch (const std::exception& e) {
            std::cerr << "Failed to initialize Cython environment: " << e.what() << std::endl;
            throw;
        }
    }
}

int SolveBellhopPropagationModel(const std::string& json, std::string& outJson) {
    try {
        // 初始化Cython环境
        initializeCython();
        
        if (!g_cython_env || !g_cython_env->isInitialized()) {
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Cython environment initialization failed"
            })";
            return 500;
        }
        
        // 优先尝试使用Cython模块
        PyObject* pModule = nullptr;
        PyObject* pFunc = nullptr;
        const char* function_name = nullptr;
        
        // 尝试导入Cython模块（静默模式）
        pModule = PyImport_ImportModule("bellhop_cython_core");
        if (pModule) {
            function_name = "solve_bellhop_propagation";
            pFunc = PyObject_GetAttrString(pModule, function_name);
        }
        
        // 如果Cython模块不可用，回退到Python模块
        if (!pModule || !pFunc) {
            if (pModule) {
                Py_DECREF(pModule);
            }
            PyErr_Clear(); // 清除错误
            
            pModule = PyImport_ImportModule("bellhop_wrapper");
            if (pModule) {
                function_name = "solve_bellhop_propagation";
                pFunc = PyObject_GetAttrString(pModule, function_name);
            }
        }
        
        if (!pModule) {
            PyErr_Print();
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Failed to import both Cython and Python modules"
            })";
            return 500;
        }
        
        if (!pFunc || !PyCallable_Check(pFunc)) {
            PyErr_Print();
            Py_DECREF(pModule);
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Cannot find function solve_bellhop_propagation"
            })";
            return 500;
        }
        
        // 准备参数
        PyObject* pArgs = PyTuple_New(1);
        PyObject* pValue = PyUnicode_FromString(json.c_str());
        PyTuple_SetItem(pArgs, 0, pValue);
        
        // 调用函数
        PyObject* pResult = PyObject_CallObject(pFunc, pArgs);
        
        // 清理
        Py_DECREF(pArgs);
        Py_DECREF(pFunc);
        Py_DECREF(pModule);
        
        if (!pResult) {
            PyErr_Print();
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Function call failed"
            })";
            return 500;
        }
        
        // 获取结果
        const char* result_str = PyUnicode_AsUTF8(pResult);
        if (result_str) {
            outJson = std::string(result_str);
        } else {
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Cannot get function return value"
            })";
            Py_DECREF(pResult);
            return 500;
        }
        
        Py_DECREF(pResult);
        return 200;
        
    } catch (const std::exception& e) {
        outJson = R"({
            "receiver_depth": [],
            "receiver_range": [],
            "transmission_loss": [],
            "propagation_pressure": [],
            "ray_trace": [],
            "time_wave": null,
            "error_code": 500,
            "error_message": "C++ layer exception: )" + std::string(e.what()) + R"("
        })";
        return 500;
    }
}
