#!/bin/bash

# Bellhop传播模型清理脚本
# 用途：清理编译产物和临时文件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== 清理项目 ==="

cd "$PROJECT_ROOT"

echo "清理编译产物..."
rm -rf build/
rm -rf build_cython/
rm -rf compiled_modules/
rm -f *.so
rm -f examples/output*.json
rm -f examples/test_output.json

echo "清理交付包..."
rm -rf BellhopPropagationModel_Delivery/
rm -rf BellhopPropagationModel_Release/
rm -rf BellhopPropagationModel_Standalone/

echo "清理临时文件..."
rm -rf data/tmp/
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true

echo "✓ 清理完成"
