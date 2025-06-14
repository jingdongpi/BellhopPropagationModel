#ifndef BELLHOP_PROPAGATION_MODEL_INTERFACE_H
#define BELLHOP_PROPAGATION_MODEL_INTERFACE_H

#include <string>

#ifdef _WIN32
    #ifdef BELLHOP_EXPORTS
        #define BELLHOP_API __declspec(dllexport)
    #else
        #define BELLHOP_API __declspec(dllimport)
    #endif
#else
    #define BELLHOP_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief BellhopPropagationModel声传播计算接口
 * 
 * @param json 输入参数JSON字符串，包含以下必需字段：
 *   - freq: 频率(Hz) - 数值或数组
 *   - source_depth: 声源深度(m) - 数值
 *   - receiver_depth: 接收器深度(m) - 数组
 *   - receiver_range: 接收器距离(m) - 数组
 *   - bathy: 海底地形 - {range: 距离数组(m), depth: 深度数组(m)}
 *   - sound_speed_profile: 声速剖面 - 数组
 *   - sediment_info: 沉积物信息 - 数组
 * 
 * @param outJson 输出结果JSON字符串，包含：
 *   - error_code: 错误码 (200=成功, 500=失败)
 *   - error_message: 错误信息
 *   - receiver_depth: 接收器深度数组(m)
 *   - receiver_range: 接收器距离数组(m)  
 *   - transmission_loss: 传输损失矩阵(dB)
 *   - frequencies: 计算频率数组(Hz) (多频率时)
 *   - propagation_pressure: 传播压力数据 (可选)
 *   - ray_trace: 射线轨迹数据 (可选)
 * 
 * @return int 返回码 (0=成功, 非0=失败)
 * 
 * @note 参数单位规范：
 *   - 距离：m
 *   - 深度：m
 *   - 频率：Hz
 */
BELLHOP_API int SolveBellhopPropagationModel(const std::string& json, std::string& outJson);

/**
 * @brief 获取模型版本信息
 * @return const char* 版本字符串
 */
BELLHOP_API const char* GetBellhopPropagationModelVersion();

/**
 * @brief 获取支持的功能列表
 * @return const char* 功能描述JSON字符串
 */
BELLHOP_API const char* GetBellhopPropagationModelCapabilities();

#ifdef __cplusplus
}
#endif

#endif // BELLHOP_PROPAGATION_MODEL_INTERFACE_H