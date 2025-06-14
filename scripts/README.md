# Bellhop传播模型项目脚本目录

## 概述
本目录包含了 Bellhop 传播模型项目的核心管理脚本，采用简化设计，专注于核心功能。
使用项目根目录下的 `manager.sh` 进行统一管理。

## 快速使用

```bash
# 返回项目根目录
cd /home/shunli/AcousticProjects/BellhopPropagationModel

# 完整编译流程
./manager.sh build

# 检查依赖
./manager.sh deps  

# 清理项目
./manager.sh clean

# 测试运行
./manager.sh test

# 显示帮助
./manager.sh help
```

## 脚本说明

### 核心脚本（按编号顺序）
```
scripts/
├── 01_compile_nuitka.py    # Nuitka Python模块编译
├── 02_check_deps.py        # 项目依赖检查
├── 03_build_legacy.sh      # 传统构建脚本（备用）
└── 04_cleanup.sh           # 编译产物清理
```

### 脚本功能

#### `01_compile_nuitka.py`
- **功能**: 使用 Nuitka 编译 Python 模块为优化的 .so 库
- **输入**: `python_core/` 和 `python_wrapper/` 下的 Python 文件
- **输出**: `lib/` 目录下的编译后的 .so 文件
- **使用**: `python scripts/01_compile_nuitka.py`

#### `02_check_deps.py`
- **功能**: 检查项目所需的 Python 依赖和系统工具
- **检查项**: NumPy, SciPy, Nuitka, CMake, GCC等
- **使用**: `python scripts/02_check_deps.py`

#### `03_build_legacy.sh`
- **功能**: 传统的完整构建脚本（备用）
- **说明**: 包含完整的构建流程，作为备份方案
- **使用**: `./scripts/03_build_legacy.sh`

#### `04_cleanup.sh`
- **功能**: 清理所有编译产物和临时文件
- **清理项**: build/, lib/*.so, bin/可执行文件等
- **使用**: `./scripts/04_cleanup.sh`

## 统一管理

**推荐使用项目根目录的 `scripts_manager.sh` 进行统一管理：**

```bash
# 完整编译项目
./scripts_manager.sh build

# 仅编译 Python 模块
./scripts_manager.sh nuitka

# 仅编译 C++ 程序
./scripts_manager.sh cpp

# 检查依赖
./scripts_manager.sh deps

# 运行测试
./scripts_manager.sh test

# 清理项目
./scripts_manager.sh clean

# 查看帮助
./scripts_manager.sh help
```

## 编译流程

### 标准编译流程
1. **依赖检查**: `02_check_deps.py`
2. **Python编译**: `01_compile_nuitka.py` 
3. **C++编译**: CMake + Make
4. **测试验证**: 运行生成的可执行文件

### 输出文件
- **可执行文件**: `bin/BellhopPropagationModel`
- **动态库**: `lib/libBellhopPropagationModel.so`
- **Python库**: `lib/*.cpython-39-x86_64-linux-gnu.so`

## 维护说明

### 简化原则
- 移除了复杂的编号脚本（00-06, 99等）
- 移除了 Windows 相关脚本（.bat文件）
- 专注于 Linux 平台的核心功能
- 使用统一的命名规范

### 版本控制
- 所有脚本都进行版本控制
- 修改脚本后请更新相应的文档
- 保持脚本的简洁性和可维护性

## 故障排除

### 常见问题
1. **依赖缺失**: 运行 `./scripts_manager.sh deps` 检查
2. **编译失败**: 查看具体错误信息，通常是依赖或路径问题
3. **权限问题**: 确保脚本有执行权限 `chmod +x scripts/*.sh`

### 支持
- 项目根目录: `/home/shunli/AcousticProjects/BellhopPropagationModel`
- 脚本目录: `scripts/`
- 日志文件: 查看终端输出

---

**最后更新**: 2025-06-14  
**版本**: v3.0 - 简化版本
