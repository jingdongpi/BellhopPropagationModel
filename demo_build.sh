#!/bin/bash

# BellhopPropagationModel 构建演示脚本
# 演示如何使用新的本地Docker多平台构建系统

set -e

echo "🚀 BellhopPropagationModel 本地构建演示"
echo "========================================"

echo ""
echo "📋 支持的构建平台:"
echo "  - centos7-x86_64    (兼容 GLIBC 2.17+)"
echo "  - debian11-x86_64   (兼容 GLIBC 2.31+)"
echo "  - debian11-arm64    (兼容 ARM64 Linux)"
echo "  - centos8-arm64     (兼容 ARM64 CentOS)"
echo "  - win11-x86_64      (Windows 10+ 64位)"

echo ""
echo "🔍 1. 验证构建环境..."
if ./verify_build_env.sh; then
    echo "✅ 环境验证通过！"
else
    echo "❌ 环境验证失败，请根据提示修复后重试"
    exit 1
fi

echo ""
echo "🏗️ 2. 构建演示选项:"
echo "  a) 快速演示 - 构建 CentOS 7 x86_64 (兼容性最好)"
echo "  b) 完整演示 - 构建所有平台"
echo "  c) 自定义演示 - 选择特定平台"
echo ""

read -p "请选择演示类型 (a/b/c): " choice

case $choice in
    a|A)
        echo ""
        echo "🚀 快速演示: 构建 CentOS 7 x86_64..."
        ./build_local.sh -p centos7-x86_64 -v 3.8 -o ./demo-dist
        ;;
    b|B)
        echo ""
        echo "🚀 完整演示: 构建所有平台..."
        echo "⚠️  注意: 这将需要较长时间 (30分钟+)"
        read -p "确认继续? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./build_local.sh -p all -v 3.8 -o ./demo-dist -c
        else
            echo "演示取消"
            exit 0
        fi
        ;;
    c|C)
        echo ""
        echo "🚀 自定义演示: 选择构建平台..."
        echo "  1) centos7-x86_64"
        echo "  2) debian11-x86_64"
        echo "  3) debian11-arm64"
        echo "  4) centos8-arm64"
        echo ""
        read -p "请选择平台 (1-4): " platform_choice
        
        case $platform_choice in
            1) platform="centos7-x86_64" ;;
            2) platform="debian11-x86_64" ;;
            3) platform="debian11-arm64" ;;
            4) platform="centos8-arm64" ;;
            *) echo "无效选择"; exit 1 ;;
        esac
        
        echo ""
        echo "选择 Python 版本:"
        echo "  1) Python 3.8 (推荐)"
        echo "  2) Python 3.9"
        echo "  3) Python 3.10"
        echo "  4) Python 3.11"
        echo ""
        read -p "请选择版本 (1-4): " python_choice
        
        case $python_choice in
            1) python_ver="3.8" ;;
            2) python_ver="3.9" ;;
            3) python_ver="3.10" ;;
            4) python_ver="3.11" ;;
            *) echo "无效选择"; exit 1 ;;
        esac
        
        echo ""
        echo "🚀 构建 $platform (Python $python_ver)..."
        ./build_local.sh -p "$platform" -v "$python_ver" -o ./demo-dist
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "🎉 构建演示完成！"
echo ""
echo "📁 构建产物位置: ./demo-dist/"
echo ""

if [ -d "./demo-dist" ]; then
    echo "📊 构建产物统计:"
    find ./demo-dist -mindepth 1 -maxdepth 1 -type d | while read platform_dir; do
        platform_name=$(basename "$platform_dir")
        echo "  📦 $platform_name:"
        
        if [ -d "$platform_dir/bin" ]; then
            bin_count=$(find "$platform_dir/bin" -type f | wc -l)
            echo "    - bin/: $bin_count 个文件"
        fi
        
        if [ -d "$platform_dir/lib" ]; then
            lib_count=$(find "$platform_dir/lib" -type f | wc -l)
            echo "    - lib/: $lib_count 个文件"
        fi
        
        if [ -d "$platform_dir/include" ]; then
            include_count=$(find "$platform_dir/include" -type f | wc -l)
            echo "    - include/: $include_count 个文件"
        fi
        
        if [ -f "$platform_dir/build-info.txt" ]; then
            echo "    - 构建信息: ✅"
        fi
    done
    
    echo ""
    echo "🔍 查看构建信息:"
    echo "  cat ./demo-dist/*/build-info.txt"
    echo ""
    echo "📋 使用说明:"
    echo "  1. 选择适合目标系统的平台版本"
    echo "  2. 复制 bin/、lib/、include/ 到目标系统"
    echo "  3. 确保目标系统满足 GLIBC 版本要求"
    echo ""
    echo "📚 详细文档: LOCAL_BUILD_GUIDE.md"
fi

echo ""
echo "✨ 感谢使用 BellhopPropagationModel 本地构建系统！"
