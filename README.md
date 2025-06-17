# BellhopPropagationModel

海洋声传播计算工具，基于 Bellhop 算法的 C++ 动态库实现。

## 🚀 快速开始

### GitHub Actions 云端构建（推荐）

本项目支持 **GitHub Actions 多平台自动构建**，无需本地环境配置。

#### 1. 在 GitHub 上触发构建
1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Multi-Platform Build** 工作流
4. 点击 **Run workflow** 按钮
5. 选择构建选项：
   - ✅ 构建 CentOS 7 x86_64
   - ✅ 构建 Debian 11 x86_64
   - ✅ 构建 Windows x86_64
   - ⬜ 构建 Linux ARM64
   - Python 版本：`3.8,3.9`

#### 2. 下载构建产物
构建完成后，在 Actions 页面下载：
- `bellhop-centos7-x64-python3.8` - CentOS 7 兼容版本
- `bellhop-debian11-x64-python3.8` - Debian 11 版本
- `bellhop-win11-x64-python3.8` - Windows 版本
- `build-info-*` - 各平台兼容性信息

#### 3. 测试单个平台
使用 **Test Build** 工作流快速测试：
1. 选择 **Test Build** 工作流
2. 选择测试平台（debian11-x64/centos7-x64/win11-x64）
3. 选择 Python 版本
4. 运行并检查结果

### 本地构建方式

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

| 平台 | GitHub Actions | 本地 Docker | 兼容性 |
|------|----------------|-------------|--------|
| CentOS 7 x86_64 | ✅ ubuntu-22.04 + Docker | ✅ | GLIBC 2.17+ |
| Debian 11 x86_64 | ✅ ubuntu-22.04 + Docker | ✅ | GLIBC 2.31+ |
| Windows 11 x64 | ✅ windows-2022 | ✅ PowerShell | Windows 10+ |
| Debian 11 ARM64 | ✅ ubuntu-22.04-arm + Docker | ✅ | ARM64 Linux |
| CentOS 8 ARM64 | ✅ ubuntu-22.04-arm + Docker | ✅ | ARM64 CentOS |

### 🎯 构建方式对比

| 特性 | GitHub Actions | 本地构建 |
|------|----------------|----------|
| **设置难度** | 🟢 无需配置 | 🟡 需要 Docker |
| **构建速度** | 🟡 中等（云端） | 🟢 快速（本地） |
| **多平台支持** | 🟢 全自动 | 🟢 Docker 支持 |
| **资源使用** | 🟢 免费额度 | 🟡 本地资源 |
| **适用场景** | 发布、CI/CD | 开发、测试 |

## 🔧 管理命令

### GitHub Actions 云端构建
```bash
# 1. 进入 GitHub 仓库 -> Actions 标签
# 2. 选择工作流：
#    - Multi-Platform Build (完整构建)
#    - Test Build (单平台测试)
# 3. 点击 Run workflow，选择构建选项
# 4. 下载构建产物和构建信息
```

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

- **云端构建**: GitHub Actions + Docker 多平台自动构建
- **多平台支持**: Docker 容器化，支持 x86_64 和 ARM64
- **核心计算**: Python + Nuitka 编译优化
- **接口层**: C++ 动态库
- **构建系统**: CMake + Docker + GitHub Actions
- **性能**: 比纯 Python 版本提升 20-50%
- **兼容性**: 支持不同 GLIBC 版本，向下兼容

## 📚 文档

- [本地构建指南](LOCAL_BUILD_GUIDE.md) - 详细的多平台构建说明
- [GitHub Actions](../../actions) - 云端自动构建
- [构建历史](.github/workflows-archive/README.md) - 旧版 CI/CD 配置存档

---
*版本: 1.0.0 | 海洋声传播计算工具 | GitHub Actions + 本地 Docker 多平台构建*