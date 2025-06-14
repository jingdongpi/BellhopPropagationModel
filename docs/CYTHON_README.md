# BellhopPropagationModel - Cython优化版本

基于 Cython 的高性能声传播建模解决方案，符合接口规范要求。

## 编译步骤

### 1. 安装依赖
```bash
pip install cython numpy setuptools
```

### 2. 编译 Cython 模块
```bash
python setup_cython.py build_ext --inplace
```

### 3. 编译 C++ 库和可执行文件
```bash
mkdir -p build && cd build
cmake ..
make -j$(nproc)
```

## 接口规范兼容性

### 可执行文件
- 文件名: `BellhopPropagationModel` (位于 examples/ 目录)
- 无参数运行: `./BellhopPropagationModel` (使用默认 input.json 和 output.json)
- 带参数运行: `./BellhopPropagationModel input_custom.json output_custom.json`

### 动态链接库
- 库文件: `libBellhopPropagationModel.so` (位于 lib/ 目录)
- 计算函数: `int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)`
- 头文件: `BellhopPropagationModelInterface.h` (位于 include/ 目录)

## 性能优化

- Python 核心模块编译为 Cython 扩展
- 移除 Python 解释器依赖
- 静态链接优化编译
- 生产环境优化标志

## 部署说明

编译完成后，只需要分发：
1. `examples/BellhopPropagationModel` - 可执行文件
2. `lib/libBellhopPropagationModel.so` - 动态库
3. `include/BellhopPropagationModelInterface.h` - 头文件

无需 Python 运行时环境。
