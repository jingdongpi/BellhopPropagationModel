#ifndef BELLHOP_PROPAGATION_MODEL_INTERFACE_H
#define BELLHOP_PROPAGATION_MODEL_INTERFACE_H

#include <string>

#ifdef _WIN32
    #ifdef BELLHOP_PROPAGATION_MODEL_EXPORTS
        #define BELLHOP_API __declspec(dllexport)
    #else
        #define BELLHOP_API __declspec(dllimport)
    #endif
#else
    #define BELLHOP_API __attribute__((visibility("default")))
#endif

extern "C" {
    /**
     * Bellhop声传播模型计算函数
     * @param json 输入JSON字符串，包含所有计算参数
     * @param outJson 输出JSON字符串，包含计算结果
     * @return 错误码: 200成功，500失败
     */
    BELLHOP_API int SolveBellhopPropagationModel(const std::string& json, std::string& outJson);
}

#endif // BELLHOP_PROPAGATION_MODEL_INTERFACE_H