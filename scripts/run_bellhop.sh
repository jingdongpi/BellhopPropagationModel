#!/bin/bash

# Bellhop传播模型启动脚本
# 简单的包装器，直接运行二进制程序（程序内置智能Python检测）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BINARY_PATH="$PROJECT_ROOT/bin/BellhopPropagationModel"

# 检查二进制文件是否存在
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ 未找到可执行文件: $BINARY_PATH"
    echo "请先编译项目: mkdir build && cd build && cmake .. && make"
    exit 1
fi

# 帮助信息
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Bellhop传播模型"
    echo ""
    echo "用法:"
    echo "  $0 [输入文件] [输出文件]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                              # 使用默认文件 input.json -> output.json"
    echo "  $0 task.json result.json        # 指定输入和输出文件"
    echo ""
    echo "注意: 程序内置智能Python环境检测，会自动处理库链接问题"
    exit 0
fi

# 直接运行程序（程序内置智能检测）
echo "=== Bellhop传播模型 ==="
echo "启动程序: $BINARY_PATH"
if [ $# -gt 0 ]; then
    echo "参数: $@"
fi
echo ""

exec "$BINARY_PATH" "$@"
