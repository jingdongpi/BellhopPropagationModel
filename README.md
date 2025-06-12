# Bellhop声传播模型 - 生产环境版本

高性能的Bellhop声传播建模解决方案，提供C++动态库和可执行文件接口。

## 生产环境特性

- 🚀 **高性能**: 优化的C++核心，集成Python计算模块
- 📦 **自包含**: 无外部依赖，部署简单
- 🔧 **双接口**: 支持动态库调用和命令行使用
- 🌊 **完整功能**: 传输损失计算、射线追踪、压力场分析

## 项目结构

```
BellhopPropagationModel/
├── lib/
│   └── libBellhopPropagationModel.so    # 动态库 (47KB)
├── examples/
│   ├── BellhopPropagationModel          # 可执行文件 (50KB)
│   ├── input.json                       # 输入示例
│   └── output.json                      # 输出示例
├── include/
│   └── BellhopPropagationModelInterface.h  # C++头文件
├── python_core/                         # 核心计算模块
├── python_wrapper/                      # Python接口层
├── src/                                 # C++源代码
└── data/tmp/                           # 计算临时文件
```

## 快速使用

### 命令行接口
```bash
cd examples
./BellhopPropagationModel input.json output.json
```

### C++动态库接口
```cpp
#include "BellhopPropagationModelInterface.h"

const char* input_json = "{...}";
const char* result = SolveBellhopPropagationModel(input_json);
```

## 输入输出格式

输入JSON包含频率、声源深度、接收器配置、环境参数等。
输出JSON包含传输损失、接收器位置、计算结果等。

详细格式请参考 examples/input.json 和 examples/output.json。

## 系统要求

- **操作系统**: Linux (64位)
- **Python**: 3.8+ (运行时)
- **内存**: 最小512MB
- **存储**: 50MB + 临时文件空间

## 部署说明

1. 复制整个项目目录到目标服务器
2. 确保Python 3.8+环境可用
3. 设置执行权限：
   ```bash
   chmod +x lib/libBellhopPropagationModel.so
   chmod +x examples/BellhopPropagationModel
   ```
4. 运行测试：
   ```bash
   cd examples
   ./BellhopPropagationModel input.json output.json
   ```

## 技术支持

- **版本**: 生产就绪版本
- **技术栈**: C++17, Python 3.9, CMake
- **算法**: Bellhop海洋声学传播建模

---
*Bellhop声传播模型 - 高性能生产环境版本*
