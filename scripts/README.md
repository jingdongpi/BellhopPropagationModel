# Bellhop传播模型项目管理指南

## 概述
本项目提供了 Bellhop 传播模型的 Cython+Python 优化实现，包含完整的构建、交付和管理脚本。

## 脚本目录结构
```
scripts/
├── build.sh                    # 智能编译脚本
├── create_delivery_package.sh  # 交付包创建脚本
├── cleanup.sh                  # 项目清理脚本
└── README.md                   # 本文件
```

## 使用方法

### 1. 编译项目
```bash
./scripts/build.sh
```
- 自动检测 Cython 环境
- 智能选择编译选项
- 运行快速测试验证
- 输出编译结果和接口兼容性信息

### 2. 创建交付包
```bash
./scripts/create_delivery_package.sh
```
- 检查编译产物，如需要会自动编译
- 收集所有必要文件到 `BellhopPropagationModel_Delivery/`
- 创建完整的使用文档和测试脚本
- 正确配置 Python 模块路径

### 3. 清理项目
```bash
./scripts/cleanup.sh
```
- 清理所有编译产物
- 删除临时文件和缓存
- 清理交付包目录

## 编译要求
- Linux x86_64 系统
- GCC/G++ 编译器
- CMake 3.10+
- Python 3.9+
- numpy 库
- Cython（可选，用于性能优化）

## 交付包内容
交付包 `BellhopPropagationModel_Delivery/` 包含：
- `bin/BellhopPropagationModel` - 主可执行文件
- `lib/libBellhopPropagationModel.so` - 动态库
- `lib/*.so` - Cython 扩展模块
- `lib/python_modules/` - Python 核心模块
- `include/BellhopPropagationModelInterface.h` - C++ 接口头文件
- `examples/` - 输入输出示例
- `docs/` - 详细文档
- `test.sh` - 快速测试脚本
- `README.md` - 使用说明

## 接口规范兼容性
本项目完全符合接口规范：
- ✅ 可执行文件名：`BellhopPropagationModel`
- ✅ 动态库名：`libBellhopPropagationModel.so`
- ✅ C++ 接口函数：`int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)`
- ✅ 头文件：`BellhopPropagationModelInterface.h`
- ✅ 支持两种调用方式：
  - 无参数：使用默认的 `input.json` -> `output.json`
  - 双参数：`./BellhopPropagationModel input.json output.json`

## 技术方案
- **核心算法**：基于原有 Python 实现
- **性能优化**：使用 Cython 编译关键模块
- **接口封装**：C++ 包装器调用 Python 核心
- **依赖管理**：需要系统安装 Python 3.9+ 和 numpy
- **外部依赖**：需要 bellhop 二进制文件在系统 PATH 中

## 故障排除

### 编译问题
1. 检查 CMake 版本：`cmake --version`
2. 检查 Python 环境：`python3 --version`
3. 检查 numpy 安装：`python3 -c "import numpy; print(numpy.__version__)"`

### 运行问题
1. 检查 bellhop 安装：`which bellhop`
2. 检查环境变量配置
3. 查看详细错误信息

### 模块导入问题
确保在交付包中正确设置了环境变量：
```bash
export PYTHONPATH=$PWD/lib:$PWD/lib/python_modules:$PYTHONPATH
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
```

## 版本历史
- v1.0：初始版本，基础 Python 实现
- v2.0：添加 Cython 优化
- v3.0：完善交付包和脚本管理

## 联系信息
如有问题或建议，请联系项目维护团队。
