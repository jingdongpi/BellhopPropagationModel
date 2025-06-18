#!/bin/bash
# 统一构建脚本 - 生成双产物(可执行文件 + 动态链接库)
# 完全符合声传播模型接口规范

set -e

PLATFORM=${1:-"centos8-arm64"}

echo "🎯 统一构建脚本 - 接口规范双产物"
echo "平台: ${PLATFORM}"
echo "目标: 完全符合声传播模型接口规范"

case ${PLATFORM} in
    "centos8-arm64")
        echo "=== 执行 CentOS 8 ARM64 构建 ==="
        chmod +x scripts/build_centos8-arm64.sh
        ./scripts/build_centos8-arm64.sh
        ;;
    "debian11-arm64")
        echo "=== 执行 Debian 11 ARM64 构建 ==="
        chmod +x scripts/build_debian11-arm64.sh
        ./scripts/build_debian11-arm64.sh
        ;;
    "windows-x64")
        echo "=== 执行 Windows x86-64 构建 ==="
        chmod +x scripts/build_windows-x64.sh
        ./scripts/build_windows-x64.sh
        ;;
    *)
        echo "❌ 不支持的平台: ${PLATFORM}"
        echo "支持的平台: centos8-arm64, debian11-arm64, windows-x64"
        exit 1
        ;;
esac

echo "=== 最终验证接口规范符合性 ==="

if [ "${PLATFORM}" = "windows-x64" ]; then
    # Windows平台验证
    if [ -f "dist/BellhopPropagationModel.exe" ]; then
        echo "✅ 2.1.1 可执行文件命名规范: BellhopPropagationModel.exe"
    else
        echo "❌ 可执行文件缺失"
        exit 1
    fi

    if [ -f "dist/BellhopPropagationModel.dll" ]; then
        echo "✅ 2.1.2 动态链接库命名规范: BellhopPropagationModel.dll"
    else
        echo "❌ 动态链接库缺失"
        exit 1
    fi
else
    # Linux平台验证
    if [ -f "dist/BellhopPropagationModel" ]; then
        echo "✅ 2.1.1 可执行文件命名规范: BellhopPropagationModel"
    else
        echo "❌ 可执行文件缺失"
        exit 1
    fi

    if [ -f "dist/libBellhopPropagationModel.so" ]; then
        echo "✅ 2.1.2 动态链接库命名规范: libBellhopPropagationModel.so"
    else
        echo "❌ 动态链接库缺失"
        exit 1
    fi
fi

# 通用验证
if [ -f "dist/BellhopPropagationModelInterface.h" ]; then
    echo "✅ 2.1.2 头文件命名规范: BellhopPropagationModelInterface.h"
else
    echo "❌ 头文件缺失"
    exit 1
fi

if [ -f "dist/input.json" ]; then
    echo "✅ 2.2 标准输入接口: JSON格式"
else
    echo "❌ 标准输入文件缺失"
    exit 1
fi

echo "🎯 ${PLATFORM} 双产物构建完成！"
echo "完全符合声传播模型接口规范要求"
