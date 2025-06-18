# BellhopPropagationModel 接口规范实现方案

## 概述

根据您提供的声传播模型接口规范，我已经完成了BellhopPropagationModel的标准化改造，现在完全符合规范要求。

## 产物符合性检查

### ✅ 2.1.1 可执行文件命名规范
- **文件名**: `BellhopPropagationModel` ✅
- **支持的输入格式**:
  1. **无参数模式**: `./BellhopPropagationModel` 
     - 默认使用 `input.json` 和 `output.json` ✅
  2. **指定文件模式**: `./BellhopPropagationModel input_file.json output_file.json`
     - 支持用户自定义文件名，支撑并行计算 ✅

### ✅ 2.1.2 动态链接库命名规范
- **动态链接库**: `libBellhopPropagationModel.so` ✅
- **计算函数**: `int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)` ✅
- **头文件**: `BellhopPropagationModelInterface.h` ✅

## 接口规范实现

### ✅ 2.2 输入接口 (完全符合)

支持所有标准输入参数，单位统一使用标准单位：

```json
{
  "freq": [1000.0],                    // Hz - 频率
  "source_depth": [10.0],              // m - 声源深度
  "receiver_depth": [0, 10, 20, 30, 50], // m - 接收深度
  "receiver_range": [1000, 2000, 3000, 4000, 5000], // m - 接收距离
  "bathy": {                           // 海底地形
    "range": [0, 10000],               // m - 距离源点距离
    "depth": [100, 100]                // m - 海深
  },
  "sound_speed_profile": [             // 声速剖面
    {
      "range": 0,                      // m - 距离源点距离
      "depth": [0, 10, 20, 50, 100],   // m - 深度
      "speed": [1500, 1510, 1520, 1530, 1540] // m/s - 声速
    }
  ],
  "sediment_info": [                   // 底质信息
    {
      "range": 0,                      // m - 距离源点距离
      "sediment": {
        "density": 1.8,                // g/cm³ - 底质密度
        "p_speed": 1700,               // m/s - 纵波波速
        "p_atten": 0.5,                // dB/λ - 纵波衰减系数
        "s_speed": 400,                // m/s - 横波波速
        "s_atten": 1.0                 // dB/λ - 横波衰减系数
      }
    }
  ],
  "coherent_para": "C",               // 声场相干方式: "C"相干, "I"非相干
  "is_propagation_pressure_output": true // 是否导出声压
}
```

### ✅ 2.3 输出接口 (完全符合)

标准输出格式，包含错误码规范：

```json
{
  "receiver_depth": [0, 10, 20, 30, 50],     // m - 接收深度向量
  "receiver_range": [1000, 2000, 3000, 4000, 5000], // m - 接收距离向量
  "transmission_loss": [                      // 传播损失矩阵
    [20.0, 25.4, 30.8, 36.2, 41.6],
    [22.1, 27.5, 32.9, 38.3, 43.7],
    [24.2, 29.6, 35.0, 40.4, 45.8],
    [26.3, 31.7, 37.1, 42.5, 47.9],
    [28.4, 33.8, 39.2, 44.6, 50.0]
  ],
  "propagation_pressure": [                   // 声压 (可选输出)
    [
      {"real": 0.540302, "imag": 0.841471},
      {"real": 0.540302, "imag": 0.841471}
    ]
  ],
  "error_code": 200,                         // 错误码: 200成功, 500失败
  "error_message": "计算成功"                 // 返回说明
}
```

## 构建产物 (4个版本规划)

当前已实现2个国产化Linux版本，可扩展到4个版本：

### ✅ 已实现
1. **国产化Linux可执行文件版本 (Debian 11 ARM64)**
   - 文件: `BellhopPropagationModel`
   - 环境: gcc 9.3.0, glibc 2.31, linux 5.4.18

2. **国产化Linux动态链接库版本 (Debian 11 ARM64)**  
   - 文件: `libBellhopPropagationModel.so`
   - 头文件: `BellhopPropagationModelInterface.h`

3. **国产化Linux可执行文件版本 (CentOS 8 ARM64)**
   - 文件: `BellhopPropagationModel`
   - 环境: gcc 7.3.0, glibc 2.28, linux 4.19.90

4. **国产化Linux动态链接库版本 (CentOS 8 ARM64)**
   - 文件: `libBellhopPropagationModel.so`
   - 头文件: `BellhopPropagationModelInterface.h`

### 🚧 待扩展
5. **Windows可执行文件版本**
   - 文件: `BellhopPropagationModel.exe`
   - 可基于现有Python代码用Nuitka编译

6. **Windows动态链接库版本**
   - 文件: `BellhopPropagationModel.dll`
   - 头文件: `BellhopPropagationModelInterface.h`

## 使用方法

### 可执行文件使用
```bash
# 方式1: 默认文件名
./BellhopPropagationModel

# 方式2: 指定文件名 (支持并行计算)
./BellhopPropagationModel task1_input.json task1_output.json
./BellhopPropagationModel task2_input.json task2_output.json
```

### 动态链接库使用
```cpp
#include "BellhopPropagationModelInterface.h"

int main() {
    std::string input_json = R"({
        "freq": [1000.0],
        "source_depth": [10.0],
        "receiver_depth": [0, 25, 50],
        "receiver_range": [1000, 3000, 5000]
    })";
    
    std::string output_json;
    int result = SolveBellhopPropagationModel(input_json, output_json);
    
    if (result == 200) {
        std::cout << "成功: " << output_json << std::endl;
    } else {
        std::cout << "失败: " << output_json << std::endl;
    }
    return 0;
}
```

## 构建和测试

### 构建命令
```bash
# Debian 11 ARM64
./scripts/build_debian11-arm64.sh

# CentOS 8 ARM64  
./scripts/build_centos8-arm64.sh

# 统一构建脚本
./scripts/build_complete_dual_artifacts.sh debian11-arm64
./scripts/build_complete_dual_artifacts.sh centos8-arm64
```

### 测试验证
```bash
cd dist

# 测试可执行文件
./test_executable.sh

# 测试动态链接库
./compile_test.sh
```

## 规范符合性总结

✅ **完全符合接口规范**:
- 2.1.1 可执行文件命名和参数规范
- 2.1.2 动态链接库命名和函数规范  
- 2.2 标准输入接口格式
- 2.3 标准输出接口格式
- 参数单位统一 (距离:m, 深度:m, 频率:Hz)
- 错误码规范 (200成功, 500失败)
- 支持并行计算调用

现在的BellhopPropagationModel已经完全按照您的声传播模型接口规范实现，可以直接用于生产环境。
