#!/bin/bash
# Bellhop声传播模型 - 生产环境部署脚本

echo "Bellhop声传播模型 - 生产环境部署"
echo "================================"

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_ROOT"

# 检查系统要求
echo "1. 检查系统要求..."

# 检查Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
    echo "✓ Python $PYTHON_VERSION 已安装"
else
    echo "✗ Python 3.8+ 是必需的"
    exit 1
fi

# 检查核心文件
echo "2. 验证核心文件..."

REQUIRED_FILES=(
    "lib/libBellhopPropagationModel.so"
    "examples/BellhopPropagationModel"
    "examples/input.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ 缺失: $file"
        exit 1
    fi
done

# 设置权限
echo "3. 设置执行权限..."
chmod +x lib/libBellhopPropagationModel.so
chmod +x examples/BellhopPropagationModel
echo "✓ 权限设置完成"

# 创建必要目录
echo "4. 创建数据目录..."
mkdir -p data/tmp
echo "✓ 目录创建完成"

# 运行测试
echo "5. 运行功能测试..."
cd examples
if ./BellhopPropagationModel input.json test_deploy.json; then
    if [ -f "test_deploy.json" ]; then
        echo "✓ 功能测试通过"
        rm -f test_deploy.json
    else
        echo "✗ 测试失败：未生成输出文件"
        exit 1
    fi
else
    echo "✗ 程序执行失败"
    exit 1
fi

cd "$PROJECT_ROOT"

echo ""
echo "================================"
echo "✓ 部署完成！"
echo ""
echo "使用方法："
echo "  cd examples"
echo "  ./BellhopPropagationModel input.json output.json"
echo "================================"
