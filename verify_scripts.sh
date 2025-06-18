#!/bin/bash
# 验证所有构建脚本的语法和逻辑

set -e

echo "🔍 验证构建脚本语法和逻辑"

echo "=== 检查统一构建脚本 ==="
bash -n scripts/build_complete_dual_artifacts.sh
echo "✅ build_complete_dual_artifacts.sh 语法检查通过"

echo "=== 检查 CentOS 8 ARM64 构建脚本 ==="
bash -n scripts/build_centos8-arm64.sh
echo "✅ build_centos8-arm64.sh 语法检查通过"

echo "=== 检查 Debian 11 ARM64 构建脚本 ==="
bash -n scripts/build_debian11-arm64.sh
echo "✅ build_debian11-arm64.sh 语法检查通过"

echo "=== 检查 Windows x64 构建脚本 ==="
bash -n scripts/build_windows-x64.sh
echo "✅ build_windows-x64.sh 语法检查通过"

echo "=== 检查文件权限 ==="
for script in scripts/build_*.sh scripts/build_complete_dual_artifacts.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script 具有执行权限"
    else
        echo "❌ $script 缺少执行权限，正在修复..."
        chmod +x "$script"
        echo "✅ $script 权限已修复"
    fi
done

echo "=== 检查必要目录结构 ==="
required_dirs=(
    "python_core"
    "wrapper" 
    "scripts"
    "examples"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ 目录存在: $dir"
    else
        echo "❌ 目录缺失: $dir"
    fi
done

echo "=== 检查核心文件 ==="
required_files=(
    "python_core/BellhopPropagationModel.py"
    "wrapper/BellhopPropagationModelInterface.h"
    "wrapper/BellhopPropagationModelInterface.cpp"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ 文件存在: $file"
    else
        echo "❌ 文件缺失: $file"
    fi
done

echo "🎯 脚本验证完成！"
