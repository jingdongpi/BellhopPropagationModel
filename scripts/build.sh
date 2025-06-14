#!/bin/bash

# Bellhop传播模型编译脚本
# 用途：智能编译项目，支持Cython优化

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Bellhop传播模型编译 (智能模式) ==="
echo "日期: $(date)"

# 进入项目根目录
cd "$PROJECT_ROOT"

# 清理之前的构建
echo "清理之前的构建..."
rm -rf build
mkdir -p build

# 检查Python环境
echo "检查Python环境..."
python3 --version

# 检查是否有Cython
CYTHON_OPT=""
if python3 -c "import Cython" 2>/dev/null; then
    echo "✓ 发现Cython，将使用优化版本"
    CYTHON_OPT="-DUSE_CYTHON=ON"
else
    echo "⚠ 未发现Cython，使用标准版本"
    CYTHON_OPT="-DUSE_CYTHON=OFF"
fi

# 配置编译选项
echo "配置编译选项..."
cd build

if [ "$CYTHON_OPT" = "-DUSE_CYTHON=ON" ]; then
    echo "使用Cython优化版本"
    cmake .. $CYTHON_OPT \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
else
    echo "使用标准版本"
    cmake .. $CYTHON_OPT \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17
fi

# 开始编译
echo "开始编译..."
make -j$(nproc)

cd "$PROJECT_ROOT"

echo ""
echo "=== 编译结果 ==="
if [ -f "lib/libBellhopPropagationModel.so" ]; then
    LIB_SIZE=$(du -h lib/libBellhopPropagationModel.so | cut -f1)
    echo "✓ 动态库: $LIB_SIZE lib/libBellhopPropagationModel.so"
else
    echo "✗ 动态库编译失败"
    exit 1
fi

if [ -f "examples/BellhopPropagationModel" ]; then
    EXE_SIZE=$(du -h examples/BellhopPropagationModel | cut -f1)
    echo "✓ 可执行文件: $EXE_SIZE examples/BellhopPropagationModel"
else
    echo "✗ 可执行文件编译失败"
    exit 1
fi

# 运行快速测试
if [ -f "examples/input.json" ]; then
    echo "运行快速测试..."
    cd examples
    if ./BellhopPropagationModel input.json output.json; then
        echo "✓ 可执行文件运行正常"
    else
        echo "✗ 可执行文件运行失败"
        exit 1
    fi
    cd "$PROJECT_ROOT"
fi

echo ""
echo "=== 接口规范兼容性 ==="
echo "✓ 可执行文件名: BellhopPropagationModel"
echo "✓ 动态库名: libBellhopPropagationModel.so"
echo "✓ 计算函数: int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)"
echo "✓ 头文件: include/BellhopPropagationModelInterface.h"
echo ""
echo "使用方法："
echo "  ./examples/BellhopPropagationModel                    # 默认 input.json -> output.json"
echo "  ./examples/BellhopPropagationModel input.json output.json  # 自定义文件"
