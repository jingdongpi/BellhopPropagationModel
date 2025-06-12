#!/bin/bash

# ============================================================================
# 性能测试脚本 - Performance Testing
# ============================================================================
# 功能：测试计算性能、内存使用、优化效果
# 使用：./scripts/02_performance_testing.sh
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="/home/shunli/AcousticProjects/BellhopPropagationModel"
cd "$PROJECT_ROOT"

# 性能测试结果目录
PERF_DIR="performance_results"
mkdir -p "$PERF_DIR"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}⚡ BellhopPropagationModel - 性能测试${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "测试时间: $(date)"
echo

# 性能基准定义（秒）
EXCELLENT_TIME=2.0
GOOD_TIME=5.0
ACCEPTABLE_TIME=15.0

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
PERFORMANCE_SCORES=()

performance_check() {
    local time=$1
    local test_name="$2"
    local file_size="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo "  📊 $test_name"
    echo "    计算时间: ${time}s"
    echo "    数据规模: $file_size"
    
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
test_performance "examples/input_minimal_test.json" "最小配置测试"
test_performance "examples/input_fast_test.json" "快速配置测试"  
test_performance "examples/input_interface_compliant.json" "接口规范测试"

echo

# ============================================================================
# 3. 内存使用分析
# ============================================================================
echo -e "${YELLOW}3. 🧠 内存使用分析${NC}"

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
# 4. 并发性能测试
# ============================================================================
echo -e "${YELLOW}4. 🔄 并发性能测试${NC}"

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
# 5. 优化效果对比
# ============================================================================
echo -e "${YELLOW}5. 📈 优化效果对比${NC}"

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
