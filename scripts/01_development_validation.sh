#!/bin/bash
# ============================================================================
# 开发阶段验证脚本 - Development Validation
# ============================================================================
# 功能：验证开发环境、代码质量、基础功能、射线筛选优化
# 使用：./scripts/01_development_validation.sh
# 版本：2.0 - 适配射线筛选优化和多频率功能
# ============================================================================

set -e  # 遇到错误立即退出
# 但对于某些非关键检查，我们会临时禁用这个设置

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/home/shunli/AcousticProjects/BellhopPropagationModel"
cd "$PROJECT_ROOT"

# 验证结果目录
VALIDATION_DIR="validation_results"
mkdir -p "$VALIDATION_DIR"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 BellhopPropagationModel - 开发阶段验证 v2.0${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "开始时间: $(date)"
echo "项目路径: $PROJECT_ROOT"
echo "验证结果目录: $VALIDATION_DIR"
echo

# 验证阶段计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=()

check_result() {
    local result=$1
    local test_name="$2"
    local details="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $test_name${NC}"
        if [ -n "$details" ]; then
            echo -e "     ${CYAN}$details${NC}"
        fi
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}❌ $test_name${NC}"
        if [ -n "$details" ]; then
            echo -e "     ${RED}$details${NC}"
        fi
        FAILED_CHECKS+=("$test_name")
        return 1
    fi
}

# ============================================================================
# 1. 环境依赖检查
# ============================================================================
echo -e "${YELLOW}1. 🔍 环境依赖检查${NC}"

# Python环境检查
python3 --version > /dev/null 2>&1
python_version=$(python3 --version 2>&1)
check_result $? "Python 3 环境" "$python_version"

# 必需的Python库检查
echo "  检查Python依赖库..."
python3 -c "import numpy; print(f'NumPy {numpy.__version__}')" > "$VALIDATION_DIR/numpy_check.log" 2>&1
numpy_version=$(python3 -c "import numpy; print(numpy.__version__)" 2>/dev/null || echo "未安装")
check_result $? "NumPy 库" "版本: $numpy_version"

python3 -c "import scipy; print(f'SciPy {scipy.__version__}')" > "$VALIDATION_DIR/scipy_check.log" 2>&1
scipy_version=$(python3 -c "import scipy; print(scipy.__version__)" 2>/dev/null || echo "未安装")
check_result $? "SciPy 库" "版本: $scipy_version"

python3 -c "import json, os, sys; print('核心库支持正常')" > /dev/null 2>&1
check_result $? "Python 核心库"

# Bellhop二进制文件检查
echo "  🔍 检查 Bellhop 二进制文件..."
python3 -c "
import sys
sys.path.insert(0, '.')
from python_core.config import AtBinPath
import os

bellhop_path = os.path.join(AtBinPath, 'bellhop')
if os.path.exists(bellhop_path) and os.access(bellhop_path, os.X_OK):
    print(f'✅ Bellhop 二进制文件: {bellhop_path}')
    exit(0)
else:
    print(f'❌ Bellhop 二进制文件不存在或不可执行: {bellhop_path}')
    exit(1)
" > "$VALIDATION_DIR/bellhop_check.log" 2>&1
check_result $? "Bellhop 二进制文件" "使用项目配置检测"

# 检查多频率和射线优化相关功能
echo "  检查项目核心功能..."
python3 -c "
import sys
sys.path.insert(0, '.')
from python_core.bellhop import find_cvgcRays, call_Bellhop_multi_freq
print('射线筛选和多频率功能可导入')
" > "$VALIDATION_DIR/core_functions.log" 2>&1
check_result $? "核心功能导入" "射线筛选优化和多频率功能"

echo

# ============================================================================
# 2. 项目结构验证
# ============================================================================
echo -e "${YELLOW}2. 📁 项目结构验证${NC}"

# 核心目录检查
directories=("python_core" "python_wrapper" "examples" "include" "lib" "src" "scripts" "data")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        file_count=$(find "$dir" -type f | wc -l)
        check_result 0 "目录 $dir" "包含 $file_count 个文件"
    else
        check_result 1 "目录 $dir 缺失"
    fi
done

# 关键文件检查
files=(
    "python_core/__init__.py"
    "python_core/bellhop.py"
    "python_core/config.py"
    "python_wrapper/bellhop_wrapper.py"
    "include/BellhopPropagationModelInterface.h"
    "examples/input_small.json"
    "examples/input_medium.json"
    "examples/input_large.json"
    "examples/input_ray_test.json"
    "examples/input_multi_frequency.json"
    "CMakeLists.txt"
    "build.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        file_size=$(du -h "$file" | cut -f1)
        check_result 0 "文件 $file" "大小: $file_size"
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
python_files=()
for py_file in $(find python_core python_wrapper -name "*.py" 2>/dev/null); do
    python_files+=("$py_file")
    # 创建安全的日志文件名（将路径中的斜杠替换为下划线）
    safe_filename=$(echo "$py_file" | tr '/' '_')
    if ! python3 -m py_compile "$py_file" 2>"$VALIDATION_DIR/syntax_error_${safe_filename}.log"; then
        echo -e "    ${RED}语法错误: $py_file${NC}"
        # 显示具体错误信息
        error_msg=$(python3 -m py_compile "$py_file" 2>&1 | head -2)
        echo -e "    ${RED}错误详情: $error_msg${NC}"
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [ $syntax_errors -eq 0 ]; then
    check_result 0 "Python语法检查" "检查了 ${#python_files[@]} 个文件"
else
    check_result 1 "Python语法检查失败" "$syntax_errors 个错误"
fi

# 代码质量检查
echo "  🔍 关键代码检查..."
# 检查射线筛选函数
grep -q "find_cvgcRays.*bathymetry" python_core/bellhop.py
check_result $? "射线筛选优化函数" "动态深度阈值支持"

# 检查多频率函数
grep -q "call_Bellhop_multi_freq" python_core/bellhop.py
check_result $? "多频率计算函数" "批量频率处理"

# 代码行数统计
echo "  📈 代码统计:"
python_lines=$(find python_core python_wrapper -name "*.py" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
echo "    Python代码总行数: $python_lines"

cpp_lines=$(find src include -name "*.cpp" -o -name "*.h" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
echo "    C++代码总行数: $cpp_lines"

json_files=$(find examples -name "*.json" | wc -l)
echo "    测试配置文件: $json_files 个"

echo

# ============================================================================
# 4. 模块导入测试
# ============================================================================
echo -e "${YELLOW}4. 🔗 模块导入测试${NC}"

# 测试核心模块导入
python3 -c "
import sys
sys.path.insert(0, '.')

try:
    from python_core.bellhop import find_cvgcRays, call_Bellhop_multi_freq, call_Bellhop, call_Bellhop_Rays
    print('✅ 核心bellhop模块导入成功')
    exit(0)
except Exception as e:
    print(f'❌ 核心bellhop模块导入失败: {e}')
    exit(1)
" > "$VALIDATION_DIR/core_import.log" 2>&1
check_result $? "核心bellhop模块导入"

# 测试包装器模块导入
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')

try:
    from python_wrapper.bellhop_wrapper import solve_bellhop_propagation, parse_input_data
    print('✅ bellhop_wrapper 模块导入成功')
    exit(0)
except Exception as e:
    print(f'❌ bellhop_wrapper 模块导入失败: {e}')
    exit(1)
" > "$VALIDATION_DIR/wrapper_import.log" 2>&1
check_result $? "bellhop_wrapper 模块导入"

# 测试环境模块导入
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_core')

try:
    from python_core.env import Pos, Source, Dom, SSP, Beam, Box
    from python_core.readwrite import write_env, read_shd, get_rays
    print('✅ 环境和读写模块导入成功')
    exit(0)
except Exception as e:
    print(f'❌ 环境和读写模块导入失败: {e}')
    exit(1)
" > "$VALIDATION_DIR/env_import.log" 2>&1
check_result $? "环境和读写模块导入"

echo

# ============================================================================
# 5. 射线筛选优化验证
# ============================================================================
echo -e "${YELLOW}5. 🎯 射线筛选优化验证${NC}"

# 验证射线筛选函数签名
python3 -c "
import sys
sys.path.insert(0, '.')
from python_core.bellhop import find_cvgcRays
import inspect

# 检查函数签名
sig = inspect.signature(find_cvgcRays)
params = list(sig.parameters.keys())

if 'bathymetry' in params:
    print('✅ 射线筛选支持动态深度阈值')
    exit(0)
else:
    print('❌ 射线筛选缺少bathymetry参数')
    exit(1)
" > "$VALIDATION_DIR/ray_filtering.log" 2>&1
check_result $? "射线筛选优化参数" "支持动态深度阈值"

# 验证多频率功能
python3 -c "
import sys
sys.path.insert(0, '.')
from python_core.bellhop import call_Bellhop_multi_freq
import inspect

# 检查函数存在性
sig = inspect.signature(call_Bellhop_multi_freq)
params = list(sig.parameters.keys())

if 'frequencies' in params and 'performance_mode' in params:
    print('✅ 多频率功能完整')
    exit(0)
else:
    print('❌ 多频率功能不完整')
    exit(1)
" > "$VALIDATION_DIR/multi_freq.log" 2>&1
check_result $? "多频率计算功能" "支持批量频率处理"

echo

# ============================================================================
# 6. 接口规范验证
# ============================================================================
echo -e "${YELLOW}6. 📋 接口规范验证${NC}"

# 测试JSON输入输出格式
echo "  🔍 验证输入输出接口..."
python3 -c "
import sys, json
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

# 构造最小测试输入
test_input = {
    'freq': 100,
    'source_depth': 20,
    'receiver_depth': [10, 30],
    'receiver_range': [500, 1000],
    'bathy': {'range': [0, 1000], 'depth': [100, 110]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50, 100], 'speed': [1520, 1510, 1500]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}]
}

try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    
    required_fields = ['error_code', 'receiver_depth', 'receiver_range', 'transmission_loss']
    missing_fields = [f for f in required_fields if f not in result_data]
    
    if not missing_fields and result_data['error_code'] == 200:
        print('✅ 接口格式正确')
        exit(0)
    else:
        print(f'❌ 接口格式错误，缺少字段: {missing_fields}')
        exit(1)
except Exception as e:
    print(f'❌ 接口测试失败: {e}')
    exit(1)
" > "$VALIDATION_DIR/interface_test.log" 2>&1
check_result $? "JSON接口格式验证" "输入输出格式符合规范"

echo

# ============================================================================
# 7. 基础功能测试
# ============================================================================
echo -e "${YELLOW}7. ⚙️ 基础功能测试${NC}"

# 测试各种输入文件 (开发验证阶段使用轻量级测试)
echo "  🧪 基础功能验证 (轻量级测试)..."

# 仅测试接口是否能正常调用，不进行完整计算
python3 -c "
import sys, json
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

# 构造极简测试输入，快速验证接口
test_input = {
    'freq': 100,
    'source_depth': 20,
    'receiver_depth': [30],
    'receiver_range': [100],
    'bathy': {'range': [0, 200], 'depth': [50, 50]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50], 'speed': [1500, 1500]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}],
    'options': {'ray_num': 5, 'ray_alpha_max': 10, 'ray_alpha_min': -10}  # 极少射线数快速测试
}

try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    
    if result_data.get('error_code') == 200:
        print('✅ 基础接口功能验证成功')
        exit(0)
    else:
        print(f'❌ 基础接口测试失败: {result_data.get(\"error_message\", \"未知错误\")}')
        exit(1)
except Exception as e:
    print(f'❌ 基础接口测试异常: {e}')
    exit(1)
" > "$VALIDATION_DIR/basic_interface_test.log" 2>&1
check_result $? "基础接口功能验证" "轻量级快速测试"

# 检查示例文件是否存在（不执行耗时计算）
test_files=("input_small.json" "input_medium.json" "input_ray_test.json")
for test_file in "${test_files[@]}"; do
    if [ -f "examples/$test_file" ]; then
        # 仅验证文件格式，不执行计算
        python3 -c "
import sys, json
with open('examples/${test_file}', 'r') as f:
    data = json.load(f)
    
required_fields = ['freq', 'source_depth', 'receiver_depth', 'receiver_range', 'bathy']
missing_fields = [f for f in required_fields if f not in data]

if not missing_fields:
    print('✅ ${test_file} 格式验证成功')
    exit(0)
else:
    print('❌ ${test_file} 格式错误，缺少字段:', missing_fields)
    exit(1)
        " > "$VALIDATION_DIR/format_$test_file.log" 2>&1
        check_result $? "$test_file 格式验证" "JSON格式正确"
    else
        check_result 1 "$test_file 测试文件缺失"
    fi
done

# 性能基准测试
echo "  ⏱️ 基准性能测试..."
python3 -c "
import sys, json, time
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

# 使用小规模测试数据进行性能测试
test_input = {
    'freq': 100,
    'source_depth': 20,
    'receiver_depth': [10, 20, 30],
    'receiver_range': [500, 1000, 1500],
    'bathy': {'range': [0, 2000], 'depth': [100, 120]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50, 100], 'speed': [1520, 1510, 1500]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}],
    'options': {'is_propagation_pressure_output': True}
}

start_time = time.time()
try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    execution_time = time.time() - start_time
    
    if result_data.get('error_code') == 200 and execution_time < 10.0:
        print(f'✅ 基准性能测试通过 ({execution_time:.2f}s)')
        exit(0)
    else:
        print(f'❌ 性能测试失败或超时 ({execution_time:.2f}s)')
        exit(1)
except Exception as e:
    execution_time = time.time() - start_time
    print(f'❌ 性能测试异常 ({execution_time:.2f}s): {e}')
    exit(1)
" > "$VALIDATION_DIR/performance_benchmark.log" 2>&1
check_result $? "基准性能测试" "小规模计算在10秒内完成"

echo

# ============================================================================
# 8. 构建系统检查
# ============================================================================
echo -e "${YELLOW}8. 🔨 构建系统检查${NC}"

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
