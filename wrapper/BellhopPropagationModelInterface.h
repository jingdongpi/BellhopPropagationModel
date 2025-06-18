/**
 * BellhopPropagationModelInterface.h
 * 
 * 声传播模型接口规范 - C++动态链接库接口
 * 完全符合规范2.1.2要求
 * 
 * 接口规范：
 * - 动态链接库命名：libBellhopPropagationModel.so (Linux) / BellhopPropagationModel.dll (Windows)
 * - 计算函数：SolveBellhopPropagationModel
 * - 输入输出：JSON字符串格式
 * - 错误码：200成功，500失败
 */

#ifndef BELLHOP_PROPAGATION_MODEL_INTERFACE_H
#define BELLHOP_PROPAGATION_MODEL_INTERFACE_H

#include <string>

// 平台导出宏定义
#ifdef _WIN32
    #ifdef BELLHOP_EXPORTS
        #define BELLHOP_API __declspec(dllexport)
    #else
        #define BELLHOP_API __declspec(dllimport)
    #endif
#else
    #define BELLHOP_API __attribute__((visibility("default")))
#endif

extern "C" {

/**
 * SolveBellhopPropagationModel - 声传播模型计算函数
 * 
 * 符合声传播模型接口规范2.1.2
 * 
 * @param input_json 输入参数JSON字符串，包含完整的声传播计算参数
 *                   必须符合标准输入接口格式（规范2.2）
 * @param output_json 输出结果JSON字符串，包含传播损失等计算结果
 *                    符合标准输出接口格式（规范2.3）
 * 
 * @return int 错误码
 *         200 - 计算成功
 *         500 - 计算失败
 * 
 * 输入JSON格式示例：
 * {
 *   "frequency": 1000.0,           // Hz
 *   "source": {
 *     "depth": 50.0,               // m
 *     "range": 0.0                 // m
 *   },
 *   "receiver": {
 *     "depth_min": 10.0,           // m
 *     "depth_max": 200.0,          // m
 *     "depth_count": 50,
 *     "range_min": 1000.0,         // m
 *     "range_max": 10000.0,        // m
 *     "range_count": 100
 *   },
 *   "environment": {
 *     "water_depth": 200.0,        // m
 *     "sound_speed_profile": [...],
 *     "bottom": {
 *       "density": 1.8,            // g/cm³
 *       "sound_speed": 1600.0,     // m/s
 *       "attenuation": 0.5         // dB/λ
 *     }
 *   },
 *   "calculation": {
 *     "ray_count": 100,
 *     "angle_min": -45.0,          // degrees
 *     "angle_max": 45.0            // degrees
 *   }
 * }
 * 
 * 输出JSON格式示例：
 * {
 *   "error_code": 200,             // 200成功，500失败
 *   "message": "计算成功完成",
 *   "model_name": "BellhopPropagationModel",
 *   "results": {
 *     "transmission_loss": {
 *       "values": [[...], [...]],  // dB
 *       "range_points": [...],     // m
 *       "depth_points": [...]      // m
 *     }
 *   },
 *   "units": {
 *     "frequency": "Hz",
 *     "depth": "m",
 *     "range": "m",
 *     "sound_speed": "m/s",
 *     "density": "g/cm³",
 *     "attenuation": "dB/λ"
 *   }
 * }
 * 
 * 单位规范：
 * - 频率：Hz (赫兹)
 * - 深度：m (米)
 * - 距离：m (米)
 * - 声速：m/s (米/秒)
 * - 密度：g/cm³ (克/立方厘米)
 * - 衰减：dB/λ (分贝/波长)
 */
BELLHOP_API int SolveBellhopPropagationModel(const char* input_json, char** output_json);

/**
 * 释放输出字符串内存
 * 
 * @param json_string 需要释放的JSON字符串指针
 */
BELLHOP_API void FreeBellhopJsonString(char* json_string);

/**
 * 获取模型版本信息
 * 
 * @return const char* 版本字符串
 */
BELLHOP_API const char* GetBellhopModelVersion();

} // extern "C"

// C++风格的接口（可选）
#ifdef __cplusplus
namespace BellhopPropagationModel {

/**
 * C++风格的计算接口
 * 
 * @param input_json 输入JSON字符串
 * @param output_json 输出JSON字符串（通过引用返回）
 * @return int 错误码：200成功，500失败
 */
BELLHOP_API int SolveBellhopPropagationModel(const std::string& input_json, std::string& output_json);

/**
 * 获取模型信息
 */
struct ModelInfo {
    std::string name;
    std::string version;
    std::string build_date;
    std::string compiler;
    std::string platform;
};

BELLHOP_API ModelInfo GetModelInfo();

} // namespace BellhopPropagationModel
#endif

#endif // BELLHOP_PROPAGATION_MODEL_INTERFACE_H
