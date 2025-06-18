#!/bin/bash
# build_complete_dual_artifacts.sh - 完整的双产物构建脚本
# 支持多平台：debian11-arm64, centos8-arm64

set -e

PLATFORM=${1:-"debian11-arm64"}
PROJECT_ROOT=$(pwd)

echo "================================================"
echo "完整双产物构建 - 平台: $PLATFORM"
echo "Python源码 -> 二进制文件 + C++动态库"
echo "================================================"

case "$PLATFORM" in
    "debian11-arm64")
        echo "使用 Debian 11 ARM64 构建配置"
        echo "目标: gcc 9.3.0、glibc 2.31、linux 5.4.18"
        if [ -f "scripts/build_debian11-arm64.sh" ]; then
            bash scripts/build_debian11-arm64.sh
        else
            echo "❌ 找不到 Debian 11 构建脚本"
            exit 1
        fi
        ;;
    "centos8-arm64")
        echo "使用 CentOS 8 ARM64 构建配置"
        echo "目标: gcc 7.3.0、glibc 2.28、linux 4.19.90"
        if [ -f "scripts/build_centos8-arm64.sh" ]; then
            bash scripts/build_centos8-arm64.sh
        else
            echo "❌ 找不到 CentOS 8 构建脚本"
            exit 1
        fi
        ;;
    *)
        echo "❌ 不支持的平台: $PLATFORM"
        echo "支持的平台:"
        echo "  - debian11-arm64"
        echo "  - centos8-arm64"
        echo ""
        echo "使用方法:"
        echo "  $0 debian11-arm64"
        echo "  $0 centos8-arm64"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "✅ $PLATFORM 平台构建完成！"
echo "================================================"
echo ""
echo "产物位置: $PROJECT_ROOT/dist"
echo "- BellhopPropagationModel (独立二进制文件)"
echo "- libBellhopPropagationModel.so (自包含动态库)"
echo "- bellhop_wrapper.h (C++头文件)"
echo "- test_library.cpp (测试程序)"
echo "- compile_test.sh (编译测试脚本)"
echo "- README.md (使用说明)"

if [ -d "$PROJECT_ROOT/dist" ]; then
    echo ""
    echo "文件列表:"
    ls -la "$PROJECT_ROOT/dist"
fi

echo ""
echo "快速测试:"
echo "cd dist"
echo "./BellhopPropagationModel                      # 测试二进制文件"
echo "./compile_test.sh                              # 测试动态库"
