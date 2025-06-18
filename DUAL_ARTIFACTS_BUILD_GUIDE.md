# BellhopPropagationModel 双产物构建方案

## 概述

根据您的需求，我已经修改了构建脚本来支持在GitHub Actions的不同Docker镜像内构建两种产物：

1. **独立二进制文件** - 使用Nuitka编译的完全自包含可执行文件
2. **C++动态库** - 自包含的动态库，可嵌入其他C++应用程序

## 支持平台

### 1. Debian 11 ARM64
- **目标环境**: gcc 9.3.0、glibc 2.31、linux 5.4.18
- **构建脚本**: `scripts/build_debian11-arm64.sh`
- **特点**: 更新的工具链，更好的兼容性

### 2. CentOS 8 ARM64  
- **目标环境**: gcc 7.3.0、glibc 2.28、linux 4.19.90
- **构建脚本**: `scripts/build_centos8-arm64.sh`
- **特点**: 更老的基础库，更广泛的兼容性

## 使用方法

### 方式1: 使用统一构建脚本
```bash
# Debian 11 ARM64 构建
./scripts/build_complete_dual_artifacts.sh debian11-arm64

# CentOS 8 ARM64 构建  
./scripts/build_complete_dual_artifacts.sh centos8-arm64
```

### 方式2: 直接调用平台脚本
```bash
# Debian 11 构建
./scripts/build_debian11-arm64.sh

# CentOS 8 构建
./scripts/build_centos8-arm64.sh
```

## 构建产物

每次构建完成后，会在 `dist/` 目录生成以下文件：

### 核心产物
- `BellhopPropagationModel` - 独立二进制文件
- `libBellhopPropagationModel.so` - C++动态库
- `bellhop_wrapper.h` - C++接口头文件

### 测试和文档
- `test_library.cpp` - C++测试程序源码
- `compile_test.sh` - 编译测试脚本
- `README.md` - 使用说明

## 特性

### 独立二进制文件
- ✅ 完全自包含，无需Python环境
- ✅ 静态链接所有依赖
- ✅ 支持命令行参数
- ✅ JSON输入输出格式

### C++动态库
- ✅ 嵌入式Python解释器
- ✅ C风格API接口
- ✅ 自动内存管理
- ✅ 错误处理机制

## GitHub Actions 集成

构建脚本设计用于在GitHub Actions的Docker容器中运行：

```yaml
# .github/workflows/build.yml 示例
- name: Build Debian 11 ARM64
  run: |
    docker run --rm -v $PWD:/workspace -w /workspace \
      debian:11 ./scripts/build_complete_dual_artifacts.sh debian11-arm64

- name: Build CentOS 8 ARM64  
  run: |
    docker run --rm -v $PWD:/workspace -w /workspace \
      centos:8 ./scripts/build_complete_dual_artifacts.sh centos8-arm64
```

## 快速测试

构建完成后可以立即测试：

```bash
cd dist

# 测试二进制文件
./BellhopPropagationModel '{"frequency": 1000, "source_depth": 10}'

# 测试动态库
./compile_test.sh
```

## 技术实现

1. **Nuitka编译**: 将Python代码编译为独立二进制文件
2. **静态链接**: 使用 `--static-libpython=yes` 避免Python依赖
3. **C++包装器**: 提供标准C API接口
4. **内存管理**: 自动处理Python对象生命周期
5. **错误处理**: 完整的异常捕获和处理机制

这个方案完全符合您的要求，不考虑客户电脑的Python版本，直接在Docker镜像内构建自包含的产物。
