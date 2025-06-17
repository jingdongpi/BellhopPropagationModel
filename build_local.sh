#!/bin/bash

# BellhopPropagationModel 本地 Docker 多平台构建脚本
# 支持 CentOS 7 x86_64、Debian 11 x86_64、Debian 11 ARM64、CentOS 8 ARM64

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
BellhopPropagationModel 本地 Docker 多平台构建脚本

用法: $0 [选项]

选项:
  -p, --platform <platform>     指定构建平台，支持：
                                 - centos7-x86_64 (CentOS 7 x86_64)
                                 - debian11-x86_64 (Debian 11 x86_64)
                                 - debian11-arm64 (Debian 11 ARM64)
                                 - centos8-arm64 (CentOS 8 ARM64)
                                 - all (所有平台)
  -v, --python-version <version> Python 版本 (3.8, 3.9, 3.10, 3.11)，默认 3.8
  -o, --output <dir>             输出目录，默认 ./dist
  -c, --clean                    清理旧的构建产物
  -h, --help                     显示此帮助信息

平台说明:
  - centos7-x86_64:   兼容 GLIBC 2.17+ 的 x86_64 Linux 系统
  - debian11-x86_64:  兼容 GLIBC 2.31+ 的 x86_64 Linux 系统
  - debian11-arm64:   兼容 GLIBC 2.31+ 的 ARM64 Linux 系统
  - centos8-arm64:    兼容 GLIBC 2.28+ 的 ARM64 Linux 系统

示例:
  $0 -p centos7-x86_64 -v 3.9            # 构建 CentOS 7 x86_64 版本，Python 3.9
  $0 -p all -v 3.8 -o ./release          # 构建所有平台，Python 3.8，输出到 ./release
  $0 -p debian11-arm64 -c                # 构建 Debian 11 ARM64，清理旧产物

EOF
}

# 默认参数
PLATFORM="all"
PYTHON_VERSION="3.8"
OUTPUT_DIR="./dist"
CLEAN_BUILD=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -v|--python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证平台参数
case $PLATFORM in
    centos7-x86_64|debian11-x86_64|debian11-arm64|centos8-arm64|all)
        ;;
    *)
        log_error "不支持的平台: $PLATFORM"
        log_info "支持的平台: centos7-x86_64, debian11-x86_64, debian11-arm64, centos8-arm64, all"
        exit 1
        ;;
esac

# 验证 Python 版本
case $PYTHON_VERSION in
    3.8|3.9|3.10|3.11)
        ;;
    *)
        log_error "不支持的 Python 版本: $PYTHON_VERSION"
        log_info "支持的版本: 3.8, 3.9, 3.10, 3.11"
        exit 1
        ;;
esac

# 检查 Docker 环境
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装或不在 PATH 中"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker 服务未运行或权限不足"
    exit 1
fi

# 检查 Docker Buildx
if ! docker buildx version &> /dev/null; then
    log_warning "Docker Buildx 未启用，尝试启用..."
    docker buildx create --use --name multi-platform-builder || true
fi

# 清理函数
cleanup_build() {
    log_info "清理旧的构建产物..."
    rm -rf "$OUTPUT_DIR"
    docker image prune -f
    log_success "清理完成"
}

# 构建单个平台
build_platform() {
    local platform=$1
    local dockerfile=""
    local arch=""
    local build_args="--build-arg PYTHON_VERSION=$PYTHON_VERSION"
    
    case $platform in
        centos7-x86_64)
            dockerfile="docker-local/Dockerfile.centos7"
            arch="linux/amd64"
            ;;
        debian11-x86_64)
            dockerfile="docker-local/Dockerfile.debian11"
            arch="linux/amd64"
            ;;
        debian11-arm64)
            dockerfile="docker-local/Dockerfile.debian11-arm64"
            arch="linux/arm64"
            ;;
        centos8-arm64)
            dockerfile="docker-local/Dockerfile.centos8-arm64"
            arch="linux/arm64"
            ;;
        *)
            log_error "不支持的平台: $platform"
            return 1
            ;;
    esac
    
    log_info "开始构建平台: $platform (架构: $arch, Python: $PYTHON_VERSION)"
    
    # 检查 Dockerfile 是否存在
    if [ ! -f "$dockerfile" ]; then
        log_error "Dockerfile 不存在: $dockerfile"
        return 1
    fi
    
    # 构建 Docker 镜像
    local image_name="bellhop-builder:$platform-py$PYTHON_VERSION"
    log_info "构建 Docker 镜像: $image_name"
    
    if ! docker buildx build \
        --platform "$arch" \
        -f "$dockerfile" \
        $build_args \
        -t "$image_name" \
        . ; then
        log_error "Docker 镜像构建失败: $platform"
        return 1
    fi
    
    # 创建输出目录
    local platform_output="$OUTPUT_DIR/$platform-python$PYTHON_VERSION"
    mkdir -p "$platform_output"
    
    # 运行容器进行构建
    log_info "在容器中执行构建..."
    
    # 创建临时容器进行构建
    local container_name="bellhop-build-$platform-$(date +%s)"
    
    if ! docker run --name "$container_name" --platform "$arch" \
        "$image_name" ; then
        log_error "容器构建失败: $platform"
        docker rm -f "$container_name" 2>/dev/null || true
        return 1
    fi
    
    # 复制构建产物
    log_info "复制构建产物到: $platform_output"
    
    # 复制 bin 目录
    if docker cp "$container_name:/workspace/bin" "$platform_output/" 2>/dev/null; then
        log_success "复制 bin/ 目录成功"
    else
        log_warning "bin/ 目录复制失败或不存在"
    fi
    
    # 复制 lib 目录
    if docker cp "$container_name:/workspace/lib" "$platform_output/" 2>/dev/null; then
        log_success "复制 lib/ 目录成功"
    else
        log_warning "lib/ 目录复制失败或不存在"
    fi
    
    # 复制 include 目录
    if docker cp "$container_name:/workspace/include" "$platform_output/" 2>/dev/null; then
        log_success "复制 include/ 目录成功"
    else
        log_warning "include/ 目录复制失败或不存在"
    fi
    
    # 创建构建信息文件
    cat > "$platform_output/build-info.txt" << EOF
==========================================
BellhopPropagationModel 构建信息
==========================================
平台: $platform
架构: $arch
Python版本: $PYTHON_VERSION
构建时间: $(date)
主机系统: $(uname -a)

兼容性说明:
EOF
    
    case $platform in
        centos7-x86_64)
            echo "- 支持 GLIBC 2.17+ 的 x86_64 Linux 系统" >> "$platform_output/build-info.txt"
            ;;
        debian11-x86_64)
            echo "- 支持 GLIBC 2.31+ 的 x86_64 Linux 系统" >> "$platform_output/build-info.txt"
            ;;
        debian11-arm64)
            echo "- 支持 GLIBC 2.31+ 的 ARM64 Linux 系统" >> "$platform_output/build-info.txt"
            ;;
        centos8-arm64)
            echo "- 支持 GLIBC 2.28+ 的 ARM64 Linux 系统" >> "$platform_output/build-info.txt"
            ;;
    esac
    
    echo "" >> "$platform_output/build-info.txt"
    echo "静态链接: libgcc, libstdc++" >> "$platform_output/build-info.txt"
    echo "Python 模块: Nuitka 编译" >> "$platform_output/build-info.txt"
    
    # 清理临时容器
    docker rm -f "$container_name" >/dev/null 2>&1 || true
    
    # 显示构建产物信息
    log_info "构建产物统计:"
    if [ -d "$platform_output/bin" ]; then
        echo "  bin/: $(find "$platform_output/bin" -type f | wc -l) 个文件"
    fi
    if [ -d "$platform_output/lib" ]; then
        echo "  lib/: $(find "$platform_output/lib" -type f | wc -l) 个文件"
    fi
    if [ -d "$platform_output/include" ]; then
        echo "  include/: $(find "$platform_output/include" -type f | wc -l) 个文件"
    fi
    
    log_success "平台 $platform 构建完成"
    return 0
}

# 主构建流程
main() {
    log_info "=== BellhopPropagationModel 本地 Docker 多平台构建 ==="
    log_info "平台: $PLATFORM"
    log_info "Python 版本: $PYTHON_VERSION"
    log_info "输出目录: $OUTPUT_DIR"
    
    # 清理旧产物
    if [ "$CLEAN_BUILD" = true ]; then
        cleanup_build
    fi
    
    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"
    
    # 构建时间记录
    local start_time=$(date +%s)
    local success_count=0
    local total_count=0
    
    if [ "$PLATFORM" = "all" ]; then
        # 构建所有平台
        local platforms=("centos7-x86_64" "debian11-x86_64" "debian11-arm64" "centos8-arm64")
        
        for platform in "${platforms[@]}"; do
            total_count=$((total_count + 1))
            log_info "开始构建平台 $total_count/${#platforms[@]}: $platform"
            
            if build_platform "$platform"; then
                success_count=$((success_count + 1))
            else
                log_error "平台 $platform 构建失败"
            fi
            
            echo ""
        done
    else
        # 构建单个平台
        total_count=1
        if build_platform "$PLATFORM"; then
            success_count=1
        fi
    fi
    
    # 构建完成统计
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    log_info "=== 构建完成统计 ==="
    log_info "总耗时: ${duration}s"
    log_info "成功: $success_count/$total_count"
    
    if [ $success_count -eq $total_count ]; then
        log_success "所有平台构建成功！"
        log_info "构建产物位置: $OUTPUT_DIR"
        
        # 生成总体构建报告
        cat > "$OUTPUT_DIR/build-summary.txt" << EOF
==========================================
BellhopPropagationModel 构建汇总
==========================================
构建时间: $(date)
Python版本: $PYTHON_VERSION
总耗时: ${duration}s
成功平台: $success_count/$total_count

构建产物目录:
$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

使用说明:
1. 选择对应平台的构建产物
2. 将 bin/、lib/、include/ 目录复制到目标系统
3. 确保目标系统满足 GLIBC 版本要求（见各平台的 build-info.txt）
4. Python 模块已通过 Nuitka 编译为二进制文件，无需额外依赖

技术支持:
- 查看各平台的 build-info.txt 了解兼容性信息
- 确保运行环境满足 GLIBC 版本要求
- ARM64 版本需要在 ARM64 架构的系统上运行
EOF
        
        exit 0
    else
        log_error "部分平台构建失败"
        exit 1
    fi
}

# 执行主函数
main
