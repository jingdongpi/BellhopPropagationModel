/**
 * Bellhop传播模型可执行文件
 * 符合接口规范：支持无参数和双参数调用
 */

#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include "BellhopPropagationModelInterface.h"
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>

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
    // 确保输出目录存在
    std::filesystem::path filepath(filename);
    if (filepath.has_parent_path()) {
        std::filesystem::create_directories(filepath.parent_path());
    }
    
    std::ofstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot create file: " + filename);
    }
    file << content;
}

void printUsage(const std::string& programName) {
    std::cout << "Bellhop传播模型 v1.0\n";
    std::cout << "用法：\n";
    std::cout << "  " << programName << "                           # 使用默认文件 input.json -> output.json\n";
    std::cout << "  " << programName << " <input.json> <output.json>  # 指定输入输出文件\n";
    std::cout << "\n接口规范兼容:\n";
    std::cout << "  - 可执行文件名: BellhopPropagationModel\n";
    std::cout << "  - 支持无参数调用（默认input.json/output.json）\n";
    std::cout << "  - 支持双参数调用（自定义输入输出文件）\n";
}

int main(int argc, char* argv[]) {
    std::string inputFile = "input.json";   // 默认输入文件
    std::string outputFile = "output.json"; // 默认输出文件
    
    // 根据接口规范处理命令行参数
    if (argc == 1) {
        // 无参数：使用默认文件名（静默模式）
    } else if (argc == 3) {
        // 两个参数：用户指定的输入输出文件
        inputFile = argv[1];
        outputFile = argv[2];
    } else {
        // 参数错误
        std::cerr << "错误：参数数量不正确" << std::endl;
        printUsage(argv[0]);
        return 1;
    }
    
    try {
        // 检查输入文件是否存在
        if (!std::filesystem::exists(inputFile)) {
            std::cerr << "错误：输入文件不存在: " << inputFile << std::endl;
            return 1;
        }
        
        // 读取输入JSON
        std::string inputJson = readFile(inputFile);
        
        // 调用传播模型计算
        std::string outputJson;
        int result = SolveBellhopPropagationModel(inputJson, outputJson);
        
        if (result == 200) {
            // 写入输出文件
            writeFile(outputFile, outputJson);
            std::cout << "Computation completed: " << inputFile << " -> " << outputFile << std::endl;
            return 0;
        } else {
            std::cerr << "计算失败，错误码: " << result << std::endl;
            // 即使失败也写入错误结果
            writeFile(outputFile, outputJson);
            return result;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "程序异常: " << e.what() << std::endl;
        
        // 生成错误输出
        std::string errorJson = R"({
            "receiver_depth": [],
            "receiver_range": [],
            "transmission_loss": [],
            "propagation_pressure": [],
            "ray_trace": [],
            "time_wave": null,
            "error_code": 500,
            "error_message": ")" + std::string(e.what()) + R"("
        })";
        
        try {
            writeFile(outputFile, errorJson);
        } catch (...) {
            std::cerr << "无法写入错误输出文件" << std::endl;
        }
        
        return 500;
    }
}

// 为了保持接口一致性，可执行文件也包含库函数的声明
// 实际实现在 BellhopPropagationModel_cython.cpp 中
extern int SolveBellhopPropagationModel(const std::string& json, std::string& outJson);
