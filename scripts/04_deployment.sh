#!/bin/bash

# ============================================================================
# 部署脚本 - Deployment Script
# ============================================================================
# 功能：构建项目、打包部署、生成发布版本
# 使用：./scripts/04_deployment.sh [--build|--package|--install|--release]
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

# 部署配置
DEPLOYMENT_DIR="deployment"
VERSION=$(date +"%Y%m%d_%H%M%S")
BUILD_TYPE="Release"

# 解析命令行参数
ACTION="${1:-build}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📦 BellhopPropagationModel - 部署脚本${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "部署时间: $(date)"
echo "版本标识: $VERSION"
echo "操作模式: $ACTION"
echo

# 部署结果统计
TOTAL_STEPS=0
COMPLETED_STEPS=0
FAILED_STEPS=()

deployment_step() {
    local step_name="$1"
    local result=$2
    local details="$3"
    
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $step_name${NC}"
        [ -n "$details" ] && echo "    $details"
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
        return 0
    else
        echo -e "  ${RED}❌ $step_name${NC}"
        [ -n "$details" ] && echo "    错误: $details"
        FAILED_STEPS+=("$step_name")
        return 1
    fi
}

# ============================================================================
# 1. 预部署检查
# ============================================================================
echo -e "${YELLOW}1. 🔍 预部署检查${NC}"

# 检查环境
if ./scripts/01_development_validation.sh > /dev/null 2>&1; then
    deployment_step "开发环境验证" 0 "环境检查通过"
else
    deployment_step "开发环境验证" 1 "环境检查失败，请先运行环境配置"
    exit 1
fi

# 检查必需文件
required_files=(
    "CMakeLists.txt"
    "build.sh"
    "python_core/bellhop.py"
    "python_wrapper/bellhop_wrapper.py"
    "include/BellhopPropagationModelInterface.h"
    "src/BellhopPropagationModel.cpp"
)

echo "  📁 检查项目文件完整性..."
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "    ${GREEN}✅ $file${NC}"
    else
        deployment_step "文件检查" 1 "缺失文件: $file"
        exit 1
    fi
done

deployment_step "项目文件完整性检查" 0 "所有必需文件存在"

echo

# ============================================================================
# 2. 清理和构建
# ============================================================================
if [ "$ACTION" = "--build" ] || [ "$ACTION" = "--package" ] || [ "$ACTION" = "--release" ]; then
    echo -e "${YELLOW}2. 🔨 项目构建${NC}"
    
    # 清理之前的构建
    echo "  🧹 清理构建目录..."
    rm -rf build/
    mkdir -p build
    
    # CMake 配置
    echo "  ⚙️ CMake 配置..."
    cd build
    if cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE .. > ../deployment/cmake.log 2>&1; then
        deployment_step "CMake 配置" 0 "配置成功"
    else
        deployment_step "CMake 配置" 1 "配置失败，查看 deployment/cmake.log"
        cd ..
        exit 1
    fi
    
    # 编译项目
    echo "  🔧 编译项目..."
    if make -j$(nproc) > ../deployment/build.log 2>&1; then
        deployment_step "项目编译" 0 "编译成功"
    else
        deployment_step "项目编译" 1 "编译失败，查看 deployment/build.log"
        cd ..
        exit 1
    fi
    
    cd ..
    
    # 验证构建结果
    if [ -f "lib/libBellhopPropagationModel.so" ] && [ -f "examples/BellhopPropagationModel" ]; then
        deployment_step "构建产物验证" 0 "库文件和可执行文件生成成功"
    else
        deployment_step "构建产物验证" 1 "构建产物不完整"
        exit 1
    fi
    
    echo
fi

# ============================================================================
# 3. 运行测试套件
# ============================================================================
if [ "$ACTION" = "--package" ] || [ "$ACTION" = "--release" ]; then
    echo -e "${YELLOW}3. 🧪 部署前测试${NC}"
    
    # 快速测试
    echo "  ⚡ 运行快速测试..."
    if ./scripts/99_test_orchestrator.sh --quick > deployment/quick_test.log 2>&1; then
        deployment_step "快速测试" 0 "测试通过"
    else
        deployment_step "快速测试" 1 "测试失败，查看 deployment/quick_test.log"
        exit 1
    fi
    
    # 性能基准测试
    echo "  📊 性能基准测试..."
    if ./scripts/02_performance_testing.sh > deployment/performance_test.log 2>&1; then
        deployment_step "性能测试" 0 "性能达标"
    else
        deployment_step "性能测试" 1 "性能测试失败，查看 deployment/performance_test.log"
        # 性能测试失败不阻止部署，但会记录
    fi
    
    echo
fi

# ============================================================================
# 4. 打包部署
# ============================================================================
if [ "$ACTION" = "--package" ] || [ "$ACTION" = "--release" ]; then
    echo -e "${YELLOW}4. 📦 打包部署${NC}"
    
    # 创建部署包目录
    PACKAGE_NAME="BellhopPropagationModel_${VERSION}"
    PACKAGE_DIR="$DEPLOYMENT_DIR/$PACKAGE_NAME"
    rm -rf "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR"
    
    # 复制核心文件
    echo "  📂 复制核心文件..."
    
    # 库文件
    cp -r lib/ "$PACKAGE_DIR/"
    cp examples/BellhopPropagationModel "$PACKAGE_DIR/"
    
    # Python模块
    cp -r python_core/ "$PACKAGE_DIR/"
    cp -r python_wrapper/ "$PACKAGE_DIR/"
    
    # 头文件
    cp -r include/ "$PACKAGE_DIR/"
    
    # 示例和文档
    cp -r examples/*.json "$PACKAGE_DIR/examples/" 2>/dev/null || mkdir -p "$PACKAGE_DIR/examples/"
    cp README.md "$PACKAGE_DIR/" 2>/dev/null || echo "# BellhopPropagationModel" > "$PACKAGE_DIR/README.md"
    
    # 脚本文件
    mkdir -p "$PACKAGE_DIR/scripts/"
    cp scripts/*.sh "$PACKAGE_DIR/scripts/"
    
    deployment_step "核心文件复制" 0 "文件复制完成"
    
    # 生成版本信息
    cat > "$PACKAGE_DIR/VERSION_INFO.txt" << EOF
BellhopPropagationModel 部署包
===============================
版本: $VERSION
构建时间: $(date)
构建类型: $BUILD_TYPE
Git提交: $(git rev-parse HEAD 2>/dev/null || echo "N/A")

包含组件:
- C++ 动态库 (lib/libBellhopPropagationModel.so)
- Python 核心模块 (python_core/)
- Python 包装器 (python_wrapper/)
- 命令行工具 (BellhopPropagationModel)
- 头文件 (include/)
- 测试脚本 (scripts/)
- 示例配置 (examples/)

特性:
- 多频率批处理优化
- 射线筛选优化
- 完整的Python接口
- 性能优化
EOF
    
    deployment_step "版本信息生成" 0 "版本文件创建完成"
    
    # 创建安装脚本
    cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
# BellhopPropagationModel 安装脚本

echo "正在安装 BellhopPropagationModel..."

# 检查Python环境
if ! python3 --version > /dev/null 2>&1; then
    echo "错误: 需要 Python 3 环境"
    exit 1
fi

# 检查依赖
python3 -c "import numpy, scipy" 2>/dev/null || {
    echo "正在安装 Python 依赖..."
    python3 -m pip install numpy scipy matplotlib psutil
}

# 设置执行权限
chmod +x BellhopPropagationModel
chmod +x scripts/*.sh

# 创建软链接（可选）
read -p "是否创建全局命令链接? (y/N): " create_link
if [ "$create_link" = "y" ] || [ "$create_link" = "Y" ]; then
    sudo ln -sf "$(pwd)/BellhopPropagationModel" /usr/local/bin/bellhop-model
    echo "全局命令 'bellhop-model' 已创建"
fi

echo "安装完成!"
echo "使用方法："
echo "  Python接口: 导入 python_wrapper.bellhop_wrapper"
echo "  命令行工具: ./BellhopPropagationModel"
echo "  测试验证: ./scripts/01_development_validation.sh"
EOF
    
    chmod +x "$PACKAGE_DIR/install.sh"
    deployment_step "安装脚本生成" 0 "install.sh 创建完成"
    
    # 创建压缩包
    echo "  🗜️ 创建压缩包..."
    cd "$DEPLOYMENT_DIR"
    if tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME/"; then
        deployment_step "压缩包创建" 0 "${PACKAGE_NAME}.tar.gz"
    else
        deployment_step "压缩包创建" 1 "压缩失败"
    fi
    cd ..
    
    echo
fi

# ============================================================================
# 5. 安装到系统
# ============================================================================
if [ "$ACTION" = "--install" ]; then
    echo -e "${YELLOW}5. 🏠 系统安装${NC}"
    
    INSTALL_PREFIX="/opt/BellhopPropagationModel"
    
    echo "  📍 安装位置: $INSTALL_PREFIX"
    
    # 创建安装目录
    sudo mkdir -p "$INSTALL_PREFIX"
    sudo cp -r lib/ "$INSTALL_PREFIX/"
    sudo cp -r python_core/ "$INSTALL_PREFIX/"
    sudo cp -r python_wrapper/ "$INSTALL_PREFIX/"
    sudo cp -r include/ "$INSTALL_PREFIX/"
    sudo cp examples/BellhopPropagationModel "$INSTALL_PREFIX/"
    
    deployment_step "系统文件安装" 0 "文件已安装到 $INSTALL_PREFIX"
    
    # 创建环境设置脚本
    sudo tee "/etc/profile.d/bellhop-model.sh" > /dev/null << EOF
export BELLHOP_MODEL_HOME="$INSTALL_PREFIX"
export PATH="\$PATH:$INSTALL_PREFIX"
export PYTHONPATH="\$PYTHONPATH:$INSTALL_PREFIX"
EOF
    
    deployment_step "环境变量配置" 0 "环境变量已配置"
    
    echo
fi

# ============================================================================
# 部署总结
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 部署总结报告${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "部署时间: $(date)"
echo "版本标识: $VERSION"
echo "总步骤数: $TOTAL_STEPS"
echo "完成步骤: $COMPLETED_STEPS"
echo "失败步骤: $((TOTAL_STEPS - COMPLETED_STEPS))"

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo
    echo -e "${RED}失败步骤列表:${NC}"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  - $step"
    done
fi

echo
success_rate=$((COMPLETED_STEPS * 100 / TOTAL_STEPS))
echo "成功率: ${success_rate}%"

if [ $success_rate -eq 100 ]; then
    echo -e "${GREEN}🎉 部署成功完成！${NC}"
    
    if [ "$ACTION" = "--package" ] || [ "$ACTION" = "--release" ]; then
        echo
        echo -e "${CYAN}部署产物:${NC}"
        echo "  📦 部署包: $DEPLOYMENT_DIR/${PACKAGE_NAME}.tar.gz"
        echo "  📂 展开目录: $DEPLOYMENT_DIR/$PACKAGE_NAME/"
        echo
        echo -e "${CYAN}使用方法:${NC}"
        echo "  1. 解压: tar -xzf ${PACKAGE_NAME}.tar.gz"
        echo "  2. 安装: cd $PACKAGE_NAME && ./install.sh"
        echo "  3. 测试: ./scripts/01_development_validation.sh"
    fi
    
    exit 0
else
    echo -e "${RED}❌ 部署过程中存在问题，请检查失败步骤。${NC}"
    exit 1
fi
