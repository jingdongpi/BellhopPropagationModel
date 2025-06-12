#!/bin/bash

echo "开始构建Bellhop传播模型..."

# 激活正确的Python环境
export PATH="/home/shunli/.pyenv/versions/3.9.19/bin:$PATH"
export PYTHON_ROOT="/home/shunli/.pyenv/versions/3.9.19"

# 检查Python环境
chmod +x check_python_setup.sh
./check_python_setup.sh

# 清理之前的构建
rm -rf build/*
mkdir -p build

cd build

# 配置CMake，明确指定Python路径
echo "配置CMake..."
cmake .. \
    -DPython3_ROOT_DIR="/home/shunli/.pyenv/versions/3.9.19" \
    -DPython3_EXECUTABLE="/home/shunli/.pyenv/versions/3.9.19/bin/python3" \
    -DCMAKE_VERBOSE_MAKEFILE=ON

if [ $? -ne 0 ]; then
    echo "❌ CMake配置失败，请检查Python路径"
    exit 1
fi

# 编译
echo "开始编译..."
make VERBOSE=1

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

cd ..

echo "✅ 构建完成"