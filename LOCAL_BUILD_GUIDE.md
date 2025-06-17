# BellhopPropagationModel 本地 Docker 多平台构建指南

本文档介绍如何使用本地 Docker 环境构建 BellhopPropagationModel 项目的多平台版本。

## 概述

本项目支持以下平台的本地构建：
- **CentOS 7 x86_64** - 兼容 GLIBC 2.17+ 的 x86_64 Linux 系统
- **Debian 11 x86_64** - 兼容 GLIBC 2.31+ 的 x86_64 Linux 系统  
- **Debian 11 ARM64** - 兼容 GLIBC 2.31+ 的 ARM64 Linux 系统
- **CentOS 8 ARM64** - 兼容 GLIBC 2.28+ 的 ARM64 Linux 系统
- **Windows 11 x86_64** - 支持 Windows 10+ 64位系统

## 环境要求

### Linux/macOS 环境
- Docker 20.10+
- Docker Buildx (多架构支持)
- Bash shell
- 至少 8GB 可用磁盘空间

### Windows 环境  
- Windows 10+ 64位系统
- PowerShell 5.0+
- 管理员权限（用于安装构建工具）
- 至少 4GB 可用磁盘空间

## 快速开始

### Linux 多平台构建

1. **一键构建所有平台**
   ```bash
   chmod +x build_local.sh
   ./build_local.sh -p all -v 3.8
   ```

2. **构建单个平台**
   ```bash
   # CentOS 7 x86_64
   ./build_local.sh -p centos7-x86_64 -v 3.9
   
   # Debian 11 ARM64
   ./build_local.sh -p debian11-arm64 -v 3.8
   ```

3. **自定义输出目录并清理旧产物**
   ```bash
   ./build_local.sh -p all -v 3.8 -o ./release -c
   ```

### Windows 本地构建

1. **基础构建**
   ```powershell
   .\build_windows.ps1 -PythonVersion 3.8
   ```

2. **自定义输出目录**
   ```powershell
   .\build_windows.ps1 -PythonVersion 3.9 -OutputDir "C:\Release" -Clean
   ```

## 详细说明

### build_local.sh 参数说明

```bash
./build_local.sh [选项]

选项:
  -p, --platform <platform>     指定构建平台
                                 支持: centos7-x86_64, debian11-x86_64, 
                                       debian11-arm64, centos8-arm64, all
  -v, --python-version <version> Python 版本 (3.8, 3.9, 3.10, 3.11)
  -o, --output <dir>             输出目录，默认 ./dist
  -c, --clean                    清理旧的构建产物
  -h, --help                     显示帮助信息
```

### build_windows.ps1 参数说明

```powershell
.\build_windows.ps1 [参数]

参数:
  -PythonVersion <version>  Python 版本 (3.8, 3.9, 3.10, 3.11)
  -OutputDir <dir>          输出目录
  -Clean                    清理旧的构建产物
  -Help                     显示帮助信息
```

## 构建产物

每个平台的构建产物包含：

```
dist/
├── <platform>-python<version>/
│   ├── bin/                    # 可执行文件
│   │   ├── bellhop
│   │   └── BellhopPropagationModel
│   ├── lib/                    # 动态库和Python模块
│   │   ├── libBellhopPropagationModel.so
│   │   └── *.cpython-*.so
│   ├── include/                # 头文件
│   │   └── BellhopPropagationModelInterface.h
│   └── build-info.txt          # 构建信息
└── build-summary.txt           # 构建汇总
```

## 平台兼容性

| 平台 | 架构 | GLIBC 要求 | 适用系统 |
|------|------|------------|----------|
| CentOS 7 x86_64 | x86_64 | 2.17+ | RHEL/CentOS 7+, Ubuntu 16.04+ |
| Debian 11 x86_64 | x86_64 | 2.31+ | Debian 11+, Ubuntu 20.04+ |
| Debian 11 ARM64 | ARM64 | 2.31+ | ARM64 Linux (树莓派4+, ARM服务器) |
| CentOS 8 ARM64 | ARM64 | 2.28+ | ARM64 RHEL/CentOS 8+ |
| Windows 11 x86_64 | x86_64 | - | Windows 10+ 64位 |

## 使用构建产物

1. **选择合适的平台版本**
   根据目标系统的架构和 GLIBC 版本选择对应的构建产物。

2. **部署到目标系统**
   ```bash
   # 复制构建产物到目标系统
   scp -r dist/centos7-x86_64-python3.8/* user@target:/opt/bellhop/
   
   # 设置可执行权限
   chmod +x /opt/bellhop/bin/*
   
   # 添加到 PATH
   export PATH="/opt/bellhop/bin:$PATH"
   export LD_LIBRARY_PATH="/opt/bellhop/lib:$LD_LIBRARY_PATH"
   ```

3. **验证安装**
   ```bash
   # 测试可执行文件
   BellhopPropagationModel --version
   
   # 测试 Python 模块
   python3 -c "import sys; sys.path.insert(0, '/opt/bellhop/lib'); import bellhop"
   ```

## 故障排除

### Docker 构建问题

1. **权限不足**
   ```bash
   sudo usermod -aG docker $USER
   # 重新登录或重启
   ```

2. **多架构支持未启用**
   ```bash
   docker buildx create --use --name multi-platform-builder
   docker buildx inspect --bootstrap
   ```

3. **磁盘空间不足**
   ```bash
   # 清理旧镜像
   docker system prune -a
   ```

### Windows 构建问题

1. **Chocolatey 安装失败**
   - 确保以管理员权限运行 PowerShell
   - 检查网络连接和防火墙设置

2. **Python 版本冲突**
   - 卸载旧版本 Python
   - 重启 PowerShell 会话

3. **编译工具缺失**
   ```powershell
   # 手动安装 Visual Studio Build Tools
   choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools"
   ```

### 运行时问题

1. **GLIBC 版本不兼容**
   ```bash
   # 检查系统 GLIBC 版本
   ldd --version
   
   # 选择更低版本的构建产物
   # 如当前系统 GLIBC 2.17，使用 centos7-x86_64 版本
   ```

2. **动态库找不到**
   ```bash
   # 设置库路径
   export LD_LIBRARY_PATH="/path/to/bellhop/lib:$LD_LIBRARY_PATH"
   
   # 或使用 ldconfig
   echo "/path/to/bellhop/lib" | sudo tee /etc/ld.so.conf.d/bellhop.conf
   sudo ldconfig
   ```

3. **Python 模块导入失败**
   ```python
   import sys
   sys.path.insert(0, "/path/to/bellhop/lib")
   import bellhop
   ```

## 自定义构建

### 修改 Python 依赖

编辑对应平台的设置脚本：
- `docker-local/centos7_setup.sh`
- `docker-local/debian11_setup.sh` 
- `docker-local/debian11_arm64_setup.sh`
- `docker-local/centos8_arm64_setup.sh`

### 修改 CMake 配置

编辑 `Dockerfile.*` 中的构建命令，或修改 `CMakeLists.txt`。

### 添加新平台

1. 创建新的设置脚本 `docker-local/<platform>_setup.sh`
2. 创建新的 Dockerfile `docker-local/Dockerfile.<platform>`
3. 修改 `build_local.sh` 添加平台支持

## 性能优化

### 加速构建

1. **使用缓存**
   ```bash
   # Docker 会自动缓存构建层
   # 修改代码后重新构建会更快
   ```

2. **并行构建**
   ```bash
   # 修改 Dockerfile 中的 make 参数
   make -j$(nproc)  # 使用所有CPU核心
   ```

3. **减少构建内容**
   - 使用 `.dockerignore` 排除不必要的文件
   - 只构建需要的平台

### 减少产物大小

1. **Strip 调试符号**
   ```bash
   strip bin/* lib/*.so
   ```

2. **移除不必要的文件**
   - 删除 `.pyc` 文件
   - 移除测试文件

## 持续集成

虽然本项目已改为本地构建，但您可以在自己的 CI/CD 环境中使用这些脚本：

```yaml
# 示例 GitHub Actions 配置
name: Local Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build all platforms
      run: ./build_local.sh -p all -v 3.8
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: bellhop-multi-platform
        path: dist/
```

## 联系支持

如有问题或建议，请：
1. 查看 `build-info.txt` 了解详细的构建信息
2. 检查 Docker 容器日志
3. 提供完整的错误信息和系统环境

---

**注意**: 本地构建需要较长时间，特别是首次构建。建议在网络良好且系统资源充足的环境中进行。
