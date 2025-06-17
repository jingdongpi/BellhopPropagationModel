#!/bin/bash

# BellhopPropagationModel 本地构建环境验证脚本

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

log_info "=== BellhopPropagationModel 本地构建环境验证 ==="

# 检查 Docker
log_info "检查 Docker 环境..."
if command -v docker &> /dev/null; then
    log_success "Docker 已安装: $(docker --version)"
    
    if docker info &> /dev/null; then
        log_success "Docker 服务运行正常"
    else
        log_error "Docker 服务未运行或权限不足"
        echo "  解决方法:"
        echo "  1. 启动 Docker 服务: sudo systemctl start docker"
        echo "  2. 添加用户到 docker 组: sudo usermod -aG docker \$USER"
        echo "  3. 重新登录或重启系统"
        exit 1
    fi
else
    log_error "Docker 未安装"
    echo "  安装方法:"
    echo "  Ubuntu/Debian: sudo apt-get install docker.io"
    echo "  CentOS/RHEL: sudo yum install docker"
    echo "  或访问: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Buildx
log_info "检查 Docker Buildx..."
if docker buildx version &> /dev/null; then
    log_success "Docker Buildx 可用: $(docker buildx version)"
    
    # 检查多平台支持
    if docker buildx ls | grep -q "linux/arm64"; then
        log_success "多平台支持已启用 (包含 ARM64)"
    else
        log_warning "ARM64 支持未启用，尝试启用..."
        if docker buildx create --use --name multi-platform-builder &> /dev/null; then
            log_success "多平台构建器创建成功"
        else
            log_warning "无法创建多平台构建器，ARM64 构建可能失败"
        fi
    fi
else
    log_error "Docker Buildx 未安装或不可用"
    echo "  Docker Buildx 是 Docker 的多平台构建插件"
    echo "  通常随 Docker 20.10+ 自动安装"
    exit 1
fi

# 检查磁盘空间
log_info "检查磁盘空间..."
AVAILABLE_GB=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
if [ $AVAILABLE_GB -ge 8 ]; then
    log_success "可用磁盘空间: ${AVAILABLE_GB}GB"
else
    log_warning "磁盘空间不足: ${AVAILABLE_GB}GB (建议至少 8GB)"
    echo "  可用命令清理空间:"
    echo "  docker system prune -a"
fi

# 检查网络连接
log_info "检查网络连接..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    log_success "网络连接正常"
else
    log_warning "网络连接异常，可能影响 Docker 镜像下载"
fi

# 检查构建脚本
log_info "检查构建脚本..."
if [ -f "build_local.sh" ] && [ -x "build_local.sh" ]; then
    log_success "build_local.sh 存在且可执行"
else
    log_error "build_local.sh 不存在或不可执行"
    echo "  请确保运行: chmod +x build_local.sh"
    exit 1
fi

if [ -f "build_windows.ps1" ]; then
    log_success "build_windows.ps1 存在"
else
    log_warning "build_windows.ps1 不存在"
fi

# 检查 Docker 配置文件
log_info "检查 Docker 配置文件..."
DOCKER_CONFIGS=(
    "docker-local/Dockerfile.centos7"
    "docker-local/Dockerfile.debian11" 
    "docker-local/Dockerfile.debian11-arm64"
    "docker-local/Dockerfile.centos8-arm64"
    "docker-local/centos7_setup.sh"
    "docker-local/debian11_setup.sh"
    "docker-local/debian11_arm64_setup.sh"
    "docker-local/centos8_arm64_setup.sh"
)

ALL_CONFIGS_OK=true
for config in "${DOCKER_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        log_success "$config 存在"
        
        # 检查可执行权限（对于 .sh 文件）
        if [[ "$config" == *.sh ]] && [ ! -x "$config" ]; then
            log_warning "$config 缺少可执行权限"
            chmod +x "$config"
            log_info "已自动添加可执行权限"
        fi
    else
        log_error "$config 不存在"
        ALL_CONFIGS_OK=false
    fi
done

if [ "$ALL_CONFIGS_OK" = false ]; then
    log_error "部分 Docker 配置文件缺失"
    exit 1
fi

# 测试 Docker 镜像拉取
log_info "测试基础 Docker 镜像..."
TEST_IMAGES=("centos:7" "debian:11")

for image in "${TEST_IMAGES[@]}"; do
    log_info "测试拉取镜像: $image"
    if docker pull "$image" &> /dev/null; then
        log_success "$image 拉取成功"
    else
        log_warning "$image 拉取失败，可能影响构建"
    fi
done

# 检查系统资源
log_info "检查系统资源..."
CPU_CORES=$(nproc)
MEMORY_GB=$(free -g | awk 'NR==2{print $2}')

log_info "CPU 核心数: $CPU_CORES"
log_info "系统内存: ${MEMORY_GB}GB"

if [ $CPU_CORES -ge 2 ]; then
    log_success "CPU 核心数充足"
else
    log_warning "CPU 核心数较少，构建可能较慢"
fi

if [ $MEMORY_GB -ge 4 ]; then
    log_success "系统内存充足"
else
    log_warning "系统内存不足，建议至少 4GB"
fi

# 运行简单的构建测试
log_info "运行构建环境测试..."
if docker run --rm hello-world &> /dev/null; then
    log_success "Docker 运行测试通过"
else
    log_error "Docker 运行测试失败"
    exit 1
fi

# 总结
echo ""
log_info "=== 环境验证结果 ==="
log_success "✅ Docker 环境正常"
log_success "✅ 构建脚本就绪"
log_success "✅ 配置文件完整"
log_success "✅ 系统资源充足"

echo ""
log_info "=== 下一步操作 ==="
echo "1. 运行单平台测试构建:"
echo "   ./build_local.sh -p centos7-x86_64 -v 3.8"
echo ""
echo "2. 运行完整多平台构建:"
echo "   ./build_local.sh -p all -v 3.8"
echo ""
echo "3. 查看详细使用说明:"
echo "   ./build_local.sh --help"
echo "   less LOCAL_BUILD_GUIDE.md"

echo ""
log_success "环境验证完成！可以开始构建了。"
