/**
 * Bellhop传播模型 - Nuitka版本可执行文件
 * 
 * 使用Nuitka编译的Python模块实现声传播计算
 * 符合声传播模型接口规范
 * 
 * 使用方法：
 * 1. ./BellhopPropagationModel                    # 默认 input.json -> output.json
 * 2. ./BellhopPropagationModel input.json output.json  # 自定义文件
 */

#include <iostream>
#include <fstream>
#include <string>
#include <sys/stat.h>  // for file existence check
#include <Python.h>

// 包含动态库头文件
#include "BellhopPropagationModelInterface.h"

// C++11兼容的文件存在检查函数
inline bool file_exists(const std::string& path) {
    struct stat buffer;
    return (stat(path.c_str(), &buffer) == 0);
}

// 声明外部函数
extern int SolveBellhopPropagationModel(const std::string& json, std::string& outJson);

/**
 * 读取JSON文件内容
 */
std::string readJsonFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot open input file: " + filename);
    }
    
    std::string content;
    std::string line;
    while (std::getline(file, line)) {
        content += line + "\n";
    }
    
    return content;
}

/**
 * 写入JSON文件内容
 */
void writeJsonFile(const std::string& filename, const std::string& content) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot create output file: " + filename);
    }
    
    file << content;
    file.close();
}

/**
 * 显示程序使用帮助
 */
void showUsage(const char* programName) {
    std::cout << "Bellhop声传播模型 - Nuitka版本" << std::endl;
    std::cout << "使用方法:" << std::endl;
    std::cout << "  " << programName << "                    # 默认使用 input.json -> output.json" << std::endl;
    std::cout << "  " << programName << " input.json output.json  # 指定输入输出文件" << std::endl;
    std::cout << std::endl;
    std::cout << "参数说明:" << std::endl;
    std::cout << "  input.json   - 输入参数文件（JSON格式）" << std::endl;
    std::cout << "  output.json  - 输出结果文件（JSON格式）" << std::endl;
    std::cout << std::endl;
    std::cout << "接口规范:" << std::endl;
    std::cout << "  - 可执行文件名: BellhopPropagationModel" << std::endl;
    std::cout << "  - 动态库名: libBellhopPropagationModel.so" << std::endl;
    std::cout << "  - 计算函数: int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)" << std::endl;
    std::cout << "  - 参数单位: 距离(m), 深度(m), 频率(Hz)" << std::endl;
}

/**
 * 主函数
 */
int main(int argc, char* argv[]) {
    std::string inputFile = "input.json";
    std::string outputFile = "output.json";
    
    // 解析命令行参数
    if (argc == 1) {
        // 默认参数：input.json -> output.json
        std::cout << "使用默认参数: " << inputFile << " -> " << outputFile << std::endl;
    } else if (argc == 3) {
        // 自定义参数
        inputFile = argv[1];
        outputFile = argv[2];
        std::cout << "使用自定义参数: " << inputFile << " -> " << outputFile << std::endl;
    } else if (argc == 2 && (std::string(argv[1]) == "-h" || std::string(argv[1]) == "--help")) {
        // 显示帮助
        showUsage(argv[0]);
        return 0;
    } else {
        // 参数错误
        std::cerr << "错误: 参数数量不正确" << std::endl;
        std::cerr << "使用 " << argv[0] << " -h 查看帮助" << std::endl;
        return 1;
    }
    
    try {
        // 检查输入文件是否存在
        if (!file_exists(inputFile)) {
            std::cerr << "错误: 输入文件不存在: " << inputFile << std::endl;
            return 1;
        }
        
        std::cout << "=== Bellhop声传播模型计算 (Nuitka版本) ===" << std::endl;
        std::cout << "输入文件: " << inputFile << std::endl;
        std::cout << "输出文件: " << outputFile << std::endl;
        
        // 读取输入JSON
        std::cout << "读取输入文件..." << std::endl;
        std::string inputJson = readJsonFile(inputFile);
        
        // 调用计算函数
        std::cout << "开始计算..." << std::endl;
        std::string outputJson;
        int errorCode = SolveBellhopPropagationModel(inputJson, outputJson);
        
        // 检查计算结果
        if (errorCode == 200) {
            std::cout << "✓ 计算成功完成" << std::endl;
            
            // 写入输出文件
            std::cout << "写入输出文件..." << std::endl;
            writeJsonFile(outputFile, outputJson);
            
            std::cout << "✓ 结果已保存到: " << outputFile << std::endl;
            std::cout << "=== 计算完成 ===" << std::endl;
            
            return 0;
        } else {
            std::cerr << "✗ 计算失败 (错误码: " << errorCode << ")" << std::endl;
            std::cerr << "错误信息: " << outputJson << std::endl;
            
            // 仍然写入错误信息到输出文件
            writeJsonFile(outputFile, outputJson);
            
            return 1;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "✗ 程序异常: " << e.what() << std::endl;
        
        // 写入错误信息到输出文件
        std::string errorJson = R"({"error_code": 500, "error_message": "Program exception: )" + std::string(e.what()) + R"("})";
        try {
            writeJsonFile(outputFile, errorJson);
        } catch (...) {
            // 忽略写入错误
        }
        
        return 1;
    } catch (...) {
        std::cerr << "✗ 未知异常" << std::endl;
        
        // 写入错误信息到输出文件
        std::string errorJson = R"({"error_code": 500, "error_message": "Unknown exception"})";
        try {
            writeJsonFile(outputFile, errorJson);
        } catch (...) {
            // 忽略写入错误
        }
        
        return 1;
    }
}
