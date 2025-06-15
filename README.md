# BellhopPropagationModel

海洋声传播计算工具，基于 Bellhop 算法的 C++ 动态库实现。

## 🚀 快速开始

### 构建项目
```bash
./manager.sh build
```

### 运行测试
```bash
./manager.sh test
```

### 创建交付包
```bash
./manager.sh delivery
```

## 📁 项目结构

```
BellhopPropagationModel/
├── bin/BellhopPropagationModel         # 可执行文件
├── lib/libBellhopPropagationModel.so   # 动态库
├── include/                            # 头文件
├── examples/                           # 使用示例
└── manager.sh                          # 项目管理脚本
```

## 🔧 管理命令

```bash
./manager.sh help          # 显示帮助
./manager.sh build         # 完整构建
./manager.sh test          # 运行测试
./manager.sh run           # 运行示例
./manager.sh status        # 检查状态
./manager.sh delivery      # 创建交付包
./manager.sh clean         # 清理构建文件
```

## 💻 使用方式

### 命令行使用
```bash
./bin/BellhopPropagationModel input.json output.json
```

### C++ 动态库接口
```cpp
#include "BellhopPropagationModelInterface.h"

std::string input_json = "{...}";
std::string output_json;
int result = SolveBellhopPropagationModel(input_json, output_json);
```

### 编译链接
```bash
g++ -o myapp myapp.cpp -L./lib -lBellhopPropagationModel
```

## 📋 系统要求

- **操作系统**: Linux 64位
- **Python**: 3.9+ (运行时需要)
- **编译器**: GCC 7.0+
- **构建工具**: CMake 3.10+

## 📦 输入输出格式

输入为 JSON 格式，包含频率、声源深度、接收器位置、海底地形、声速剖面等参数。
输出为 JSON 格式，包含传输损失、声压场、射线追踪等计算结果。

详细格式请参考 `input.json` 示例文件。

## 🛠️ 技术架构

- **核心计算**: Python + Nuitka 编译优化
- **接口层**: C++ 动态库
- **构建系统**: CMake + 自动化脚本
- **性能**: 比纯 Python 版本提升 20-50%

---
*版本: 1.0.0 | 海洋声传播计算工具*