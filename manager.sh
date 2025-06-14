#!/bin/bash
# ============================================================================
# Bellhop传播模型项目脚本管理器 v3.0
# ============================================================================
# 功能：统一管理所有项目脚本，提供简化的构建、测试、清理接口
# 更新：移除复杂的编号脚本，专注核心功能
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

print_header() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}    Bellhop传播模型项目脚本管理器 v3.0${NC}"
    echo -e "${CYAN}================================================${NC}"
}

# 显示帮助信息
show_help() {
    print_header
    echo ""
    echo -e "${GREEN}核心功能：${NC}"
    echo -e "  ${BLUE}build${NC}     - 完整编译项目 (Nuitka + C++)"
    echo -e "  ${BLUE}nuitka${NC}    - 仅编译 Python 模块"
    echo -e "  ${BLUE}cpp${NC}       - 仅编译 C++ 程序"
    echo -e "  ${BLUE}test${NC}      - 运行基础测试"
    echo -e "  ${BLUE}clean${NC}     - 清理编译产物"
    echo ""
    echo -e "${GREEN}环境管理：${NC}"
    echo -e "  ${BLUE}setup${NC}     - 检查和配置环境"
    echo -e "  ${BLUE}deps${NC}      - 检查依赖"
    echo ""
    echo -e "${GREEN}使用示例：${NC}"
    echo -e "  ${YELLOW}./scripts_manager.sh build${NC}    # 完整编译"
    echo -e "  ${YELLOW}./scripts_manager.sh test${NC}     # 运行测试"
    echo -e "  ${YELLOW}./scripts_manager.sh clean${NC}    # 清理项目"
    echo ""
    echo -e "${CYAN}脚本位置: $SCRIPTS_DIR/${NC}"
}

# 检查脚本目录是否存在
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo -e "${RED}错误: 脚本目录不存在: $SCRIPTS_DIR${NC}"
    exit 1
fi

# 核心编译功能
build_project() {
    echo -e "${GREEN}=== 开始完整项目编译 ===${NC}"
    
    # 1. 检查依赖
    echo -e "${BLUE}[1/3] 检查依赖...${NC}"
    if [ -f "$SCRIPTS_DIR/02_check_deps.py" ]; then
        python3 "$SCRIPTS_DIR/02_check_deps.py"
    fi
    
    # 2. 编译 Python 模块
    echo -e "${BLUE}[2/3] 编译 Python 模块 (Nuitka)...${NC}"
    if [ -f "$SCRIPTS_DIR/01_compile_nuitka.py" ]; then
        python3 "$SCRIPTS_DIR/01_compile_nuitka.py"
    else
        echo -e "${RED}错误: 01_compile_nuitka.py 不存在${NC}"
        exit 1
    fi
    
    # 3. 编译 C++ 程序
    echo -e "${BLUE}[3/3] 编译 C++ 程序...${NC}"
    mkdir -p build
    cd build
    cmake .. -DUSE_NUITKA=ON -DBUILD_EXECUTABLE=ON -DBUILD_SHARED_LIBS=ON
    make -j$(nproc)
    cd ..
    
    echo -e "${GREEN}=== 编译完成! ===${NC}"
    echo -e "${GREEN}可执行文件: bin/BellhopPropagationModel${NC}"
    echo -e "${GREEN}动态库: lib/libBellhopPropagationModel.so${NC}"
}

# Nuitka 编译
build_nuitka() {
    echo -e "${GREEN}=== 编译 Python 模块 (Nuitka) ===${NC}"
    if [ -f "$SCRIPTS_DIR/01_compile_nuitka.py" ]; then
        python3 "$SCRIPTS_DIR/01_compile_nuitka.py"
    else
        echo -e "${RED}错误: 01_compile_nuitka.py 不存在${NC}"
        exit 1
    fi
}

# C++ 编译
build_cpp() {
    echo -e "${GREEN}=== 编译 C++ 程序 ===${NC}"
    mkdir -p build
    cd build
    cmake .. -DUSE_NUITKA=ON -DBUILD_EXECUTABLE=ON -DBUILD_SHARED_LIBS=ON
    make -j$(nproc)
    cd ..
    echo -e "${GREEN}C++ 编译完成!${NC}"
}

# 基础测试
run_test() {
    echo -e "${GREEN}=== 运行基础功能测试 ===${NC}"
    
    # 检查可执行文件
    if [ ! -f "bin/BellhopPropagationModel" ]; then
        echo -e "${RED}错误: 可执行文件不存在，请先编译项目${NC}"
        echo -e "${YELLOW}运行: ./scripts_manager.sh build${NC}"
        exit 1
    fi
    
    # 测试运行
    if [ -f "examples/input.json" ]; then
        echo -e "${BLUE}测试可执行文件...${NC}"
        cd examples
        
        # 添加错误处理和详细输出
        echo "正在运行: ../bin/BellhopPropagationModel input.json test_output.json"
        
        # 使用 timeout 防止程序无限挂起，并捕获退出状态
        timeout 30s ../bin/BellhopPropagationModel input.json test_output.json
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            if [ -f "test_output.json" ]; then
                echo -e "${GREEN}✓ 基础功能测试通过!${NC}"
                echo -e "${BLUE}输出文件: examples/test_output.json${NC}"
                # 显示文件大小而不是内容（避免打印大文件）
                file_size=$(du -h test_output.json 2>/dev/null | cut -f1)
                echo -e "${BLUE}文件大小: ${file_size}${NC}"
                # 检查文件是否为有效的JSON格式
                if command -v jq >/dev/null 2>&1; then
                    if jq empty test_output.json >/dev/null 2>&1; then
                        echo -e "${GREEN}✓ 输出文件为有效的JSON格式${NC}"
                        # 显示JSON的顶层键（不显示具体内容）
                        echo -e "${BLUE}JSON结构:${NC}"
                        jq -r 'keys[]' test_output.json 2>/dev/null | head -10 | sed 's/^/  - /'
                    else
                        echo -e "${YELLOW}⚠ 输出文件不是有效的JSON格式${NC}"
                    fi
                else
                    echo -e "${BLUE}提示: 安装 jq 可以验证JSON格式 (apt install jq)${NC}"
                fi
            else
                echo -e "${RED}✗ 程序运行成功但未生成输出文件!${NC}"
                exit 1
            fi
        elif [ $exit_code -eq 124 ]; then
            echo -e "${RED}✗ 程序运行超时（30秒）!${NC}"
            exit 1
        elif [ $exit_code -eq 139 ]; then
            echo -e "${RED}✗ 程序发生段错误（Segmentation fault）!${NC}"
            echo -e "${YELLOW}建议：重新编译项目或检查 Python 环境${NC}"
            exit 1
        else
            echo -e "${RED}✗ 程序运行失败，退出码: $exit_code${NC}"
            exit 1
        fi
        cd ..
    else
        echo -e "${YELLOW}警告: examples/input.json 不存在，跳过功能测试${NC}"
    fi
}

# 环境配置
setup_environment() {
    echo -e "${GREEN}=== 检查和配置开发环境 ===${NC}"
    if [ -f "$SCRIPTS_DIR/00_environment_setup.sh" ]; then
        echo -e "${BLUE}使用完整环境配置脚本...${NC}"
        "$SCRIPTS_DIR/00_environment_setup.sh" --check
    else
        echo -e "${BLUE}基础依赖检查...${NC}"
        python3 -c "import numpy, scipy, nuitka; print('✓ Python依赖正常')"
        cmake --version > /dev/null && echo -e "${GREEN}✓ CMake 可用${NC}"
        gcc --version > /dev/null && echo -e "${GREEN}✓ GCC 可用${NC}"
    fi
}

# 依赖检查
check_dependencies() {
    echo -e "${GREEN}=== 检查项目依赖 ===${NC}"
    if [ -f "$SCRIPTS_DIR/02_check_deps.py" ]; then
        python3 "$SCRIPTS_DIR/02_check_deps.py"
    else
        echo -e "${BLUE}基础依赖检查...${NC}"
        python3 -c "
import sys
try:
    import numpy
    print('✓ NumPy:', numpy.__version__)
except ImportError:
    print('✗ NumPy 未安装')
    sys.exit(1)

try:
    import scipy  
    print('✓ SciPy:', scipy.__version__)
except ImportError:
    print('✗ SciPy 未安装')
    sys.exit(1)

try:
    import nuitka
    print('✓ Nuitka 可用')
except ImportError:
    print('✗ Nuitka 未安装')
    sys.exit(1)
"
    fi
}

# 清理项目
clean_project() {
    echo -e "${GREEN}=== 清理编译产物 ===${NC}"
    
    # 使用现有清理脚本
    if [ -f "$SCRIPTS_DIR/04_cleanup.sh" ]; then
        "$SCRIPTS_DIR/04_cleanup.sh"
    else
        # 手动清理
        echo -e "${BLUE}手动清理编译产物...${NC}"
        rm -rf build/
        rm -rf lib/*.so lib/*.dll 
        rm -f bin/BellhopPropagationModel
        rm -f examples/test_output.json
        echo -e "${GREEN}✓ 清理完成${NC}"
    fi
}

# 解析命令
case "${1:-help}" in
    build)
        cd "$SCRIPT_DIR"
        build_project
        ;;
    nuitka)
        cd "$SCRIPT_DIR"
        build_nuitka
        ;;
    cpp)
        cd "$SCRIPT_DIR"
        build_cpp
        ;;
    clean)
        cd "$SCRIPT_DIR"
        clean_project
        ;;
    test)
        cd "$SCRIPT_DIR"
        run_test
        ;;
    setup)
        cd "$SCRIPT_DIR"
        setup_environment
        ;;
    deps)
        cd "$SCRIPT_DIR"
        check_dependencies
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}错误: 未知命令 '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
