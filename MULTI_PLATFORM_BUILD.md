# 🌍 多平台构建指南

## 🎯 支持的平台

我们的项目现在支持以下平台的自动构建：

### Windows
- **操作系统**: Windows Server 2019
- **Python版本**: 3.8, 3.10, 3.12
- **架构**: x86_64
- **编译器**: Visual Studio 2019 Build Tools
- **构建系统**: MSBuild + CMake

### Linux  
- **操作系统**: Ubuntu 22.04 LTS
- **Python版本**: 3.8, 3.10, 3.12
- **架构**: x86_64
- **编译器**: GCC
- **构建系统**: Make + CMake

## 📋 构建矩阵

总共 **6个构建配置**:

| 平台 | OS | Python | 架构 |
|------|----|---------|----- |
| Windows | windows-2019 | 3.8 | x86_64 |
| Windows | windows-2019 | 3.10 | x86_64 |
| Windows | windows-2019 | 3.12 | x86_64 |
| Linux | ubuntu-22.04 | 3.8 | x86_64 |
| Linux | ubuntu-22.04 | 3.10 | x86_64 |
| Linux | ubuntu-22.04 | 3.12 | x86_64 |

## 🔧 平台特定配置

### Windows 构建流程

1. **环境准备**:
   ```powershell
   # 安装Visual Studio Build Tools
   choco install visualstudio2019buildtools
   # 安装CMake
   choco install cmake
   ```

2. **Python依赖**:
   ```powershell
   pip install -r requirements.txt
   # numpy>=2.0.0, scipy>=1.7.0
   ```

3. **CMake配置**:
   ```powershell
   mkdir build
   cd build
   cmake .. -DBUILD_EXECUTABLE=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
   ```

4. **构建**:
   ```powershell
   cmake --build . --config Release --parallel
   ```

5. **构建产物**:
   - `bin/Release/BellhopPropagationModel.exe` (可执行文件)
   - `lib/Release/BellhopPropagationModel.dll` (动态库)

### Linux 构建流程

1. **环境准备**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y build-essential cmake gcc g++ make python3-dev
   ```

2. **Python依赖**:
   ```bash
   pip install -r requirements.txt
   # numpy>=2.0.0, scipy>=1.7.0
   ```

3. **CMake配置**:
   ```bash
   mkdir -p build
   cd build
   cmake .. -DBUILD_EXECUTABLE=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
   ```

4. **构建**:
   ```bash
   make -j$(nproc)
   ```

5. **构建产物**:
   - `bin/BellhopPropagationModel` (可执行文件)
   - `lib/libBellhopPropagationModel.so` (动态库)

## 📦 构建产物

### 自动上传

每次构建成功后，构建产物会自动上传为GitHub Artifacts：

- **命名格式**: `bellhop-build-{platform}-{arch}-python{version}`
- **保留时间**: 7天
- **包含文件**: 可执行文件、动态库、头文件

### 示例产物

```
bellhop-build-windows-x86_64-python3.12/
├── bin/Release/BellhopPropagationModel.exe
├── lib/Release/BellhopPropagationModel.dll
└── include/BellhopPropagationModelInterface.h

bellhop-build-linux-x86_64-python3.12/
├── bin/BellhopPropagationModel
├── lib/libBellhopPropagationModel.so
└── include/BellhopPropagationModelInterface.h
```

## 🧪 CI测试

### Linux CI测试 (`ci_test.sh`)
- 验证构建文件存在性
- 检查可执行文件权限
- 验证动态库依赖
- 功能测试
- Python环境验证

### Windows CI测试 (`ci_test_windows.ps1`)
- PowerShell脚本验证构建产物
- 检查.exe和.dll文件
- Python环境和依赖验证
- NumPy版本要求检查

## 🚀 触发构建

### 自动触发
- 推送到 `main`, `master`, `develop` 分支
- 创建Pull Request

### 手动触发
在GitHub Actions页面点击 "Run workflow"

## 📊 构建状态

可以在以下位置查看构建状态：
- GitHub仓库 → Actions 标签页
- 每个构建配置的详细日志
- 构建产物下载链接

## 🛠️ 本地开发

### Windows开发环境
```powershell
# 安装依赖
pip install -r requirements.txt

# 本地构建
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
cmake --build . --config Debug
```

### Linux开发环境
```bash
# 安装依赖
pip install -r requirements.txt

# 本地构建
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
```

## 🔍 故障排除

### 常见问题

1. **Windows构建失败**:
   - 检查Visual Studio Build Tools安装
   - 确认CMake路径配置
   - 验证Python开发库

2. **Linux构建失败**:
   - 检查系统依赖安装
   - 确认GCC版本兼容性
   - 验证Python开发头文件

3. **NumPy版本问题**:
   - 确保使用 NumPy >= 2.0.0
   - 检查Python版本兼容性
   - 更新requirements.txt

### 调试建议

1. **查看详细日志**: 在GitHub Actions中展开每个步骤
2. **下载构建产物**: 验证文件是否正确生成
3. **本地复现**: 使用相同的构建命令在本地测试
4. **检查依赖**: 确认所有依赖版本正确

## 📈 性能优化

### 构建加速
- 使用并行构建 (`-j$(nproc)`, `--parallel`)
- CMake缓存优化
- 依赖缓存（未来可添加）

### 资源管理
- 构建产物定期清理 (7天保留期)
- 失败日志收集 (3天保留期)
- 矩阵构建优化

---

🎉 **现在你的项目支持Windows和Linux的自动化构建！**
