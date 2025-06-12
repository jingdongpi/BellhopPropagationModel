#!/bin/bash
# ============================================================================
# 开发阶段验证脚本 - Development Validation
# ============================================================================
# 功能：验证开发环境、代码质量、基础功能
# 使用：./scripts/01_development_validation.sh
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/home/shunli/AcousticProjects/BellhopPropagationModel"
cd "$PROJECT_ROOT"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 BellhopPropagationModel - 开发阶段验证${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "开始时间: $(date)"
echo

# 验证阶段计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0

check_result() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "  ${GREEN}✅ $2${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}❌ $2${NC}"
        return 1
    fi
}

# ============================================================================
# 1. 环境依赖检查
# ============================================================================
echo -e "${YELLOW}1. 🔍 环境依赖检查${NC}"

# Python环境检查
python3 --version > /dev/null 2>&1
check_result $? "Python 3 环境"

# 必需的Python库检查
python3 -c "import numpy; print(f'NumPy {numpy.__version__}')" > /dev/null 2>&1
check_result $? "NumPy 库"

python3 -c "import json; import sys; print(f'JSON 支持正常')" > /dev/null 2>&1
check_result $? "JSON 处理库"

# Bellhop二进制文件检查
if [ -f "/home/shunli/pro/at/bin/bellhop" ]; then
    check_result 0 "Bellhop 二进制文件存在"
else
    check_result 1 "Bellhop 二进制文件缺失"
fi

echo

# ============================================================================
# 2. 项目结构验证
# ============================================================================
echo -e "${YELLOW}2. 📁 项目结构验证${NC}"

# 核心目录检查
directories=("python_core" "python_wrapper" "examples" "include" "lib" "src")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        check_result 0 "目录 $dir 存在"
    else
        check_result 1 "目录 $dir 缺失"
    fi
done

# 关键文件检查
files=(
    "python_core/__init__.py"
    "python_core/bellhop.py"
    "python_wrapper/bellhop_wrapper.py"
    "include/BellhopPropagationModelInterface.h"
    "examples/input_fast_test.json"
    "CMakeLists.txt"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        check_result 0 "文件 $file 存在"
    else
        check_result 1 "文件 $file 缺失"
    fi
done

echo

# ============================================================================
# 3. 代码质量检查
# ============================================================================
echo -e "${YELLOW}3. 📊 代码质量检查${NC}"

# Python语法检查
echo "  🔍 Python语法检查..."
syntax_errors=0
for py_file in $(find python_core python_wrapper -name "*.py" 2>/dev/null); do
    if ! python3 -m py_compile "$py_file" 2>/dev/null; then
        echo -e "    ${RED}语法错误: $py_file${NC}"
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [ $syntax_errors -eq 0 ]; then
    check_result 0 "Python语法检查通过"
else
    check_result 1 "Python语法检查失败 ($syntax_errors 个错误)"
fi

# 代码行数统计
echo "  📈 代码统计:"
python_lines=$(find python_core python_wrapper -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
echo "    Python代码总行数: $python_lines"

cpp_lines=$(find src include -name "*.cpp" -o -name "*.h" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
echo "    C++代码总行数: $cpp_lines"

echo

# ============================================================================
# 4. 模块导入测试
# ============================================================================
echo -e "${YELLOW}4. 🔗 模块导入测试${NC}"

# 测试Python模块导入
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')

try:
    from python_wrapper.bellhop_wrapper import solve_bellhop_propagation, parse_input_data
    print('bellhop_wrapper 模块导入成功')
    exit(0)
except Exception as e:
    print(f'bellhop_wrapper 模块导入失败: {e}')
    exit(1)
" 2>/dev/null
check_result $? "bellhop_wrapper 模块导入"

python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_core')

try:
    from python_core.bellhop import call_Bellhop
    print('bellhop_core 模块导入成功')
    exit(0)
except Exception as e:
    print(f'bellhop_core 模块导入失败: {e}')
    exit(1)
" 2>/dev/null
check_result $? "bellhop_core 模块导入"

echo

# ============================================================================
# 5. 接口规范验证
# ============================================================================
echo -e "${YELLOW}5. 📋 接口规范验证${NC}"

if [ -f "test_interface_compliance.py" ]; then
    echo "  🔍 运行接口规范验证..."
    if python3 test_interface_compliance.py > /tmp/interface_test.log 2>&1; then
        success_rate=$(grep "成功率:" /tmp/interface_test.log | awk '{print $2}' | sed 's/%//' || echo "0")
        if [ -n "$success_rate" ] && [ "${success_rate%.*}" -ge 80 ]; then
            check_result 0 "接口规范验证通过 (${success_rate}%)"
        else
            check_result 1 "接口规范验证失败 (${success_rate}%)"
        fi
    else
        check_result 1 "接口规范验证执行失败"
    fi
else
    check_result 1 "接口规范验证脚本缺失"
fi

echo

# ============================================================================
# 6. 基础功能测试
# ============================================================================
echo -e "${YELLOW}6. ⚙️ 基础功能测试${NC}"

# 测试最简单的配置
echo "  🧪 测试最小配置..."
if [ -f "examples/input_minimal_test.json" ]; then
    python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    with open('examples/input_minimal_test.json', 'r') as f:
        test_data = json.load(f)
    
    result = solve_bellhop_propagation(test_data)
    result_data = json.loads(result) if isinstance(result, str) else result
    
    if result_data.get('error_code') == 200:
        print('基础功能测试通过')
        exit(0)
    else:
        print(f'基础功能测试失败: {result_data.get(\"error_message\", \"未知错误\")}')
        exit(1)
except Exception as e:
    print(f'基础功能测试异常: {e}')
    exit(1)
" 2>/dev/null
    check_result $? "最小配置功能测试"
else
    check_result 1 "最小配置测试文件缺失"
fi

echo

# ============================================================================
# 7. 构建系统检查
# ============================================================================
echo -e "${YELLOW}7. 🔨 构建系统检查${NC}"

# CMake配置检查
if [ -f "CMakeLists.txt" ]; then
    check_result 0 "CMakeLists.txt 存在"
    
    # 检查是否已构建
    if [ -f "examples/BellhopPropagationModel" ] && [ -x "examples/BellhopPropagationModel" ]; then
        check_result 0 "可执行文件已构建"
    else
        echo "  🔧 尝试构建项目..."
        if [ -f "build.sh" ] && bash build.sh > /tmp/build.log 2>&1; then
            check_result 0 "项目构建成功"
        else
            check_result 1 "项目构建失败"
        fi
    fi
else
    check_result 1 "CMakeLists.txt 缺失"
fi

# 动态库检查
if [ -f "lib/libBellhopPropagationModel.so" ]; then
    check_result 0 "动态库文件存在"
else
    check_result 1 "动态库文件缺失"
fi

echo

# ============================================================================
# 总结报告
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 开发阶段验证总结报告${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "验证时间: $(date)"
echo "总检查项: $TOTAL_CHECKS"
echo "通过项数: $PASSED_CHECKS"
echo "失败项数: $((TOTAL_CHECKS - PASSED_CHECKS))"

success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "通过率: ${success_rate}%"

echo
if [ $success_rate -ge 90 ]; then
    echo -e "${GREEN}🎉 开发环境验证优秀！可以进入性能测试阶段。${NC}"
    exit 0
elif [ $success_rate -ge 80 ]; then
    echo -e "${YELLOW}⚠️ 开发环境验证良好，建议修复剩余问题后进入下一阶段。${NC}"
    exit 0
else
    echo -e "${RED}❌ 开发环境验证失败，请修复关键问题后重新验证。${NC}"
    exit 1
fi
