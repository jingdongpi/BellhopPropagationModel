# BellhopPropagationModel

海洋声传播计算工具，基于 Bellhop 算法的 C++ 动态库实现。

## 🚀 快速开始

### 本地构建（推荐）

本项目现已**全面改为本地 Docker 构建**，支持多平台一键构建。

#### 1. 验证构建环境
```bash
./verify_build_env.sh
```

#### 2. 构建所有平台
```bash
# Linux/macOS
./build_local.sh -p all -v 3.8

# Windows (PowerShell)
.\build_windows.ps1 -PythonVersion 3.8
```

#### 3. 构建单个平台
```bash
# CentOS 7 x86_64 (兼容性最好)
./build_local.sh -p centos7-x86_64 -v 3.8

# Debian 11 ARM64
./build_local.sh -p debian11-arm64 -v 3.8
```

详细说明请参考：[本地构建指南](LOCAL_BUILD_GUIDE.md)

### 传统构建方式
```bash
./manager.sh build         # 本地环境构建
./manager.sh test          # 运行测试
./manager.sh delivery      # 创建交付包
```

## 📁 项目结构

```
BellhopPropagationModel/
├── bin/BellhopPropagationModel         # 可执行文件
├── lib/libBellhopPropagationModel.so   # 动态库
├── include/                            # 头文件
├── examples/                           # 使用示例
├── docker-local/                       # 本地 Docker 构建配置
│   ├── Dockerfile.centos7              # CentOS 7 x86_64
│   ├── Dockerfile.debian11             # Debian 11 x86_64
│   ├── Dockerfile.debian11-arm64       # Debian 11 ARM64
│   ├── Dockerfile.centos8-arm64        # CentOS 8 ARM64
│   └── *.sh                           # 各平台环境设置脚本
├── build_local.sh                      # Linux/macOS 多平台构建脚本
├── build_windows.ps1                   # Windows 本地构建脚本
├── verify_build_env.sh                 # 构建环境验证脚本
├── LOCAL_BUILD_GUIDE.md                # 详细构建指南
└── manager.sh                          # 项目管理脚本
```

## 🏗️ 支持的构建平台

| 平台 | 架构 | GLIBC 要求 | 适用系统 |
|------|------|------------|----------|
| CentOS 7 x86_64 | x86_64 | 2.17+ | RHEL/CentOS 7+, Ubuntu 16.04+ |
| Debian 11 x86_64 | x86_64 | 2.31+ | Debian 11+, Ubuntu 20.04+ |
| Debian 11 ARM64 | ARM64 | 2.31+ | ARM64 Linux (树莓派4+) |
| CentOS 8 ARM64 | ARM64 | 2.28+ | ARM64 RHEL/CentOS 8+ |
| Windows 11 x86_64 | x86_64 | - | Windows 10+ 64位 |

## 🔧 管理命令

### 本地多平台构建
```bash
# 环境验证
./verify_build_env.sh

# 一键构建所有平台
./build_local.sh -p all -v 3.8

# 构建特定平台
./build_local.sh -p centos7-x86_64 -v 3.9

# Windows 构建 (PowerShell)
.\build_windows.ps1 -PythonVersion 3.8

# 查看帮助
./build_local.sh --help
```

### 传统构建命令
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

### 构建环境
- **Docker**: 20.10+ (支持多架构构建)
- **操作系统**: Linux/macOS/Windows 
- **磁盘空间**: 至少 8GB 可用空间
- **网络**: 用于下载基础镜像

### 运行环境
- **Linux**: 根据构建平台的 GLIBC 版本要求
- **Windows**: Windows 10+ 64位系统
- **Python**: 不需要（已通过 Nuitka 编译为二进制）

## 📦 输入输出格式

输入为 JSON 格式，包含频率、声源深度、接收器位置、海底地形、声速剖面等参数。
输出为 JSON 格式，包含传输损失、声压场、射线追踪等计算结果。

详细格式请参考 `input.json` 示例文件。

## 🛠️ 技术架构

- **多平台支持**: Docker 本地构建，支持 x86_64 和 ARM64
- **核心计算**: Python + Nuitka 编译优化
- **接口层**: C++ 动态库
- **构建系统**: CMake + Docker + 自动化脚本
- **性能**: 比纯 Python 版本提升 20-50%
- **兼容性**: 支持不同 GLIBC 版本，向下兼容

## 📚 文档

- [本地构建指南](LOCAL_BUILD_GUIDE.md) - 详细的多平台构建说明
- [构建历史](.github/workflows-archive/README.md) - 旧版 CI/CD 配置存档

---
*版本: 1.0.0 | 海洋声传播计算工具 | 本地 Docker 多平台构建*