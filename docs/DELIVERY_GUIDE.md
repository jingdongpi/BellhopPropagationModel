# BellhopPropagationModel 交付包使用说明

**版本**: v1.0.0  
**平台**: Linux x64

## 📦 交付内容

- `bin/BellhopPropagationModel` - 可执行文件
- `lib/libBellhopPropagationModel.so` - C++ 动态库
- `lib/*.so` - Python 模块（Nuitka 编译）
- `include/BellhopPropagationModelInterface.h` - C++ 接口头文件
- `examples/` - 使用示例和输入文件
- `scripts/` - 快速开始和编译脚本

## 🔧 运行环境要求

### 系统要求
- **操作系统**: Linux 64位 (Ubuntu 18.04+, CentOS 7+)
- **架构**: x86_64

### Python 环境 (必须安装)
- **Python 版本**: 3.8 - 3.11 (自动检测兼容版本)
- **必需 Python 库**:
  ```bash
  pip install numpy scipy
  ```

### 🔄 自动环境适配
程序启动时会自动：
- 检测可用的 Python 版本 (3.8/3.9/3.10/3.11)
- 自动搜索 numpy/scipy 安装路径
- 动态设置 Python 模块搜索路径
- 提供详细的依赖检测报告

如果环境检测失败，程序会提供具体的安装建议。

### 可选依赖 (仅编译示例时需要)
- **编译器**: GCC 7.0+
- **构建工具**: make

## 🚀 快速开始

### 1. 检查环境
```bash
# 检查 Python 版本
python3 --version  # 应该 >= 3.8

# 检查必需库
python3 -c "import numpy, scipy; print('环境检查通过')"
```

### 2. 运行可执行文件
```bash
# 设置环境变量（必须）
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH  # 动态库路径
export PYTHONPATH=$PWD/lib:$PYTHONPATH           # Python模块路径

# 使用默认输入文件
./bin/BellhopPropagationModel examples/input.json output.json

# 检查输出
ls -la output.json
```

### 3. 一键测试脚本（推荐）
```bash
# 自动设置环境变量并运行测试
./scripts/quick_start.sh
```

## 💻 C++ 动态库使用

### 接口说明
动态库提供标准的 C++ 接口，用于声传播计算：

```cpp
// 主计算函数
int SolveBellhopPropagationModel(const std::string& input_json, std::string& output_json);

// 获取版本信息  
const char* GetBellhopPropagationModelVersion();
```

### 编译链接示例
```bash
# 编译您的程序
g++ -std=c++17 -I./include -o myapp myapp.cpp -L./lib -lBellhopPropagationModel

# 运行前设置库路径
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
./myapp
```

### C++ 使用示例
参考 `examples/use_library_example.cpp`：

```cpp
#include "BellhopPropagationModelInterface.h"
#include <iostream>
#include <string>

int main() {
    // 输入 JSON 数据
    std::string input_json = R"({
        "freq": [1000.0],
        "source_depth": [10.0],
        "receiver_depth": [25.0, 50.0],
        "receiver_range": [1000.0, 2000.0],
        "bathy": {
            "range": [0, 2000],
            "depth": [100, 110]
        },
        "sound_speed_profile": [...],
        "sediment_info": [...],
        "ray_model_para": {...}
    })";
    
    // 调用计算函数
    std::string output_json;
    int result = SolveBellhopPropagationModel(input_json, output_json);
    
    if (result == 200) {
        std::cout << "计算成功" << std::endl;
        std::cout << "结果: " << output_json << std::endl;
    } else {
        std::cout << "计算失败，错误码: " << result << std::endl;
        std::cout << "错误信息: " << output_json << std::endl;
    }
    
    return 0;
}
```

### 编译和运行示例
```bash
# 编译示例程序
./scripts/compile_example.sh

# 运行示例
cd examples && ./use_library_example
```

## 📋 输入输出格式

### 输入 JSON 格式
详见 `examples/input.json` 文件，主要参数：
- `freq`: 频率数组 (Hz)
- `source_depth`: 声源深度 (m)
- `receiver_depth`: 接收器深度数组 (m)  
- `receiver_range`: 接收器距离数组 (m)
- `bathy`: 海底地形数据
- `sound_speed_profile`: 声速剖面数据
- `sediment_info`: 沉积物信息
- `ray_model_para`: 射线模型参数

### 输出 JSON 格式
- `error_code`: 错误码 (200=成功)
- `error_message`: 错误信息
- `transmission_loss`: 传输损失矩阵
- `receiver_depth` / `receiver_range`: 接收器位置
- `propagation_pressure`: 声压场数据 (可选)
- `ray_trace`: 射线追踪数据 (可选)

## 🔍 故障排除

### 常见问题

1. **"Python 模块加载失败"**
   ```bash
   # 检查 Python 环境
   python3 --version
   python3 -c "import numpy, scipy"
   
   # 安装缺失的库
   pip install numpy scipy
   ```

2. **"动态库加载失败"**
   ```bash
   # 设置库路径
   export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
   
   # 检查库依赖
   ldd bin/BellhopPropagationModel
   ```

3. **"编译示例失败"**
   ```bash
   # 检查编译器
   gcc --version  # 需要 GCC 7.0+
   
   # 检查头文件
   ls -la include/BellhopPropagationModelInterface.h
   ```

4. **"计算结果错误"**
   ```bash
   # 检查输入文件格式
   python3 -m json.tool examples/input.json
   ```

### 运行时环境检查
```bash
echo "=== 环境检查 ==="
echo "Python 版本: $(python3 --version)"
echo "NumPy: $(python3 -c 'import numpy; print(numpy.__version__)' 2>/dev/null || echo '未安装')"
echo "SciPy: $(python3 -c 'import scipy; print(scipy.__version__)' 2>/dev/null || echo '未安装')"
echo "动态库: $(ls -la lib/libBellhopPropagationModel.so)"
echo "可执行文件: $(ls -la bin/BellhopPropagationModel)"
```

## 📞 技术支持

- 检查输入文件格式是否正确
- 确保所有依赖库已安装
- 运行环境检查脚本进行诊断
- 查看 error_code 和 error_message 获取错误详情

---
*BellhopPropagationModel v1.0.0 - 专业海洋声传播计算工具*
