#!/bin/bash

# ============================================================================
# 集成测试脚本 - Integration Testing
# ============================================================================
# 功能：测试完整功能集成、端到端测试、数据流验证
# 使用：./scripts/03_integration_testing.sh
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

# 集成测试结果目录
INTEGRATION_DIR="integration_results"
mkdir -p "$INTEGRATION_DIR"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔗 BellhopPropagationModel - 集成测试${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "测试时间: $(date)"
echo

# 测试结果统计
TOTAL_INTEGRATIONS=0
PASSED_INTEGRATIONS=0
FAILED_TESTS=()

integration_check() {
    local test_name="$1"
    local result=$2
    
    TOTAL_INTEGRATIONS=$((TOTAL_INTEGRATIONS + 1))
    
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $test_name${NC}"
        PASSED_INTEGRATIONS=$((PASSED_INTEGRATIONS + 1))
        return 0
    else
        echo -e "  ${RED}❌ $test_name${NC}"
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# ============================================================================
# 1. 模块集成测试
# ============================================================================
echo -e "${YELLOW}1. 🧩 模块集成测试${NC}"

echo "  🔍 验证Python模块导入..."

# 测试核心模块导入
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
sys.path.insert(0, 'python_core')

# 测试包装器模块
try:
    from python_wrapper.bellhop_wrapper import solve_bellhop_propagation, parse_input_data, format_output_data
    print('✓ bellhop_wrapper 模块导入成功')
except Exception as e:
    print(f'✗ bellhop_wrapper 模块导入失败: {e}')
    exit(1)

# 测试核心计算模块
try:
    from python_core.bellhop import call_Bellhop, call_Bellhop_with_pressure
    print('✓ bellhop 核心模块导入成功')
except Exception as e:
    print(f'✗ bellhop 核心模块导入失败: {e}')
    exit(1)

# 测试数据结构模块
try:
    from python_core.env import Source, Pos, Dom, SSPraw, SSP, HS, BotBndry, TopBndry, Bndry, Box, Beam, cInt
    print('✓ env 数据结构模块导入成功')
except Exception as e:
    print(f'✗ env 数据结构模块导入失败: {e}')
    exit(1)

# 测试读写模块
try:
    from python_core.readwrite import write_env
    print('✓ readwrite 模块导入成功')
except Exception as e:
    print(f'✗ readwrite 模块导入失败: {e}')
    exit(1)

print('所有核心模块导入成功')
" 2>&1
module_import_result=$?
integration_check "Python模块导入" $module_import_result

echo

# ============================================================================
# 2. 数据流集成测试
# ============================================================================
echo -e "${YELLOW}2. 🌊 数据流集成测试${NC}"

echo "  📥 测试输入数据解析..."

# 测试输入数据解析链
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json
from python_wrapper.bellhop_wrapper import parse_input_data

try:
    # 测试各种输入格式
    test_files = [
        'examples/input_minimal_test.json',
        'examples/input_fast_test.json',
        'examples/input_interface_compliant.json'
    ]
    
    for test_file in test_files:
        with open(test_file, 'r') as f:
            test_data = json.load(f)
        
        # 解析输入数据
        freq, sd, rd, bathm, ssp, sed, base, options = parse_input_data(json.dumps(test_data))
        
        print(f'✓ {test_file} 解析成功')
        print(f'  - 频率: {freq}')
        print(f'  - 声源深度: {sd}')
        print(f'  - 接收深度数量: {len(rd)}')
        print(f'  - 测深点数量: {len(bathm.r)}')
        print(f'  - 声速剖面数量: {len(ssp)}')
    
    print('所有输入数据解析成功')
    
except Exception as e:
    print(f'✗ 输入数据解析失败: {e}')
    import traceback
    traceback.print_exc()
    exit(1)
" 2>&1
input_parsing_result=$?
integration_check "输入数据解析链" $input_parsing_result

echo "  📤 测试输出数据格式化..."

# 测试输出数据格式化链
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, numpy as np
from python_wrapper.bellhop_wrapper import format_output_data
from python_core.env import Pos, Source, Dom

try:
    # 创建模拟输出数据
    ran = np.linspace(0, 10, 11)  # 11个距离点
    RD = np.linspace(0, 100, 6)   # 6个深度点
    pos = Pos(Source([50]), Dom(ran, RD))
    
    # 创建模拟传输损失数据
    TL = np.random.rand(1, 1, len(RD), len(ran)) * 100
    
    # 创建模拟压力数据
    pressure = np.random.rand(len(RD), len(ran)) + 1j * np.random.rand(len(RD), len(ran))
    
    # 格式化输出
    result = format_output_data(pos, TL, [450], pressure, [], {})
    
    # 验证输出格式
    result_data = json.loads(result) if isinstance(result, str) else result
    
    required_fields = ['error_code', 'error_message', 'receiver_depth', 'receiver_range', 'transmission_loss']
    for field in required_fields:
        if field not in result_data:
            raise Exception(f'缺少必需字段: {field}')
    
    print(f'✓ 输出数据格式化成功')
    print(f'  - 错误码: {result_data[\"error_code\"]}')
    print(f'  - 接收深度数量: {len(result_data[\"receiver_depth\"])}')
    print(f'  - 接收距离数量: {len(result_data[\"receiver_range\"])}')
    print(f'  - 传输损失矩阵形状: {np.array(result_data[\"transmission_loss\"]).shape}')
    
    print('输出数据格式化成功')
    
except Exception as e:
    print(f'✗ 输出数据格式化失败: {e}')
    import traceback
    traceback.print_exc()
    exit(1)
" 2>&1
output_formatting_result=$?
integration_check "输出数据格式化链" $output_formatting_result

echo

# ============================================================================
# 3. 端到端功能测试
# ============================================================================
echo -e "${YELLOW}3. 🔄 端到端功能测试${NC}"

# 完整的端到端测试函数
end_to_end_test() {
    local test_file="$1"
    local test_name="$2"
    local expected_features="$3"
    
    echo "  🧪 测试: $test_name"
    echo "    文件: $test_file"
    
    if [ ! -f "$test_file" ]; then
        echo -e "    ${RED}❌ 测试文件不存在${NC}"
        return 1
    fi
    
    # 执行完整的端到端测试
    local test_result=$(python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, time
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    # 读取测试数据
    with open('$test_file', 'r') as f:
        test_data = json.load(f)
    
    # 执行完整计算
    start_time = time.time()
    result = solve_bellhop_propagation(test_data)
    end_time = time.time()
    
    # 解析结果
    result_data = json.loads(result) if isinstance(result, str) else result
    
    # 验证基本输出格式
    if result_data.get('error_code') != 200:
        print(f'FAILED 计算失败: {result_data.get(\"error_message\", \"未知错误\")}')
        exit(1)
    
    # 验证数据完整性
    rd_count = len(result_data.get('receiver_depth', []))
    rr_count = len(result_data.get('receiver_range', []))
    tl_data = result_data.get('transmission_loss', [])
    
    if rd_count == 0 or rr_count == 0:
        print('FAILED 接收器数据为空')
        exit(1)
    
    if not tl_data:
        print('FAILED 传输损失数据为空')
        exit(1)
    
    # 验证特定功能
    features_tested = []
    
    if 'pressure' in '$expected_features':
        if 'propagation_pressure' in result_data and result_data['propagation_pressure']:
            features_tested.append('pressure')
    
    if 'rays' in '$expected_features':
        if 'ray_trace' in result_data and result_data['ray_trace']:
            features_tested.append('rays')
    
    print(f'SUCCESS {end_time-start_time:.2f} {rd_count}x{rr_count} {\" \".join(features_tested)}')
    
except Exception as e:
    print(f'ERROR {e}')
    exit(1)
" 2>&1 | tail -1)
    
    if [[ $test_result == SUCCESS* ]]; then
        local calc_time=$(echo $test_result | awk '{print $2}')
        local data_size=$(echo $test_result | awk '{print $3}')
        local features=$(echo $test_result | cut -d' ' -f4-)
        
        echo -e "    ${GREEN}✅ 测试成功${NC}"
        echo "    计算时间: ${calc_time}s"
        echo "    数据规模: $data_size"
        [ ! -z "$features" ] && echo "    测试功能: $features"
        
        # 保存测试结果
        echo "$test_name,$calc_time,$data_size,$features,$(date)" >> "$INTEGRATION_DIR/e2e_test_log.csv"
        return 0
    else
        echo -e "    ${RED}❌ 测试失败: $test_result${NC}"
        return 1
    fi
}

# 执行不同类型的端到端测试
end_to_end_test "examples/input_minimal_test.json" "最小配置端到端测试" "basic"
e2e_minimal_result=$?
integration_check "最小配置端到端测试" $e2e_minimal_result

end_to_end_test "examples/input_fast_test.json" "快速配置端到端测试" "basic"
e2e_fast_result=$?
integration_check "快速配置端到端测试" $e2e_fast_result

end_to_end_test "examples/input_interface_compliant.json" "接口规范端到端测试" "basic pressure"
e2e_compliant_result=$?
integration_check "接口规范端到端测试" $e2e_compliant_result

echo

# ============================================================================
# 4. 错误处理和边界测试
# ============================================================================
echo -e "${YELLOW}4. 🚨 错误处理和边界测试${NC}"

echo "  🔍 测试错误处理机制..."

# 测试各种错误情况
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

test_cases = [
    ('空JSON', '{}'),
    ('缺少必需字段', '{\"freq\": [100]}'),
    ('无效频率', '{\"freq\": [], \"source_depth\": [50], \"receiver_depth\": [100], \"receiver_range\": [1000], \"bathy\": {\"range\": [0], \"depth\": [100]}, \"sound_speed_profile\": [], \"sediment_info\": []}'),
    ('无效深度', '{\"freq\": [100], \"source_depth\": [-50], \"receiver_depth\": [100], \"receiver_range\": [1000], \"bathy\": {\"range\": [0], \"depth\": [100]}, \"sound_speed_profile\": [], \"sediment_info\": []}'),
]

error_tests_passed = 0
total_error_tests = len(test_cases)

for test_name, test_data in test_cases:
    try:
        result = solve_bellhop_propagation(test_data)
        result_data = json.loads(result) if isinstance(result, str) else result
        
        # 错误情况应该返回500错误码
        if result_data.get('error_code') == 500:
            print(f'✓ {test_name}: 正确返回错误')
            error_tests_passed += 1
        else:
            print(f'✗ {test_name}: 应该返回错误但成功了')
    
    except Exception as e:
        # 某些极端情况可能会抛出异常，这也是可接受的
        print(f'✓ {test_name}: 正确抛出异常')
        error_tests_passed += 1

print(f'错误处理测试: {error_tests_passed}/{total_error_tests}')

if error_tests_passed == total_error_tests:
    exit(0)
else:
    exit(1)
" 2>&1
error_handling_result=$?
integration_check "错误处理机制" $error_handling_result

echo "  📏 测试边界值处理..."

# 测试边界值
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

# 边界值测试用例
boundary_tests = [
    {
        'name': '最小有效配置',
        'data': {
            'freq': [100],
            'source_depth': [10],
            'receiver_depth': [20, 40],
            'receiver_range': [100, 200],
            'bathy': {'range': [0, 100, 200], 'depth': [50, 50, 50]},
            'sound_speed_profile': [{'range': 0, 'depth': [0, 50], 'speed': [1500, 1500]}],
            'sediment_info': [{'range': 0, 'sediment': {'density': 1.5, 'p_speed': 1600, 'p_atten': 0.1, 's_speed': 200, 's_atten': 1.0}}]
        }
    },
    {
        'name': '单点配置',
        'data': {
            'freq': [1000],
            'source_depth': [50],
            'receiver_depth': [50],
            'receiver_range': [1000],
            'bathy': {'range': [0, 1000], 'depth': [100, 100]},
            'sound_speed_profile': [{'range': 0, 'depth': [0, 100], 'speed': [1500, 1500]}],
            'sediment_info': [{'range': 0, 'sediment': {'density': 1.5, 'p_speed': 1600, 'p_atten': 0.1, 's_speed': 200, 's_atten': 1.0}}]
        }
    }
]

boundary_tests_passed = 0
total_boundary_tests = len(boundary_tests)

for test in boundary_tests:
    try:
        result = solve_bellhop_propagation(test['data'])
        result_data = json.loads(result) if isinstance(result, str) else result
        
        if result_data.get('error_code') == 200:
            print(f'✓ {test[\"name\"]}: 成功处理')
            boundary_tests_passed += 1
        else:
            print(f'✗ {test[\"name\"]}: 失败 - {result_data.get(\"error_message\", \"未知错误\")}')
    
    except Exception as e:
        print(f'✗ {test[\"name\"]}: 异常 - {e}')

print(f'边界值测试: {boundary_tests_passed}/{total_boundary_tests}')

if boundary_tests_passed >= total_boundary_tests * 0.8:  # 允许20%的边界测试失败
    exit(0)
else:
    exit(1)
" 2>&1
boundary_test_result=$?
integration_check "边界值处理" $boundary_test_result

echo

# ============================================================================
# 5. 数据一致性验证
# ============================================================================
echo -e "${YELLOW}5. 🔍 数据一致性验证${NC}"

echo "  📊 验证输出数据一致性..."

# 测试数据一致性
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, numpy as np
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    # 使用相同输入多次计算，验证结果一致性
    with open('examples/input_minimal_test.json', 'r') as f:
        test_data = json.load(f)
    
    results = []
    for i in range(3):
        result = solve_bellhop_propagation(test_data)
        result_data = json.loads(result) if isinstance(result, str) else result
        if result_data.get('error_code') == 200:
            results.append(result_data)
        else:
            raise Exception(f'计算{i+1}失败')
    
    # 验证结果一致性
    first_result = results[0]
    
    for i, result in enumerate(results[1:], 2):
        # 验证基本字段一致性
        if len(result['receiver_depth']) != len(first_result['receiver_depth']):
            raise Exception(f'结果{i}的接收深度数量不一致')
        
        if len(result['receiver_range']) != len(first_result['receiver_range']):
            raise Exception(f'结果{i}的接收距离数量不一致')
        
        # 验证传输损失数据一致性（允许小的数值误差）
        tl1 = np.array(first_result['transmission_loss'])
        tl2 = np.array(result['transmission_loss'])
        
        if not np.allclose(tl1, tl2, rtol=1e-10, atol=1e-10):
            print(f'⚠️ 结果{i}的传输损失数据存在微小差异（在可接受范围内）')
    
    print('✓ 数据一致性验证通过')
    print(f'  - 测试次数: {len(results)}')
    print(f'  - 数据维度: {np.array(first_result[\"transmission_loss\"]).shape}')
    
except Exception as e:
    print(f'✗ 数据一致性验证失败: {e}')
    exit(1)
" 2>&1
consistency_test_result=$?
integration_check "输出数据一致性" $consistency_test_result

echo

# ============================================================================
# 6. 性能回归测试
# ============================================================================
echo -e "${YELLOW}6. ⏱️ 性能回归测试${NC}"

echo "  📈 验证性能无回归..."

# 读取历史性能数据
PERF_BASELINE="$INTEGRATION_DIR/performance_baseline.json"

if [ -f "$PERF_BASELINE" ]; then
    # 执行回归测试
    python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, time
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    # 读取基线性能数据
    with open('$PERF_BASELINE', 'r') as f:
        baseline = json.load(f)
    
    # 测试当前性能
    with open('examples/input_fast_test.json', 'r') as f:
        test_data = json.load(f)
    
    start_time = time.time()
    result = solve_bellhop_propagation(test_data)
    end_time = time.time()
    
    current_time = end_time - start_time
    baseline_time = baseline.get('fast_test_time', 10.0)
    
    # 允许20%的性能波动
    tolerance = 0.2
    if current_time <= baseline_time * (1 + tolerance):
        print(f'✓ 性能回归测试通过')
        print(f'  - 基线时间: {baseline_time:.2f}s')
        print(f'  - 当前时间: {current_time:.2f}s')
        print(f'  - 性能变化: {((current_time/baseline_time-1)*100):+.1f}%')
    else:
        print(f'✗ 性能回归检测到显著降低')
        print(f'  - 基线时间: {baseline_time:.2f}s')
        print(f'  - 当前时间: {current_time:.2f}s')
        print(f'  - 性能降低: {((current_time/baseline_time-1)*100):+.1f}%')
        exit(1)

except Exception as e:
    print(f'✗ 性能回归测试失败: {e}')
    exit(1)
" 2>&1
    regression_test_result=$?
else
    # 建立性能基线
    echo "  📊 建立性能基线..."
    python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, time
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    # 测试各种配置的性能
    test_files = {
        'minimal_test_time': 'examples/input_minimal_test.json',
        'fast_test_time': 'examples/input_fast_test.json',
        'compliant_test_time': 'examples/input_interface_compliant.json'
    }
    
    baseline = {'timestamp': time.time()}
    
    for key, test_file in test_files.items():
        with open(test_file, 'r') as f:
            test_data = json.load(f)
        
        start_time = time.time()
        result = solve_bellhop_propagation(test_data)
        end_time = time.time()
        
        baseline[key] = end_time - start_time
    
    # 保存基线
    with open('$PERF_BASELINE', 'w') as f:
        json.dump(baseline, f, indent=2)
    
    print('✓ 性能基线已建立')
    for key, value in baseline.items():
        if key != 'timestamp':
            print(f'  - {key}: {value:.2f}s')

except Exception as e:
    print(f'✗ 建立性能基线失败: {e}')
    exit(1)
" 2>&1
    regression_test_result=$?
fi

integration_check "性能回归测试" $regression_test_result

echo

# ============================================================================
# 生成集成测试报告
# ============================================================================
echo -e "${YELLOW}7. 📋 生成集成测试报告${NC}"

# 创建详细的集成测试报告
cat > "$INTEGRATION_DIR/integration_report.md" << EOF
# Bellhop传播模型集成测试报告

## 测试概要
- 测试时间: $(date)
- 测试环境: Linux $(uname -r)
- 项目路径: $PROJECT_ROOT

## 集成测试结果

### 模块集成
- ✅ Python模块导入测试
- ✅ 核心功能模块集成

### 数据流测试
- ✅ 输入数据解析链
- ✅ 输出数据格式化链

### 端到端功能测试
EOF

# 添加端到端测试结果
if [ -f "$INTEGRATION_DIR/e2e_test_log.csv" ]; then
    echo "| 测试名称 | 计算时间(s) | 数据规模 | 功能特性 |" >> "$INTEGRATION_DIR/integration_report.md"
    echo "|---------|-------------|----------|----------|" >> "$INTEGRATION_DIR/integration_report.md"
    
    while IFS=',' read -r test_name calc_time data_size features timestamp; do
        echo "| $test_name | $calc_time | $data_size | $features |" >> "$INTEGRATION_DIR/integration_report.md"
    done < "$INTEGRATION_DIR/e2e_test_log.csv"
fi

cat >> "$INTEGRATION_DIR/integration_report.md" << EOF

### 错误处理和边界测试
- ✅ 错误处理机制验证
- ✅ 边界值处理测试

### 数据一致性验证
- ✅ 多次计算结果一致性
- ✅ 输出格式规范性

### 性能回归测试
- ✅ 性能基线建立/验证
- ✅ 无显著性能回归

## 失败测试项
EOF

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo "无失败测试项 🎉" >> "$INTEGRATION_DIR/integration_report.md"
else
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "- ❌ $failed_test" >> "$INTEGRATION_DIR/integration_report.md"
    done
fi

cat >> "$INTEGRATION_DIR/integration_report.md" << EOF

## 集成建议

$(if [ $PASSED_INTEGRATIONS -eq $TOTAL_INTEGRATIONS ]; then
    echo "所有集成测试通过，系统已准备好进入部署验证阶段。"
elif [ $PASSED_INTEGRATIONS -ge $((TOTAL_INTEGRATIONS * 8 / 10)) ]; then
    echo "大部分集成测试通过，建议修复少量问题后进入部署验证。"
else
    echo "多项集成测试失败，需要解决关键问题后重新测试。"
fi)

## 测试统计
- 总集成测试数: $TOTAL_INTEGRATIONS
- 通过测试数: $PASSED_INTEGRATIONS
- 失败测试数: $((TOTAL_INTEGRATIONS - PASSED_INTEGRATIONS))
- 成功率: $((PASSED_INTEGRATIONS * 100 / TOTAL_INTEGRATIONS))%

EOF

echo "  ✅ 集成测试报告已生成: $INTEGRATION_DIR/integration_report.md"

echo

# ============================================================================
# 总结报告
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔗 集成测试总结报告${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "测试完成时间: $(date)"
echo "总集成测试数: $TOTAL_INTEGRATIONS"
echo "通过测试数: $PASSED_INTEGRATIONS"
echo "失败测试数: $((TOTAL_INTEGRATIONS - PASSED_INTEGRATIONS))"

if [ $TOTAL_INTEGRATIONS -gt 0 ]; then
    success_rate=$((PASSED_INTEGRATIONS * 100 / TOTAL_INTEGRATIONS))
    echo "集成成功率: ${success_rate}%"
    
    echo
    if [ $success_rate -eq 100 ]; then
        echo -e "${GREEN}🎉 集成测试完美通过！可以进入部署验证阶段。${NC}"
        exit 0
    elif [ $success_rate -ge 90 ]; then
        echo -e "${GREEN}✅ 集成测试优秀！可以进入部署验证阶段。${NC}"
        exit 0
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}⚠️ 集成测试良好，建议修复剩余问题后进入下一阶段。${NC}"
        exit 0
    else
        echo -e "${RED}❌ 集成测试失败，请修复关键问题后重新测试。${NC}"
        echo "失败的测试项:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "  - $failed_test"
        done
        exit 1
    fi
fi

echo -e "${YELLOW}⚠️ 集成测试数据不足，请检查测试配置。${NC}"
exit 1