#!/bin/bash

# BellhopPropagationModel 项目管理脚本
# 统一管理构建、测试、部署等操作

set -e  # 遇到错误时退出

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

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
BellhopPropagationModel 项目管理脚本

用法: $0 [选项]

选项:
    help          显示此帮助信息
    build         构建项目（清理并重新编译）
    quick-build   快速构建（增量编译）
    clean         清理构建文件
    install       安装项目到系统
    test          运行测试
    run           运行示例
    nuitka        编译 Nuitka 模块
    setup         初始化项目环境
    status        显示项目状态
    delivery      创建交付包
    
示例:
    $0 build        # 完整构建项目
    $0 run          # 运行示例
    $0 test         # 运行测试
    $0 delivery     # 创建交付包
    $0 status       # 检查项目状态

EOF
}

# 检查项目状态
check_status() {
    log_info "检查项目状态..."
    
    echo "项目根目录: $PROJECT_ROOT"
    echo
    
    # 检查关键文件
    echo "关键文件状态:"
    local files=(
        "CMakeLists.txt"
        "bin/BellhopPropagationModel"
        "lib/libBellhopPropagationModel.so"
        "python_wrapper/bellhop_wrapper.py"
        "input.json"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file (缺失)"
        fi
    done
    
    echo
    
    # 检查 Python 环境
    echo "Python 环境:"
    if command -v python3 &> /dev/null; then
        echo "  Python 版本: $(python3 --version)"
        echo "  Python 路径: $(which python3)"
    else
        echo "  ❌ Python3 未找到"
    fi
    
    echo
    
    # 检查编译的模块
    echo "Nuitka 编译模块:"
    local nuitka_modules=($(find lib/ -name "*.cpython-*.so" 2>/dev/null))
    if [ ${#nuitka_modules[@]} -gt 0 ]; then
        for module in "${nuitka_modules[@]}"; do
            echo "  ✅ $(basename "$module")"
        done
    else
        echo "  ⚠️  未找到 Nuitka 编译模块"
    fi
}

# 清理构建文件
clean_build() {
    log_info "清理构建文件..."
    
    rm -rf build/
    rm -f bin/BellhopPropagationModel
    rm -f lib/libBellhopPropagationModel.so
    
    log_success "清理完成"
}

# 编译 Nuitka 模块
build_nuitka() {
    log_info "编译 Nuitka 模块..."
    
    if [ -f "scripts/01_compile_nuitka.py" ]; then
        python3 scripts/01_compile_nuitka.py
    elif [ -f "scripts/setup_nuitka_simple.py" ]; then
        python3 scripts/setup_nuitka_simple.py
    else
        log_warning "未找到 Nuitka 编译脚本"
        return 1
    fi
    
    log_success "Nuitka 模块编译完成"
}

# 构建项目
build_project() {
    local clean_build_flag=$1
    
    if [ "$clean_build_flag" = "clean" ]; then
        log_info "执行完整构建（清理后重建）..."
        clean_build
    else
        log_info "执行快速构建..."
    fi
    
    # 创建构建目录
    mkdir -p build
    cd build
    
    # 配置 CMake
    log_info "配置 CMake..."
    cmake .. \
        -DBUILD_EXECUTABLE=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DUSE_NUITKA=ON \
        -DCMAKE_BUILD_TYPE=Release
    
    # 编译
    log_info "编译项目..."
    make -j$(nproc)
    
    cd ..
    
    # 检查构建结果
    if [ -f "bin/BellhopPropagationModel" ] && [ -f "lib/libBellhopPropagationModel.so" ]; then
        log_success "项目构建成功"
        echo "  可执行文件: bin/BellhopPropagationModel"
        echo "  动态库: lib/libBellhopPropagationModel.so"
    else
        log_error "构建失败"
        return 1
    fi
}

# 安装项目
install_project() {
    log_info "安装项目..."
    
    if [ ! -d "build" ]; then
        log_error "请先构建项目"
        return 1
    fi
    
    cd build
    sudo make install
    cd ..
    
    log_success "项目安装完成"
}

# 运行测试
run_tests() {
    log_info "运行项目测试..."
    
    # 检查必要文件
    if [ ! -f "bin/BellhopPropagationModel" ]; then
        log_error "可执行文件不存在，请先构建项目"
        return 1
    fi
    
    if [ ! -f "input.json" ]; then
        log_error "测试输入文件 input.json 不存在"
        return 1
    fi
    
    # 运行测试
    log_info "使用 input.json 运行测试..."
    ./bin/BellhopPropagationModel input.json output.json
    
    if [ -f "output.json" ]; then
        log_success "测试运行成功，结果保存在 output.json"
        echo "输出文件大小: $(ls -lh output.json | awk '{print $5}')"
    else
        log_error "测试失败，未生成输出文件"
        return 1
    fi
}

# 运行示例
run_example() {
    log_info "运行示例..."
    
    # 检查示例目录
    if [ -d "examples" ]; then
        local example_script="examples/run_example.sh"
        if [ -f "$example_script" ]; then
            bash "$example_script"
        else
            log_warning "未找到示例脚本，使用默认测试"
            run_tests
        fi
    else
        log_warning "未找到示例目录，使用默认测试"
        run_tests
    fi
}

# 初始化项目环境
setup_environment() {
    log_info "初始化项目环境..."
    
    # 检查 Python 依赖
    log_info "检查 Python 环境..."
    python3 -c "import sys; print(f'Python {sys.version}')"
    
    # 检查必要的 Python 包
    local required_packages=("numpy" "json")
    for package in "${required_packages[@]}"; do
        if python3 -c "import $package" 2>/dev/null; then
            echo "  ✅ $package"
        else
            echo "  ❌ $package (需要安装)"
        fi
    done
    
    # 编译 Nuitka 模块
    if [ ! -f "lib/bellhop.cpython-39-x86_64-linux-gnu.so" ]; then
        log_info "编译 Nuitka 模块..."
        build_nuitka
    fi
    
    log_success "环境初始化完成"
}

# 创建交付包
create_delivery_package() {
    log_info "创建项目交付包..."
    
    # 检查交付脚本是否存在
    if [ ! -f "scripts/delivery.sh" ]; then
        log_error "交付脚本不存在: scripts/delivery.sh"
        exit 1
    fi
    
    # 执行交付脚本
    bash scripts/delivery.sh
}

# 主函数
main() {
    case "${1:-help}" in
        "help"|"-h"|"--help")
            show_help
            ;;
        "status")
            check_status
            ;;
        "build")
            setup_environment
            build_nuitka
            build_project clean
            ;;
        "quick-build")
            build_project
            ;;
        "clean")
            clean_build
            ;;
        "install")
            install_project
            ;;
        "test")
            run_tests
            ;;
        "run")
            run_example
            ;;
        "nuitka")
            build_nuitka
            ;;
        "setup")
            setup_environment
            ;;
        "delivery")
            create_delivery_package
            ;;
        *)
            log_error "未知选项: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
