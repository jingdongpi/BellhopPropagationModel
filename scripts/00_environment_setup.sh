#!/bin/bash

# ============================================================================
# 环境配置脚本 - Environment Setup
# ============================================================================
# 功能：自动配置开发环境、检查依赖、安装缺失组件
# 使用：./scripts/00_environment_setup.sh [--install|--check|--clean]
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="/home/shunli/AcousticProjects/BellhopPropagationModel"
cd "$PROJECT_ROOT"

# 解析命令行参数
ACTION="${1:-check}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 BellhopPropagationModel - 环境配置${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "配置时间: $(date)"
echo "操作模式: $ACTION"
echo

# 配置结果统计
TOTAL_COMPONENTS=0
CONFIGURED_COMPONENTS=0
MISSING_COMPONENTS=()

check_component() {
    local component_name="$1"
    local check_command="$2"
    local install_command="$3"
    
    TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
    
    echo "  🔍 检查 $component_name..."
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "    ${GREEN}✅ $component_name 已安装${NC}"
        CONFIGURED_COMPONENTS=$((CONFIGURED_COMPONENTS + 1))
        return 0
    else
        echo -e "    ${RED}❌ $component_name 缺失${NC}"
        MISSING_COMPONENTS+=("$component_name")
        
        if [ "$ACTION" = "--install" ] && [ -n "$install_command" ]; then
            echo "    🔄 正在安装 $component_name..."
            if eval "$install_command"; then
                echo -e "    ${GREEN}✅ $component_name 安装成功${NC}"
                CONFIGURED_COMPONENTS=$((CONFIGURED_COMPONENTS + 1))
                return 0
            else
                echo -e "    ${RED}❌ $component_name 安装失败${NC}"
                return 1
            fi
        fi
        return 1
    fi
}

# ============================================================================
# 1. 系统依赖检查
# ============================================================================
echo -e "${YELLOW}1. 🖥️ 系统依赖检查${NC}"

# Python 3 环境
check_component "Python 3" \
    "python3 --version" \
    "sudo apt-get update && sudo apt-get install -y python3 python3-pip"

# CMake
check_component "CMake" \
    "cmake --version" \
    "sudo apt-get install -y cmake"

# 编译工具
check_component "GCC编译器" \
    "gcc --version" \
    "sudo apt-get install -y build-essential"

check_component "Make" \
    "make --version" \
    ""

echo

# ============================================================================
# 2. Python依赖检查
# ============================================================================
echo -e "${YELLOW}2. 🐍 Python依赖检查${NC}"

# 必需的Python包
python_packages=(
    "numpy:numpy"
    "scipy:scipy"
    "matplotlib:matplotlib"
    "psutil:psutil"
)

for package_info in "${python_packages[@]}"; do
    package_import=${package_info%:*}
    package_name=${package_info#*:}
    
    check_component "Python $package_name" \
        "python3 -c 'import $package_import'" \
        "python3 -m pip install $package_name"
done

echo

# ============================================================================
# 3. Bellhop二进制检查
# ============================================================================
echo -e "${YELLOW}3. 🔊 Bellhop二进制检查${NC}"

BELLHOP_PATH="/home/shunli/pro/at/bin/bellhop"
AT_BIN_DIR="/home/shunli/pro/at/bin"

check_component "Bellhop可执行文件" \
    "test -x '$BELLHOP_PATH'" \
    "echo '请手动安装 Acoustic Toolbox 并设置正确路径'"

if [ -d "$AT_BIN_DIR" ]; then
    echo "  📍 Acoustic Toolbox 路径: $AT_BIN_DIR"
    echo "  📂 可用工具:"
    ls -la "$AT_BIN_DIR" | grep -E "(bellhop|kraken|ram)" | head -5
else
    echo -e "  ${YELLOW}⚠️ Acoustic Toolbox 目录不存在: $AT_BIN_DIR${NC}"
fi

echo

# ============================================================================
# 4. 项目结构检查和创建
# ============================================================================
echo -e "${YELLOW}4. 📁 项目结构检查${NC}"

# 创建必要的目录
required_dirs=(
    "data/tmp"
    "validation_results"
    "performance_results"
    "integration_results"
    "comprehensive_test_results"
    "build"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "  📁 创建目录: $dir"
        mkdir -p "$dir"
    else
        echo -e "  ${GREEN}✅ 目录存在: $dir${NC}"
    fi
done

echo

# ============================================================================
# 5. 权限设置
# ============================================================================
echo -e "${YELLOW}5. 🔐 权限设置${NC}"

# 设置脚本执行权限
script_files=(
    "scripts/00_environment_setup.sh"
    "scripts/01_development_validation.sh"
    "scripts/02_performance_testing.sh"
    "scripts/03_integration_testing.sh"
    "scripts/run_comprehensive_test.sh"
    "build.sh"
)

for script in "${script_files[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "  ${GREEN}✅ 设置执行权限: $script${NC}"
    else
        echo -e "  ${YELLOW}⚠️ 脚本不存在: $script${NC}"
    fi
done

echo

# ============================================================================
# 6. 配置文件检查
# ============================================================================
echo -e "${YELLOW}6. ⚙️ 配置文件检查${NC}"

# 检查配置文件
if [ -f "python_core/config.py" ]; then
    echo "  🔍 检查 Bellhop 路径配置..."
    if grep -q "$BELLHOP_PATH" python_core/config.py 2>/dev/null; then
        echo -e "  ${GREEN}✅ Bellhop 路径配置正确${NC}"
    else
        echo -e "  ${YELLOW}⚠️ 可能需要更新 Bellhop 路径配置${NC}"
        echo "    当前 Bellhop 路径: $BELLHOP_PATH"
    fi
else
    echo -e "  ${RED}❌ 配置文件不存在: python_core/config.py${NC}"
fi

echo

# ============================================================================
# 清理操作
# ============================================================================
if [ "$ACTION" = "--clean" ]; then
    echo -e "${YELLOW}🧹 清理临时文件${NC}"
    
    # 清理临时文件
    temp_dirs=("data/tmp" "build" "*_results" "__pycache__")
    for temp_dir in "${temp_dirs[@]}"; do
        if [ -d "$temp_dir" ] || ls $temp_dir > /dev/null 2>&1; then
            echo "  🗑️ 清理: $temp_dir"
            rm -rf $temp_dir
        fi
    done
    
    # 重新创建必要目录
    mkdir -p data/tmp
    echo -e "  ${GREEN}✅ 清理完成${NC}"
fi

echo

# ============================================================================
# 环境配置总结
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 环境配置总结${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "配置时间: $(date)"
echo "总组件数: $TOTAL_COMPONENTS"
echo "已配置数: $CONFIGURED_COMPONENTS"
echo "缺失组件数: $((TOTAL_COMPONENTS - CONFIGURED_COMPONENTS))"

if [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
    echo
    echo -e "${YELLOW}缺失组件列表:${NC}"
    for component in "${MISSING_COMPONENTS[@]}"; do
        echo "  - $component"
    done
fi

echo
success_rate=$((CONFIGURED_COMPONENTS * 100 / TOTAL_COMPONENTS))
echo "配置完成率: ${success_rate}%"

if [ $success_rate -eq 100 ]; then
    echo -e "${GREEN}🎉 环境配置完成！可以开始开发和测试。${NC}"
    echo
    echo -e "${CYAN}建议下一步操作:${NC}"
    echo "  1. 运行开发验证: ./scripts/01_development_validation.sh"
    echo "  2. 运行性能测试: ./scripts/02_performance_testing.sh"
    echo "  3. 运行集成测试: ./scripts/03_integration_testing.sh"
    echo "  4. 运行综合测试: ./scripts/run_comprehensive_test.sh"
    exit 0
elif [ $success_rate -ge 80 ]; then
    echo -e "${YELLOW}⚠️ 环境基本配置完成，但存在一些缺失组件。${NC}"
    echo "  建议使用 --install 参数自动安装缺失组件。"
    exit 0
else
    echo -e "${RED}❌ 环境配置不完整，请解决缺失组件后重新运行。${NC}"
    echo "  使用 --install 参数尝试自动安装: $0 --install"
    exit 1
fi
