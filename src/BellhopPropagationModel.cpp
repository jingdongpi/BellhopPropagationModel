#include "BellhopPropagationModelInterface.h"
#include <Python.h>
#include <iostream>
#include <stdexcept>
#include <filesystem>

class PythonEnvironment {
private:
    bool initialized;
    std::string project_dir;
    
public:
    PythonEnvironment() : initialized(false) {
        if (!Py_IsInitialized()) {
            Py_Initialize();
            if (!Py_IsInitialized()) {
                throw std::runtime_error("Failed to initialize Python");
            }
        }
        initialized = true;
        
        // 获取项目目录（假设可执行文件在项目根目录或子目录中）
        project_dir = std::filesystem::current_path();
        
        // 添加Python模块路径 - 使用本地模块
        PyRun_SimpleString("import sys");
        
        std::string python_core_path = project_dir + "/python_core";
        std::string python_wrapper_path = project_dir + "/python_wrapper";
        
        std::string add_path_cmd = 
            "sys.path.insert(0, '" + python_wrapper_path + "')\n"
            "sys.path.insert(0, '" + python_core_path + "')";
        
        PyRun_SimpleString(add_path_cmd.c_str());
        
        // 备用路径（如果本地模块不存在）
        PyRun_SimpleString("sys.path.append('/home/shunli/pro/AcousticFastAPI/pyat')");
        PyRun_SimpleString("sys.path.append('/home/shunli/pro')");
        
        // 确保可以找到numpy
        PyRun_SimpleString("import numpy");
        
        // Python环境初始化完成 - 生产环境静默模式
    }
    
    ~PythonEnvironment() {
        if (initialized && Py_IsInitialized()) {
            // 注意：在某些情况下不要调用Py_Finalize()，因为可能会导致问题
            // Py_Finalize();
        }
    }
    
    bool isInitialized() const {
        return initialized && Py_IsInitialized();
    }
    
    const std::string& getProjectDir() const {
        return project_dir;
    }
};

// 全局Python环境实例
static PythonEnvironment* g_python_env = nullptr;

static void initializePython() {
    if (!g_python_env) {
        try {
            g_python_env = new PythonEnvironment();
        } catch (const std::exception& e) {
            std::cerr << "Failed to initialize Python environment: " << e.what() << std::endl;
            throw;
        }
    }
}

int SolveBellhopPropagationModel(const std::string& json, std::string& outJson) {
    try {
        // 初始化Python环境
        initializePython();
        
        if (!g_python_env || !g_python_env->isInitialized()) {
            outJson = R"({
                "receiver_depth": [],
                "receiver_range": [],
                "transmission_loss": [],
                "propagation_pressure": [],
                "ray_trace": [],
                "time_wave": null,
                "error_code": 500,
                "error_message": "Python environment initialization failed"
            })";
            return 500;
        }
        
        // 导入Python模块
        PyObject* pModule = PyImport_ImportModule("bellhop_wrapper");
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
                "error_message": "Failed to import Python module bellhop_wrapper"
            })";
            return 500;
        }
        
        // 获取函数
        PyObject* pFunc = PyObject_GetAttrString(pModule, "solve_bellhop_propagation");
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
                "error_message": "Python function call failed"
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
                "error_message": "Cannot get Python function return value"
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