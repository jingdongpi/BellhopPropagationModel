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
#include <vector>
#include <cstdlib>

// 条件包含动态库加载头文件
#if !defined(_WIN32) && !defined(_WIN64) && !defined(__MINGW32__) && !defined(__MINGW64__)
#include <dlfcn.h>
#endif

#include "BellhopPropagationModelInterface.h"

// 全局Python解释器状态
static bool python_initialized = false;
static PyObject* bellhop_module = nullptr;

/**
 * 动态检测和设置Python环境
 */
bool setup_python_environment() {
    std::vector<std::string> python_paths = {
        "/usr/lib/python3.9/site-packages",
        "/usr/local/lib/python3.9/site-packages", 
        "/usr/lib/python3/dist-packages",
        "/usr/local/lib/python3/dist-packages"
    };
    
    // 获取环境变量中的Python路径
    const char* python_path_env = std::getenv("PYTHONPATH");
    if (python_path_env) {
        std::string env_paths(python_path_env);
        size_t pos = 0;
        while ((pos = env_paths.find(':')) != std::string::npos) {
            python_paths.push_back(env_paths.substr(0, pos));
            env_paths.erase(0, pos + 1);
        }
        if (!env_paths.empty()) {
            python_paths.push_back(env_paths);
        }
    }
    
    // 动态检测Python安装路径
    PyRun_SimpleString("import sys, os, subprocess");
    
    // 尝试从python3命令获取路径
    PyRun_SimpleString(R"(
try:
    import subprocess
    result = subprocess.run(['python3', '-c', 'import sys; print(sys.path)'], 
                          capture_output=True, text=True, timeout=5)
    if result.returncode == 0:
        import ast
        detected_paths = ast.literal_eval(result.stdout.strip())
        for path in detected_paths:
            if path and os.path.exists(path):
                sys.path.insert(0, path)
except:
    pass
)");
    
    // 添加检测到的路径
    for (const auto& path : python_paths) {
        if (std::filesystem::exists(path)) {
            std::string cmd = "import sys; path = r'" + path + "'; path not in sys.path and sys.path.append(path)";
            PyRun_SimpleString(cmd.c_str());
        }
    }
    
    return true;
}

/**
 * 检测Python环境和必需依赖
 */
bool check_python_dependencies() {
    std::cout << "🔍 检测Python环境..." << std::endl;
    
    // 检测Python版本
    PyRun_SimpleString(R"(
import sys
print(f"✓ Python版本: {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")
)");
    
    // 检测并尝试导入numpy
    int numpy_result = PyRun_SimpleString(R"(
try:
    import numpy as np
    print(f"✓ NumPy版本: {np.__version__}")
    print(f"  路径: {np.__file__}")
except ImportError as e:
    print(f"❌ NumPy未安装: {e}")
    raise
except Exception as e:
    print(f"❌ NumPy导入失败: {e}")
    raise
)");
    
    if (numpy_result != 0) {
        std::cerr << "❌ NumPy依赖检测失败" << std::endl;
        PyErr_Clear();
        return false;
    }
    
    // 检测并尝试导入scipy
    int scipy_result = PyRun_SimpleString(R"(
try:
    import scipy
    print(f"✓ SciPy版本: {scipy.__version__}")
    print(f"  路径: {scipy.__file__}")
except ImportError as e:
    print(f"⚠️  SciPy未安装: {e}")
    print("  注意: 某些功能可能受限")
except Exception as e:
    print(f"⚠️  SciPy导入失败: {e}")
    print("  注意: 某些功能可能受限")
)");
    
    // SciPy不是必须的，只是警告
    if (scipy_result != 0) {
        std::cout << "⚠️  SciPy检测失败，继续运行但部分功能可能受限" << std::endl;
        PyErr_Clear();
    }
    
    std::cout << "✅ Python环境检测完成" << std::endl;
    return true;
}

/**
 * 初始化Python环境和Nuitka模块
 */
bool initialize_python_environment() {
    if (python_initialized) {
        return true;
    }
    
    try {
        // 预加载Python共享库以解决符号链接问题（仅在Linux/Unix系统）
#if !defined(_WIN32) && !defined(_WIN64) && !defined(__MINGW32__) && !defined(__MINGW64__)
        // 智能加载Python动态库
        void* python_lib = nullptr;
        std::string loaded_lib;
        
        // 首先尝试获取当前Python版本信息
        std::string current_python_version;
        FILE* fp = popen("python3 --version 2>&1", "r");
        if (fp) {
            char buffer[128];
            if (fgets(buffer, sizeof(buffer), fp)) {
                current_python_version = std::string(buffer);
                // 提取版本号 (例如: "Python 3.8.10" -> "3.8")
                size_t start = current_python_version.find("Python ");
                if (start != std::string::npos) {
                    start += 7; // "Python ".length()
                    size_t end = current_python_version.find('.', start);
                    if (end != std::string::npos) {
                        end = current_python_version.find('.', end + 1);
                        if (end != std::string::npos) {
                            current_python_version = current_python_version.substr(start, end - start);
                        }
                    }
                }
            }
            pclose(fp);
        }
        
        // 构建优先查找列表（当前版本优先）
        std::vector<std::string> python_libs;
        std::vector<std::string> all_versions = {"3.12", "3.11", "3.10", "3.9", "3.8"};
        
        // 首先添加当前版本的所有变体
        if (!current_python_version.empty()) {
            std::cout << "✓ 检测到Python版本: " << current_python_version << std::endl;
            python_libs.push_back("libpython" + current_python_version + ".so");
            python_libs.push_back("libpython" + current_python_version + ".so.1.0");
            python_libs.push_back("libpython" + current_python_version + ".so.1");
        }
        
        // 然后添加其他版本
        for (const auto& version : all_versions) {
            if (version != current_python_version) {
                python_libs.push_back("libpython" + version + ".so");
                python_libs.push_back("libpython" + version + ".so.1.0");
                python_libs.push_back("libpython" + version + ".so.1");
            }
        }
        
        // 尝试加载库
        for (const auto& lib : python_libs) {
            python_lib = dlopen(lib.c_str(), RTLD_LAZY | RTLD_GLOBAL);
            if (python_lib) {
                loaded_lib = lib;
                std::cout << "✓ 成功加载Python库: " << lib << std::endl;
                break;
            }
        }
        
        if (!python_lib) {
            std::cerr << "⚠️  未找到兼容的Python共享库" << std::endl;
            std::cerr << "   已尝试的库文件:" << std::endl;
            for (const auto& lib : python_libs) {
                std::cerr << "     " << lib << std::endl;
            }
            std::cerr << "   建议检查Python安装和LD_LIBRARY_PATH设置" << std::endl;
        }
#endif
        
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
            
            // 动态设置Python环境
            if (!setup_python_environment()) {
                std::cerr << "Failed to setup Python environment" << std::endl;
                return false;
            }
        }
        
        // 检测Python环境和必需依赖
        if (!check_python_dependencies()) {
            std::cerr << "❌ Python依赖检测失败" << std::endl;
            std::cerr << "💡 请确保已安装：pip install numpy scipy" << std::endl;
            return false;
        }
        
        // 自动添加lib目录到Python搜索路径（仅在Linux/Unix系统）
#if !defined(_WIN32) && !defined(_WIN64) && !defined(__MINGW32__) && !defined(__MINGW64__)
        // 通过dladdr获取当前动态库的路径，然后推断lib目录位置
        Dl_info dl_info;
        if (dladdr((void*)initialize_python_environment, &dl_info) && dl_info.dli_fname) {
            std::filesystem::path lib_path = std::filesystem::path(dl_info.dli_fname).parent_path();
            
            // 如果当前是在bin目录，需要找到对应的lib目录
            if (lib_path.filename() == "bin") {
                lib_path = lib_path.parent_path() / "lib";
            }
            
            std::string python_code = "import sys; lib_path = r'" + lib_path.string() + 
                                    "'; lib_path not in sys.path and sys.path.insert(0, lib_path)";
            PyRun_SimpleString(python_code.c_str());
            
            // 输出调试信息
            std::string debug_code = "print('Added lib path:', r'" + lib_path.string() + "')";
            PyRun_SimpleString(debug_code.c_str());
            std::string debug_code2 = "print('Python sys.path:', sys.path[:3])";
            PyRun_SimpleString(debug_code2.c_str());
        }
#else
        // Windows平台：添加当前目录和lib目录到Python搜索路径
        std::string python_code = R"(
import sys
import os
# 添加当前工作目录
current_dir = os.getcwd()
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)
# 添加lib目录
lib_dir = os.path.join(current_dir, 'lib')
if os.path.exists(lib_dir) and lib_dir not in sys.path:
    sys.path.insert(0, lib_dir)
print('Added Windows paths to sys.path')
)";
        PyRun_SimpleString(python_code.c_str());
#endif
        
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
        
        // 注意：不要调用Py_Finalize()，因为可能还有其他地方在使用Python
        python_initialized = false;
    } catch (const std::exception& e) {
        std::cerr << "Exception during Python cleanup: " << e.what() << std::endl;
    }
}

/**
 * 主计算函数 - 使用Nuitka编译的Python模块
 */
int SolveBellhopPropagationModel(const std::string& input_json, std::string& output_json) {
    try {
        // 确保Python环境已初始化
        if (!initialize_python_environment()) {
            output_json = R"({"error_code": 500, "error_message": "Failed to initialize Python environment"})";
            return 500;
        }
        
        // 调用Python函数
        PyObject* solve_function = PyObject_GetAttrString(bellhop_module, "solve_bellhop_propagation");
        if (!solve_function || !PyCallable_Check(solve_function)) {
            output_json = R"({"error_code": 500, "error_message": "Function solve_bellhop_propagation not found or not callable"})";
            return 500;
        }
        
        // 创建参数
        PyObject* input_py_str = PyUnicode_FromString(input_json.c_str());
        if (!input_py_str) {
            Py_DECREF(solve_function);
            output_json = R"({"error_code": 500, "error_message": "Failed to create input string"})";
            return 500;
        }
        
        // 调用函数
        PyObject* args = PyTuple_New(1);
        PyTuple_SetItem(args, 0, input_py_str);  // PyTuple_SetItem会获取引用
        
        PyObject* result = PyObject_CallObject(solve_function, args);
        Py_DECREF(args);
        Py_DECREF(solve_function);
        
        if (!result) {
            PyErr_Print();
            output_json = R"({"error_code": 500, "error_message": "Python function call failed"})";
            return 500;
        }
        
        // Python函数返回JSON字符串（不是元组）
        if (PyUnicode_Check(result)) {
            const char* json_str = PyUnicode_AsUTF8(result);
            if (json_str) {
                output_json = std::string(json_str);
                
                // 解析JSON获取error_code
                try {
                    // 简单的error_code提取（避免引入JSON库依赖）
                    std::string json_content = output_json;
                    size_t error_code_pos = json_content.find("\"error_code\"");
                    if (error_code_pos != std::string::npos) {
                        size_t colon_pos = json_content.find(":", error_code_pos);
                        if (colon_pos != std::string::npos) {
                            size_t start = colon_pos + 1;
                            // 跳过空格
                            while (start < json_content.length() && isspace(json_content[start])) start++;
                            
                            size_t end = start;
                            while (end < json_content.length() && isdigit(json_content[end])) end++;
                            
                            if (end > start) {
                                int error_code = std::stoi(json_content.substr(start, end - start));
                                Py_DECREF(result);
                                return error_code;
                            }
                        }
                    }
                    // 如果没有找到error_code，默认返回200（成功）
                    Py_DECREF(result);
                    return 200;
                } catch (const std::exception& e) {
                    // JSON解析失败，但有结果，默认成功
                    Py_DECREF(result);
                    return 200;
                }
            } else {
                output_json = R"({"error_code": 500, "error_message": "Failed to decode Python result"})";
                Py_DECREF(result);
                return 500;
            }
        } else {
            Py_DECREF(result);
            output_json = R"({"error_code": 500, "error_message": "Python function returned non-string result"})";
            return 500;
        }
        
    } catch (const std::exception& e) {
        output_json = R"({"error_code": 500, "error_message": "C++ exception: )" + std::string(e.what()) + R"("})";
        return 500;
    }
}

/**
 * 获取版本信息
 */
const char* GetBellhopPropagationModelVersion() {
    return "1.0.0-nuitka";
}

// 编译器和平台检测（用于调试）
#ifdef _WIN32
    #ifdef __MINGW32__
        // MinGW 32位编译器
        #pragma message("编译器：MinGW 32位")
    #elif defined(__MINGW64__)
        // MinGW 64位编译器
        #pragma message("编译器：MinGW 64位")
    #else
        // 其他Windows编译器（如MSVC）
        #pragma message("编译器：Windows 其他编译器")
    #endif
#else
    // Unix/Linux编译器
    #pragma message("编译器：Unix/Linux")
#endif
