#!/bin/bash

# ============================================================================
# Bellhop传播模型综合测试脚本
# ============================================================================
# 功能：编译二进制、运行Python版本、运行二进制版本、比较结果
# 使用：./run_comprehensive_test.sh
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

# 测试结果目录
TEST_RESULTS_DIR="test_results"
mkdir -p "$TEST_RESULTS_DIR"

# 测试配置
TEST_FILES=(
    "examples/input_small.json"
    "examples/input_medium.json"
    "examples/input_large.json"
)

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 Bellhop传播模型综合测试${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "测试时间: $(date)"
echo "项目路径: $PROJECT_ROOT"
echo "测试文件数量: ${#TEST_FILES[@]}"
echo

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=()

test_result() {
    local test_name="$1"
    local result=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}❌ $test_name${NC}"
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# ============================================================================
# 1. 环境检查和编译
# ============================================================================
echo -e "${YELLOW}1. 🔍 环境检查和编译${NC}"

echo "  检查Python环境..."
python3 --version
test_result "Python环境检查" $?

echo "  检查Python模块..."
python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
sys.path.insert(0, 'python_core')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation
print('Python模块导入成功')
" 2>&1
test_result "Python模块检查" $?

echo "  编译二进制文件..."
./build.sh > "$TEST_RESULTS_DIR/build.log" 2>&1
build_result=$?
if [ $build_result -eq 0 ]; then
    echo "    编译成功"
else
    echo "    编译失败，查看日志: $TEST_RESULTS_DIR/build.log"
fi
test_result "二进制编译" $build_result

echo "  检查生成的文件..."
if [ -f "examples/BellhopPropagationModel" ] && [ -x "examples/BellhopPropagationModel" ]; then
    echo "    二进制文件存在且可执行"
    file_check=0
else
    echo "    二进制文件不存在或不可执行"
    file_check=1
fi
test_result "二进制文件检查" $file_check

echo

# ============================================================================
# 2. 批量测试和比较
# ============================================================================
echo -e "${YELLOW}2. 🧪 批量测试和比较${NC}"

# 创建比较脚本
cat > "$TEST_RESULTS_DIR/compare_results.py" << 'EOF'
#!/usr/bin/env python3
"""
比较Python版本和二进制版本的输出结果
"""

import json
import numpy as np
import sys
import os

def load_json_safe(file_path):
    """安全加载JSON文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"无法加载文件 {file_path}: {e}")
        return None

def compare_arrays(arr1, arr2, name, tolerance=1e-10):
    """比较两个数组"""
    if arr1 is None or arr2 is None:
        return False, f"{name}: 其中一个数组为None"
    
    try:
        np_arr1 = np.array(arr1)
        np_arr2 = np.array(arr2)
        
        if np_arr1.shape != np_arr2.shape:
            return False, f"{name}: 形状不匹配 {np_arr1.shape} vs {np_arr2.shape}"
        
        if np.allclose(np_arr1, np_arr2, rtol=tolerance, atol=tolerance):
            max_diff = np.max(np.abs(np_arr1 - np_arr2))
            return True, f"{name}: 相同 (最大差异: {max_diff:.2e})"
        else:
            max_diff = np.max(np.abs(np_arr1 - np_arr2))
            mean_diff = np.mean(np.abs(np_arr1 - np_arr2))
            return False, f"{name}: 不同 (最大差异: {max_diff:.2e}, 平均差异: {mean_diff:.2e})"
    
    except Exception as e:
        return False, f"{name}: 比较出错 - {e}"

def compare_results(python_file, binary_file, test_name):
    """比较两个结果文件"""
    print(f"\n{'='*60}")
    print(f"比较测试: {test_name}")
    print(f"{'='*60}")
    
    # 加载文件
    python_data = load_json_safe(python_file)
    binary_data = load_json_safe(binary_file)
    
    if python_data is None or binary_data is None:
        print("❌ 无法加载比较文件")
        return False
    
    # 检查错误码
    python_error = python_data.get('error_code', -1)
    binary_error = binary_data.get('error_code', -1)
    
    print(f"Python版本错误码: {python_error}")
    print(f"二进制版本错误码: {binary_error}")
    
    if python_error != 200 or binary_error != 200:
        print("❌ 其中一个版本计算失败")
        if python_error != 200:
            print(f"  Python错误: {python_data.get('error_message', '未知')}")
        if binary_error != 200:
            print(f"  二进制错误: {binary_data.get('error_message', '未知')}")
        return False
    
    # 比较各个字段
    comparisons = []
    
    # 比较接收深度
    success, msg = compare_arrays(
        python_data.get('receiver_depth'),
        binary_data.get('receiver_depth'),
        "接收深度"
    )
    comparisons.append((success, msg))
    
    # 比较接收距离
    success, msg = compare_arrays(
        python_data.get('receiver_range'),
        binary_data.get('receiver_range'),
        "接收距离"
    )
    comparisons.append((success, msg))
    
    # 比较传输损失
    success, msg = compare_arrays(
        python_data.get('transmission_loss'),
        binary_data.get('transmission_loss'),
        "传输损失"
    )
    comparisons.append((success, msg))
    
    # 输出比较结果
    all_passed = True
    for success, msg in comparisons:
        status = "✅" if success else "❌"
        print(f"  {status} {msg}")
        if not success:
            all_passed = False
    
    # 数据统计
    if all_passed:
        tl_data = np.array(python_data.get('transmission_loss', []))
        if tl_data.size > 0:
            print(f"\n📊 数据统计:")
            print(f"  数据形状: {tl_data.shape}")
            print(f"  数据范围: {np.min(tl_data):.1f} - {np.max(tl_data):.1f} dB")
            print(f"  平均值: {np.mean(tl_data):.1f} dB")
    
    return all_passed

def main():
    if len(sys.argv) != 4:
        print("用法: python3 compare_results.py <python_output> <binary_output> <test_name>")
        sys.exit(1)
    
    python_file = sys.argv[1]
    binary_file = sys.argv[2]
    test_name = sys.argv[3]
    
    success = compare_results(python_file, binary_file, test_name)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$TEST_RESULTS_DIR/compare_results.py"

# 执行测试
for test_file in "${TEST_FILES[@]}"; do
    if [ ! -f "$test_file" ]; then
        echo "  ⚠️  测试文件不存在: $test_file"
        continue
    fi
    
    # 提取文件名（不含路径和扩展名）
    base_name=$(basename "$test_file" .json)
    test_name=$(echo "$base_name" | sed 's/input_//')
    
    echo -e "  ${CYAN}🧪 测试: $test_name${NC}"
    
    # 定义输出文件名
    python_output="$TEST_RESULTS_DIR/output_python_${test_name}.json"
    binary_output="$TEST_RESULTS_DIR/output_binary_${test_name}.json"
    
    # 运行Python版本
    echo "    运行Python版本..."
    cd examples
    python3 test_python_wrapper.py "$PROJECT_ROOT/$test_file" "$PROJECT_ROOT/$python_output" > "$PROJECT_ROOT/$TEST_RESULTS_DIR/python_${test_name}.log" 2>&1
    python_result=$?
    cd ..
    
    if [ $python_result -eq 0 ] && [ -f "$python_output" ]; then
        echo "      Python版本成功"
    else
        echo "      Python版本失败，查看日志: $TEST_RESULTS_DIR/python_${test_name}.log"
        test_result "Python版本-$test_name" 1
        continue
    fi
    
    # 运行二进制版本
    echo "    运行二进制版本..."
    cd examples
    ./BellhopPropagationModel "$PROJECT_ROOT/$test_file" "$PROJECT_ROOT/$binary_output" > "$PROJECT_ROOT/$TEST_RESULTS_DIR/binary_${test_name}.log" 2>&1
    binary_result=$?
    cd ..
    
    if [ $binary_result -eq 0 ] && [ -f "$binary_output" ]; then
        echo "      二进制版本成功"
    else
        echo "      二进制版本失败，查看日志: $TEST_RESULTS_DIR/binary_${test_name}.log"
        test_result "二进制版本-$test_name" 1
        continue
    fi
    
    # 比较结果
    echo "    比较结果..."
    python3 "$TEST_RESULTS_DIR/compare_results.py" "$python_output" "$binary_output" "$test_name" > "$TEST_RESULTS_DIR/compare_${test_name}.log" 2>&1
    compare_result=$?
    
    if [ $compare_result -eq 0 ]; then
        echo "      结果一致 ✅"
        test_result "结果比较-$test_name" 0
    else
        echo "      结果不一致 ❌，查看详情: $TEST_RESULTS_DIR/compare_${test_name}.log"
        test_result "结果比较-$test_name" 1
    fi
    
    echo
done

# ============================================================================
# 3. 性能比较
# ============================================================================
echo -e "${YELLOW}3. ⏱️ 性能比较${NC}"

performance_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo "  🏃 性能测试: $test_name"
    
    # Python版本性能测试
    echo "    测试Python版本性能..."
    cd examples
    start_time=$(date +%s.%N)
    python3 test_python_wrapper.py "$PROJECT_ROOT/$test_file" "/tmp/perf_python.json" > /dev/null 2>&1
    python_result=$?
    end_time=$(date +%s.%N)
    python_time=$(python3 -c "print(f'{$end_time - $start_time:.3f}')")
    cd ..
    
    # 二进制版本性能测试
    echo "    测试二进制版本性能..."
    cd examples
    start_time=$(date +%s.%N)
    ./BellhopPropagationModel "$PROJECT_ROOT/$test_file" "/tmp/perf_binary.json" > /dev/null 2>&1
    binary_result=$?
    end_time=$(date +%s.%N)
    binary_time=$(python3 -c "print(f'{$end_time - $start_time:.3f}')")
    cd ..
    
    # 输出结果
    if [ $python_result -eq 0 ] && [ $binary_result -eq 0 ]; then
        echo "    Python版本: ${python_time}秒"
        echo "    二进制版本: ${binary_time}秒"
        
        # 计算性能比
        speedup=$(python3 -c "
try:
    ratio = float('$python_time') / float('$binary_time') if float('$binary_time') > 0 else 0
    print(f'{ratio:.1f}')
except:
    print('N/A')
")
        echo "    性能比: ${speedup}x (二进制版本相对Python版本)"
    else
        echo "    性能测试失败"
    fi
    
    # 清理临时文件
    rm -f /tmp/perf_python.json /tmp/perf_binary.json
    
    echo
}

# 选择一个文件进行性能测试
if [ ${#TEST_FILES[@]} -gt 0 ]; then
    performance_test "${TEST_FILES[1]}" "medium_regular_test"
fi

# ============================================================================
# 4. 测试总结
# ============================================================================
echo -e "${YELLOW}4. 📋 测试总结${NC}"

echo "总测试数: $TOTAL_TESTS"
echo "成功测试: $PASSED_TESTS"
echo "失败测试: $((TOTAL_TESTS - PASSED_TESTS))"

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo
    echo "失败的测试:"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "  - $failed_test"
    done
fi

echo
echo "测试结果文件保存在: $TEST_RESULTS_DIR/"
echo "主要输出文件:"
ls -la "$TEST_RESULTS_DIR"/ | grep "output_" | head -5

# 计算成功率
success_rate=$(python3 -c "print(f'{$PASSED_TESTS * 100 / $TOTAL_TESTS:.1f}')")
echo
if [ $(python3 -c "print(1 if $success_rate >= 80 else 0)") -eq 1 ]; then
    echo -e "${GREEN}🎉 测试成功率: ${success_rate}% - 非常好！${NC}"
    exit_code=0
elif [ $(python3 -c "print(1 if $success_rate >= 60 else 0)") -eq 1 ]; then
    echo -e "${YELLOW}⚠️  测试成功率: ${success_rate}% - 还不错，但有改进空间${NC}"
    exit_code=0
else
    echo -e "${RED}❌ 测试成功率: ${success_rate}% - 需要修复问题${NC}"
    exit_code=1
fi

echo
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}测试完成 - $(date)${NC}"
echo -e "${BLUE}============================================================================${NC}"

exit $exit_code
