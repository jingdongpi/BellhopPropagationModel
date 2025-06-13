#!/bin/bash

# ============================================================================
# 性能测试脚本 v2.0 - Performance Testing with Multi-frequency & Ray Filtering
# ============================================================================
# 功能：测试计算性能、内存使用、多频率优化、射线筛选优化效果
# 更新：适配射线筛选优化和多频率批处理功能
# 使用：./scripts/02_performance_testing.sh
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

# 性能测试结果目录
PERF_DIR="performance_results"
mkdir -p "$PERF_DIR"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}⚡ BellhopPropagationModel v2.0 - 性能测试${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "测试时间: $(date)"
echo "测试版本: 2.0 (支持多频率批处理和射线筛选优化)"
echo

# 性能基准定义（秒）
EXCELLENT_TIME=2.0
GOOD_TIME=5.0
ACCEPTABLE_TIME=15.0
MULTI_FREQ_BASELINE=10.0  # 多频率测试基准
RAY_FILTERING_SPEEDUP=1.5  # 射线筛选加速比

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
PERFORMANCE_SCORES=()
OPTIMIZATION_GAINS=()

performance_check() {
    local time=$1
    local test_name="$2"
    local file_size="$3"
    local optimization_type="$4"  # 新增：优化类型
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo "  📊 $test_name"
    echo "    计算时间: ${time}s"
    echo "    数据规模: $file_size"
    [ -n "$optimization_type" ] && echo "    优化类型: $optimization_type"
    
    # 使用Python进行浮点数比较
    local score_result=$(python3 -c "
time = float('$time')
excellent = float('$EXCELLENT_TIME')
good = float('$GOOD_TIME')
acceptable = float('$ACCEPTABLE_TIME')

if time < excellent:
    print('100 EXCELLENT')
elif time < good:
    print('80 GOOD')
elif time < acceptable:
    print('60 ACCEPTABLE')
else:
    print('20 POOR')
")
    
    local score=$(echo $score_result | awk '{print $1}')
    local rating=$(echo $score_result | awk '{print $2}')
    
    case $rating in
        "EXCELLENT")
            echo -e "    ${GREEN}🏆 性能优秀${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "GOOD")
            echo -e "    ${GREEN}✅ 性能良好${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "ACCEPTABLE")
            echo -e "    ${YELLOW}⚠️ 性能可接受${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "POOR")
            echo -e "    ${RED}❌ 性能不达标${NC}"
            ;;
    esac
    
    PERFORMANCE_SCORES+=($score)
    echo "    评分: ${score}/100"
    echo
}

# 新增：优化效果检查函数
optimization_check() {
    local baseline_time=$1
    local optimized_time=$2
    local test_name="$3"
    local expected_speedup=$4
    
    echo "  🚀 $test_name 优化效果分析"
    echo "    基准时间: ${baseline_time}s"
    echo "    优化时间: ${optimized_time}s"
    
    local speedup=$(python3 -c "
baseline = float('$baseline_time')
optimized = float('$optimized_time')
expected = float('$expected_speedup')

if optimized > 0:
    actual_speedup = baseline / optimized
    gain_percent = ((baseline - optimized) / baseline) * 100
    print(f'{actual_speedup:.2f} {gain_percent:.1f}')
else:
    print('0.00 0.0')
")
    
    local actual_speedup=$(echo $speedup | awk '{print $1}')
    local gain_percent=$(echo $speedup | awk '{print $2}')
    
    echo "    实际加速比: ${actual_speedup}x"
    echo "    性能提升: ${gain_percent}%"
    
    local meets_expectation=$(python3 -c "
actual = float('$actual_speedup')
expected = float('$expected_speedup')
print('YES' if actual >= expected else 'NO')
")
    
    if [ "$meets_expectation" = "YES" ]; then
        echo -e "    ${GREEN}🎯 达到预期优化目标 (≥${expected_speedup}x)${NC}"
        OPTIMIZATION_GAINS+=("$gain_percent")
    else
        echo -e "    ${YELLOW}⚠️ 未达到预期优化目标 (期望≥${expected_speedup}x)${NC}"
        OPTIMIZATION_GAINS+=("0")
    fi
    echo
}

# ============================================================================
# 1. 系统资源检查
# ============================================================================
echo -e "${YELLOW}1. 💻 系统资源检查${NC}"

# CPU信息
cpu_cores=$(nproc)
echo "  CPU核心数: $cpu_cores"

# 内存信息 - 使用Python获取更可靠的内存信息
memory_info=$(python3 -c "
import psutil
mem = psutil.virtual_memory()
print(f'{mem.total//1024//1024//1024}G {mem.available//1024//1024//1024}G')
")
memory_total=$(echo $memory_info | awk '{print $1}')
memory_available=$(echo $memory_info | awk '{print $2}')
echo "  总内存: $memory_total"
echo "  可用内存: $memory_available"

# 磁盘空间
disk_available=$(df -h . | awk 'NR==2 {print $4}')
echo "  可用磁盘空间: $disk_available"

echo

# ============================================================================
# 2. 轻量级性能测试
# ============================================================================
echo -e "${YELLOW}2. 🚀 轻量级性能测试${NC}"

test_performance() {
    local test_file="$1"
    local test_name="$2"
    
    if [ ! -f "$test_file" ]; then
        echo -e "  ${RED}❌ 测试文件不存在: $test_file${NC}"
        return
    fi
    
    # 获取文件信息
    local file_size=$(du -h "$test_file" | cut -f1)
    local data_points=$(python3 -c "
import json
with open('$test_file', 'r') as f:
    data = json.load(f)
rd_count = len(data.get('receiver_depth', []))
rr_count = len(data.get('receiver_range', []))
print(f'{rd_count}x{rr_count}={rd_count*rr_count}')
" 2>/dev/null || echo "N/A")
    
    echo "  🧪 测试: $test_name"
    echo "    文件: $test_file"
    echo "    数据点: $data_points"
    
    # 执行性能测试
    local start_time=$(date +%s.%N)
    
    local result=$(python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, time
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

try:
    with open('$test_file', 'r') as f:
        test_data = json.load(f)
    
    start = time.time()
    result = solve_bellhop_propagation(test_data)
    end = time.time()
    
    result_data = json.loads(result) if isinstance(result, str) else result
    
    if result_data.get('error_code') == 200:
        print(f'SUCCESS {end-start:.2f}')
    else:
        print(f'FAILED {result_data.get(\"error_message\", \"未知错误\")}')
except Exception as e:
    print(f'ERROR {e}')
" 2>&1 | tail -1)
    
    local end_time=$(date +%s.%N)
    # 使用Python计算时间差
    local total_time=$(python3 -c "print(f'{$end_time - $start_time:.3f}')")
    
    if [[ $result == SUCCESS* ]]; then
        local calc_time=$(echo $result | awk '{print $2}')
        performance_check "$calc_time" "$test_name" "$file_size ($data_points 数据点)"
        
        # 保存结果到文件
        echo "$test_name,$calc_time,$data_points,$(date)" >> "$PERF_DIR/performance_log.csv"
    else
        echo -e "    ${RED}❌ 测试失败: $result${NC}"
        echo
    fi
}

# 执行不同复杂度的测试
test_performance "examples/input_small.json" "小规模计算"
test_performance "examples/input_medium.json" "中等规模计算"
test_performance "examples/input_ray_test.json" "射线追踪测试"

echo

# ============================================================================
# 3. 多频率批处理性能测试 (NEW)
# ============================================================================
echo -e "${YELLOW}3. 🎵 多频率批处理性能测试${NC}"

# 测试多频率性能
echo "  🔄 多频率批处理测试..."

# 单频率基准测试
single_freq_time=$(python3 -c "
import sys, json, time
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

test_input = {
    'freq': 100,
    'source_depth': 30,
    'receiver_depth': [10, 20, 30, 40],
    'receiver_range': [1000, 2000, 3000],
    'bathy': {'range': [0, 4000], 'depth': [100, 120]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50, 100], 'speed': [1520, 1510, 1500]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}],
    'options': {'is_propagation_pressure_output': True}
}

start_time = time.time()
try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    execution_time = time.time() - start_time
    
    if result_data.get('error_code') == 200:
        print(f'{execution_time:.3f}')
    else:
        print('ERROR')
except Exception as e:
    print('ERROR')
" 2>&1 | tail -1 | grep -E '^[0-9]+\.[0-9]+$' || echo "ERROR")

if [ "$single_freq_time" != "ERROR" ]; then
    echo "    单频率基准时间: ${single_freq_time}s"
    
    # 多频率批处理测试
    multi_freq_time=$(python3 -c "
import sys, json, time
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

test_input = {
    'freq': [100, 200, 500, 1000],  # 4个频率
    'source_depth': 30,
    'receiver_depth': [10, 20, 30, 40],
    'receiver_range': [1000, 2000, 3000],
    'bathy': {'range': [0, 4000], 'depth': [100, 120]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50, 100], 'speed': [1520, 1510, 1500]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}],
    'options': {'is_propagation_pressure_output': True}
}

start_time = time.time()
try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    execution_time = time.time() - start_time
    
    if result_data.get('error_code') == 200:
        print(f'{execution_time:.3f}')
    else:
        print('ERROR')
except Exception as e:
    print('ERROR')
" 2>&1 | tail -1 | grep -E '^[0-9]+\.[0-9]+$' || echo "ERROR")
    
    if [ "$multi_freq_time" != "ERROR" ]; then
        echo "    多频率批处理时间: ${multi_freq_time}s (4个频率)"
        
        # 计算预期时间（4个频率顺序执行）
        expected_time=$(python3 -c "print(f'{float(\"$single_freq_time\") * 4:.3f}')")
        echo "    预期顺序执行时间: ${expected_time}s"
        
        # 分析优化效果
        optimization_check "$expected_time" "$multi_freq_time" "多频率批处理" "2.0"
        
        performance_check "$multi_freq_time" "多频率批处理" "4频率x12数据点" "多频率优化"
    else
        echo -e "    ${RED}❌ 多频率测试失败${NC}"
    fi
else
    echo -e "    ${RED}❌ 单频率基准测试失败${NC}"
fi

echo

# ============================================================================
# 4. 射线筛选优化性能测试 (NEW)
# ============================================================================
echo -e "${YELLOW}4. 🎯 射线筛选优化性能测试${NC}"

echo "  🧮 射线筛选效果测试..."

# 执行射线筛选性能分析
ray_filtering_result=$(python3 -c "
import sys, json, time
sys.path.insert(0, '.')
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

# 使用射线追踪测试输入
test_input = {
    'freq': 250,
    'source_depth': 25,
    'receiver_depth': [15, 25, 35],
    'receiver_range': [2000, 4000],
    'bathy': {'range': [0, 5000], 'depth': [150, 180]},
    'sound_speed_profile': [{'range': 0, 'depth': [0, 50, 100, 150], 'speed': [1520, 1515, 1510, 1505]}],
    'sediment_info': [{'range': 0, 'sediment': {'p_speed': 1600, 's_speed': 200, 'density': 1.8, 'p_atten': 0.2, 's_atten': 1.0}}],
    'options': {'is_ray_output': True, 'is_propagation_pressure_output': False}
}

start_time = time.time()
try:
    result = solve_bellhop_propagation(json.dumps(test_input))
    result_data = json.loads(result)
    execution_time = time.time() - start_time
    
    if result_data.get('error_code') == 200:
        ray_count = len(result_data.get('ray_trace', []))
        print(f'SUCCESS {execution_time:.3f} {ray_count}')
    else:
        print('ERROR ERROR 0')
except Exception as e:
    print('ERROR ERROR 0')
" 2>/dev/null || echo "ERROR ERROR 0")

if [[ $ray_filtering_result == SUCCESS* ]]; then
    ray_time=$(echo $ray_filtering_result | awk '{print $2}')
    ray_count=$(echo $ray_filtering_result | awk '{print $3}')
    
    echo "    射线计算时间: ${ray_time}s"
    echo "    筛选后射线数: $ray_count"
    
    performance_check "$ray_time" "射线筛选计算" "6数据点,${ray_count}射线" "射线筛选优化"
    
    # 检查射线筛选统计信息
    echo "  📊 射线筛选统计分析..."
    python3 -c "
print('    检查射线筛选的优化效果...')
if $ray_count > 0:
    print(f'    ✅ 成功筛选出 $ray_count 条有效射线')
    if $ray_count < 1000:  # 合理的射线数量
        print('    ✅ 射线数量在合理范围内，筛选效果良好')
    else:
        print('    ⚠️ 射线数量较多，可能需要进一步优化筛选策略')
else:
    print('    ❌ 没有筛选出有效射线，需要检查筛选算法')
"
else
    echo -e "    ${RED}❌ 射线筛选测试失败${NC}"
fi

echo

# ============================================================================
# 5. 内存使用分析
# ============================================================================
echo -e "${YELLOW}5. 🧠 内存使用分析${NC}"

# 测试内存使用
echo "  📊 内存使用测试..."

memory_test_result=$(python3 -c "
import sys
sys.path.insert(0, '.')
sys.path.insert(0, 'python_wrapper')
import json, psutil, os
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

def get_memory_usage():
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024  # MB

try:
    with open('examples/input_fast_test.json', 'r') as f:
        test_data = json.load(f)
    
    # 测试前内存
    mem_before = get_memory_usage()
    
    # 执行计算
    result = solve_bellhop_propagation(test_data)
    
    # 测试后内存
    mem_after = get_memory_usage()
    
    print(f'MEMORY {mem_before:.1f} {mem_after:.1f} {mem_after-mem_before:.1f}')
    
except Exception as e:
    print(f'ERROR {e}')
" 2>&1 | tail -1)

if [[ $memory_test_result == MEMORY* ]]; then
    mem_before=$(echo $memory_test_result | awk '{print $2}')
    mem_after=$(echo $memory_test_result | awk '{print $3}')
    mem_delta=$(echo $memory_test_result | awk '{print $4}')
    
    echo "  计算前内存: ${mem_before} MB"
    echo "  计算后内存: ${mem_after} MB"
    echo "  内存增长: ${mem_delta} MB"
    
    # 使用Python进行内存评估
    mem_rating=$(python3 -c "
delta = float('$mem_delta')
if delta < 100:
    print('EXCELLENT')
elif delta < 200:
    print('GOOD')
else:
    print('POOR')
")
    
    case $mem_rating in
        "EXCELLENT")
            echo -e "  ${GREEN}✅ 内存使用优秀${NC}"
            ;;
        "GOOD")
            echo -e "  ${YELLOW}⚠️ 内存使用良好${NC}"
            ;;
        "POOR")
            echo -e "  ${RED}❌ 内存使用过高${NC}"
            ;;
    esac
else
    echo -e "  ${RED}❌ 内存测试失败: $memory_test_result${NC}"
fi

echo

# ============================================================================
# 6. 并发性能测试
# ============================================================================
echo -e "${YELLOW}6. 🔄 并发性能测试${NC}"

echo "  🔍 测试并发计算能力..."

concurrent_test() {
    local thread_count=$1
    
    echo "    测试 $thread_count 并发..."
    
    local start_time=$(date +%s.%N)
    
    # 创建临时脚本
    cat > /tmp/concurrent_test.py << EOF
import sys
sys.path.insert(0, '/home/shunli/AcousticProjects/BellhopPropagationModel')
sys.path.insert(0, '/home/shunli/AcousticProjects/BellhopPropagationModel/python_wrapper')
import json, time, threading
from python_wrapper.bellhop_wrapper import solve_bellhop_propagation

def worker():
    try:
        with open('/home/shunli/AcousticProjects/BellhopPropagationModel/examples/input_minimal_test.json', 'r') as f:
            test_data = json.load(f)
        result = solve_bellhop_propagation(test_data)
        result_data = json.loads(result) if isinstance(result, str) else result
        return result_data.get('error_code') == 200
    except:
        return False

threads = []
results = []

for i in range($thread_count):
    t = threading.Thread(target=lambda: results.append(worker()))
    threads.append(t)
    t.start()

for t in threads:
    t.join()

success_count = sum(results)
print(f'{success_count}/{$thread_count}')
EOF
    
    local result=$(python3 /tmp/concurrent_test.py 2>/dev/null || echo "0/$thread_count")
    local end_time=$(date +%s.%N)
    # 使用Python计算时间差
    local duration=$(python3 -c "print(f'{$end_time - $start_time:.3f}')")
    
    echo "    结果: $result 成功"
    echo "    耗时: ${duration}s"
    
    # 清理临时文件
    rm -f /tmp/concurrent_test.py
}

# 测试不同并发级别
concurrent_test 2
concurrent_test 4

echo

# ============================================================================
# 7. 优化效果对比
# ============================================================================
echo -e "${YELLOW}7. 📈 优化效果对比${NC}"

echo "  📊 生成性能报告..."

# 创建性能报告
cat > "$PERF_DIR/performance_report.md" << EOF
# Bellhop传播模型性能测试报告

## 测试概要
- 测试时间: $(date)
- 测试环境: Linux $(uname -r)
- CPU核心: $cpu_cores
- 总内存: $memory_total

## 性能测试结果

| 测试配置 | 计算时间(s) | 性能评级 | 数据规模 |
|---------|-------------|----------|----------|
EOF

# 读取性能日志并添加到报告
if [ -f "$PERF_DIR/performance_log.csv" ]; then
    while IFS=',' read -r test_name calc_time data_points timestamp; do
        # 使用Python进行性能评级
        rating=$(python3 -c "
time = float('$calc_time')
excellent = float('$EXCELLENT_TIME')
good = float('$GOOD_TIME') 
acceptable = float('$ACCEPTABLE_TIME')

if time < excellent:
    print('🏆 优秀')
elif time < good:
    print('✅ 良好')
elif time < acceptable:
    print('⚠️ 可接受')
else:
    print('❌ 不达标')
")
        echo "| $test_name | $calc_time | $rating | $data_points |" >> "$PERF_DIR/performance_report.md"
    done < "$PERF_DIR/performance_log.csv"
fi

cat >> "$PERF_DIR/performance_report.md" << EOF

## 性能基准
- 🏆 优秀: < ${EXCELLENT_TIME}s
- ✅ 良好: < ${GOOD_TIME}s  
- ⚠️ 可接受: < ${ACCEPTABLE_TIME}s
- ❌ 不达标: >= ${ACCEPTABLE_TIME}s

## 优化建议
$(if [ ${#PERFORMANCE_SCORES[@]} -gt 0 ]; then
    avg_score=$(( ($(IFS=+; echo "${PERFORMANCE_SCORES[*]}")) / ${#PERFORMANCE_SCORES[@]} ))
    if [ $avg_score -ge 90 ]; then
        echo "当前性能优秀，建议保持现有优化策略。"
    elif [ $avg_score -ge 70 ]; then
        echo "性能良好，可考虑进一步优化网格分辨率和声线数量。"
    else
        echo "性能需要改进，建议检查算法复杂度和内存使用。"
    fi
fi)

EOF

echo "  ✅ 性能报告已生成: $PERF_DIR/performance_report.md"

echo

# ============================================================================
# 总结报告
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 性能测试总结报告${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "测试完成时间: $(date)"
echo "总测试数: $TOTAL_TESTS"
echo "通过测试数: $PASSED_TESTS"

if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "性能通过率: ${success_rate}%"
    
    # 计算平均性能分数
    if [ ${#PERFORMANCE_SCORES[@]} -gt 0 ]; then
        avg_score=$(( ($(IFS=+; echo "${PERFORMANCE_SCORES[*]}")) / ${#PERFORMANCE_SCORES[@]} ))
        echo "平均性能分数: ${avg_score}/100"
        
        echo
        if [ $avg_score -ge 90 ]; then
            echo -e "${GREEN}🏆 性能测试优秀！可以进入集成测试阶段。${NC}"
            exit 0
        elif [ $avg_score -ge 70 ]; then
            echo -e "${YELLOW}✅ 性能测试良好，建议进行少量优化后进入下一阶段。${NC}"
            exit 0
        else
            echo -e "${RED}⚠️ 性能测试需要改进，建议优化后重新测试。${NC}"
            exit 1
        fi
    fi
fi

echo -e "${YELLOW}⚠️ 性能测试数据不足，请检查测试配置。${NC}"
exit 1
