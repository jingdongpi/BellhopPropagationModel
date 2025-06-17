#!/bin/bash

# GitHub Actions 构建脚本
# 简化版本，专门用于CI/CD环境

set -e

echo "🚀 GitHub Actions 构建开始..."

# 检查环境变量
if [ -z "$PYTHON_VERSION" ]; then
    export PYTHON_VERSION="3.8"
fi

echo "Python 版本: $PYTHON_VERSION"
echo "工作目录: $(pwd)"
echo "系统信息: $(uname -a)"

# 显示系统信息
echo "=== 系统信息 ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release
elif [ -f /etc/centos-release ]; then
    cat /etc/centos-release
fi

echo "=== GLIBC 版本 ==="
ldd --version | head -1 || echo "无法获取 GLIBC 版本"

echo "=== Python 信息 ==="
python --version || python3 --version
which python || which python3

# 激活编译环境（CentOS 7 需要）
if [ -f /opt/rh/devtoolset-7/enable ]; then
    echo "激活 devtoolset-7..."
    source /opt/rh/devtoolset-7/enable
fi

# 检查构建工具
echo "=== 构建工具检查 ==="
cmake --version || echo "CMake 未安装"
gcc --version || echo "GCC 未安装"
python -c "import nuitka; print(f'Nuitka {nuitka.__version__}')" || echo "Nuitka 未安装"

# 创建构建目录
echo "=== 开始构建 ==="
mkdir -p build
cd build

# 配置 CMake
echo "配置 CMake..."
PYTHON_EXECUTABLE=$(which python || which python3)
echo "使用 Python: $PYTHON_EXECUTABLE"

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXECUTABLE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DPython3_EXECUTABLE="$PYTHON_EXECUTABLE" \
    -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" \
    -DCMAKE_C_FLAGS="-static-libgcc"

# 编译
echo "编译项目..."
make -j$(nproc)

cd ..

# 编译 Python 模块
echo "=== 编译 Python 模块 ==="
if [ -f "scripts/compile_nuitka_cross_platform.py" ]; then
    python scripts/compile_nuitka_cross_platform.py
elif [ -f "scripts/01_compile_nuitka.py" ]; then
    python scripts/01_compile_nuitka.py
else
    echo "警告: 未找到 Nuitka 编译脚本"
fi

# 检查构建结果
echo "=== 构建结果检查 ==="
echo "bin/ 目录:"
ls -la bin/ 2>/dev/null || echo "bin/ 目录不存在"

echo "lib/ 目录:"
ls -la lib/ 2>/dev/null || echo "lib/ 目录不存在"

echo "include/ 目录:"
ls -la include/ 2>/dev/null || echo "include/ 目录不存在"

# 运行简单测试
echo "=== 运行测试 ==="
if [ -f "bin/BellhopPropagationModel" ]; then
    echo "可执行文件存在，检查依赖..."
    ldd bin/BellhopPropagationModel || echo "静态链接或无法检查依赖"
    
    # 尝试运行版本检查
    ./bin/BellhopPropagationModel --version 2>/dev/null || echo "无法运行版本检查"
fi

echo "✅ GitHub Actions 构建完成"
