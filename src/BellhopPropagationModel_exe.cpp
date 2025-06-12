// Python.h应该在所有其他包含之前（除了必要的C++标准库）
#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include "BellhopPropagationModelInterface.h"
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>  // 添加这个包含

std::string readFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot open file: " + filename);
    }
    
    std::string content((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
    return content;
}

void writeFile(const std::string& filename, const std::string& content) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot create file: " + filename);
    }
    file << content;
}

std::string SolveBellhopPropagationModel(const std::string& input_json) {
    // 更严格的Python解释器初始化
    if (!Py_IsInitialized()) {
        // 设置Python程序名（可选，但推荐）
        Py_SetProgramName(L"BellhopPropagationModel");
        
        // 初始化Python解释器
        Py_Initialize();
        
        // 检查初始化是否成功
        if (!Py_IsInitialized()) {
            return R"({"error_code": 500, "error_message": "Python interpreter initialization failed"})";
        }
    }
    
    // 获取当前可执行文件的目录
    std::filesystem::path exe_path = std::filesystem::current_path();
    std::string project_root = exe_path.parent_path().string();
    
    // 确保Python解释器在函数结束时正确清理
    // 注意：通常不应该在函数中调用Py_Finalize()，除非这是程序的最后一次Python调用
    
    try {
        // 检查Python错误状态
        if (PyErr_Occurred()) {
            PyErr_Clear();  // 清除之前的错误
        }
        
        // 添加项目路径到Python系统路径
        int py_result = PyRun_SimpleString("import sys");
        if (py_result != 0) {
            PyErr_Print();
            return R"({"error_code": 500, "error_message": "Failed to import sys module"})";
        }
        
        py_result = PyRun_SimpleString("import os");
        if (py_result != 0) {
            PyErr_Print();
            return R"({"error_code": 500, "error_message": "Failed to import os module"})";
        }
        
        // 修复路径配置
        std::string add_path_cmd = 
            "project_root = r'" + project_root + "'\n"
            "python_wrapper_path = os.path.join(project_root, 'python_wrapper')\n"
            "python_core_path = os.path.join(project_root, 'python_core')\n"
            "if project_root not in sys.path:\n"
            "    sys.path.insert(0, project_root)\n"
            "if python_wrapper_path not in sys.path:\n"
            "    sys.path.insert(0, python_wrapper_path)\n"
            "if python_core_path not in sys.path:\n"
            "    sys.path.insert(0, python_core_path)\n"
            "print(f'Added path: {project_root}')\n"
            "print(f'Added path: {python_wrapper_path}')\n"
            "print(f'Added path: {python_core_path}')\n"
            "print('Current working directory:', os.getcwd())\n"
            "print('Python path:', sys.path[:3])";
        
        py_result = PyRun_SimpleString(add_path_cmd.c_str());
        if (py_result != 0) {
            PyErr_Print();
            return R"({"error_code": 500, "error_message": "Python path configuration failed"})";
        }
        
        // 导入bellhop_wrapper模块
        PyObject* pModule = PyImport_ImportModule("bellhop_wrapper");
        if (!pModule) {
            // 生产环境：记录错误但不输出到控制台
            PyErr_Clear();
            return R"({"error_code": 500, "error_message": "Failed to import bellhop_wrapper module"})";
        }
        
        // 获取solve_bellhop_propagation函数
        PyObject* pFunc = PyObject_GetAttrString(pModule, "solve_bellhop_propagation");
        if (!pFunc || !PyCallable_Check(pFunc)) {
            Py_DECREF(pModule);
            return R"({"error_code": 500, "error_message": "Cannot find solve_bellhop_propagation function"})";
        }
        
        // 创建参数
        PyObject* pArgs = PyTuple_New(1);
        PyObject* pValue = PyUnicode_FromString(input_json.c_str());
        PyTuple_SetItem(pArgs, 0, pValue);
        
        // 调用函数
        PyObject* pResult = PyObject_CallObject(pFunc, pArgs);
        
        std::string result_string;
        if (pResult) {
            const char* result_str = PyUnicode_AsUTF8(pResult);
            if (result_str) {
                result_string = result_str;
            } else {
                result_string = R"({"error_code": 500, "error_message": "Cannot get calculation result"})";
            }
            Py_DECREF(pResult);
        } else {
            // 获取Python错误信息
            std::string python_error = "Unknown Python error";
            if (PyErr_Occurred()) {
                PyObject *ptype, *pvalue, *ptraceback;
                PyErr_Fetch(&ptype, &pvalue, &ptraceback);
                
                if (pvalue) {
                    PyObject* str_exc_value = PyObject_Repr(pvalue);
                    if (str_exc_value) {
                        const char* c_str = PyUnicode_AsUTF8(str_exc_value);
                        if (c_str) {
                            python_error = c_str;
                        }
                        Py_DECREF(str_exc_value);
                    }
                }
                
                // 清理错误对象
                Py_XDECREF(ptype);
                Py_XDECREF(pvalue);
                Py_XDECREF(ptraceback);
            }
            
            result_string = R"({"error_code": 500, "error_message": "Python function call failed: )" + python_error + R"("})";
        }
        
        // 清理
        Py_DECREF(pArgs);
        Py_DECREF(pFunc);
        Py_DECREF(pModule);
        
        return result_string;
        
    } catch (const std::exception& e) {
        // 清除Python错误状态
        if (PyErr_Occurred()) {
            PyErr_Clear();
        }
        return R"({"error_code": 500, "error_message": "C++ exception: )" + std::string(e.what()) + R"("})";
    }
}

int main(int argc, char* argv[]) {
    std::string inputFile = "input.json";
    std::string outputFile = "output.json";
    
    // 解析命令行参数
    if (argc == 3) {
        inputFile = argv[1];
        outputFile = argv[2];
    } else if (argc != 1) {
        std::cerr << "Usage: " << argv[0] << " [input_file] [output_file]" << std::endl;
        std::cerr << "  or: " << argv[0] << " (use default files input.json and output.json)" << std::endl;
        return 1;
    }
    
    try {
        // 读取输入文件
        std::string inputJson = readFile(inputFile);
        
        // 调用计算函数
        std::string outputJson = SolveBellhopPropagationModel(inputJson);
        
        // 写入输出文件
        writeFile(outputFile, outputJson);
        
        if (outputJson.find("\"error_code\": 200") != std::string::npos) {
            // 生产环境：静默完成，不输出到控制台
            
            // 程序结束时清理Python解释器
            if (Py_IsInitialized()) {
                Py_Finalize();
            }
            
            return 0;
        } else {
            std::cerr << "Calculation failed, error code: 500" << std::endl;
            std::cerr << "Error details: " << outputJson << std::endl;
            
            // 程序结束时清理Python解释器
            if (Py_IsInitialized()) {
                Py_Finalize();
            }
            
            return 1;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        
        // 程序结束时清理Python解释器
        if (Py_IsInitialized()) {
            Py_Finalize();
        }
        
        return 1;
    }
}