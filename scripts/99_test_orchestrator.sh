#!/bin/bash

# ============================================================================
# 测试编排器 v2.0 - Test Orchestrator
# ============================================================================
# 功能：协调和编排所有测试脚本的执行，管理测试流程，生成综合报告
# 编排：开发验证 → 性能测试 → 集成测试 → 报告生成
# 更新：适配多频率批处理和射线筛选优化
# 使用：./scripts/99_test_orchestrator.sh [--quick|--full|--performance|--integration]
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
ORCHESTRATOR_RESULTS_DIR="orchestrator_test_results"
mkdir -p "$ORCHESTRATOR_RESULTS_DIR"

# 解析命令行参数
TEST_MODE="${1:-full}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🎭 Bellhop传播模型测试编排器 v2.0${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "编排开始时间: $(date)"
echo "项目路径: $PROJECT_ROOT"
echo "测试模式: $TEST_MODE"
echo "版本特性: 多频率批处理 + 射线筛选优化"
echo

# 测试结果统计
TOTAL_PHASES=0
PASSED_PHASES=0
FAILED_PHASES=()
PHASE_DETAILS=()

# 记录阶段结果
phase_result() {
    local phase_name="$1"
    local result=$2
    local details="$3"
    local start_time="$4"
    local end_time="$5"
    
    TOTAL_PHASES=$((TOTAL_PHASES + 1))
    
    # 计算持续时间
    local duration=""
    if [ -n "$start_time" ] && [ -n "$end_time" ]; then
        duration=$(python3 -c "print(f'{float(\"$end_time\") - float(\"$start_time\"):.2f}s')")
    fi
    
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $phase_name${NC}"
        [ -n "$details" ] && echo "    详情: $details"
        [ -n "$duration" ] && echo "    耗时: $duration"
        PASSED_PHASES=$((PASSED_PHASES + 1))
        PHASE_DETAILS+=("✅ $phase_name: $details ($duration)")
        return 0
    else
        echo -e "  ${RED}❌ $phase_name${NC}"
        [ -n "$details" ] && echo "    错误: $details"
        [ -n "$duration" ] && echo "    耗时: $duration"
        FAILED_PHASES+=("$phase_name")
        PHASE_DETAILS+=("❌ $phase_name: $details ($duration)")
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --quick        快速测试 (仅开发验证)"
    echo "  --full         完整测试 (所有阶段)"
    echo "  --performance  性能测试"
    echo "  --integration  集成测试"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "测试阶段说明:"
    echo "  1. 开发验证 - 环境检查、依赖验证、基础功能测试"
    echo "  2. 性能测试 - 计算性能、内存使用、优化效果验证"
    echo "  3. 集成测试 - 端到端测试、数据流验证、错误处理测试"
    echo ""
}

# 解析命令行参数
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# ============================================================================
# 测试阶段执行函数
# ============================================================================

run_development_validation() {
    echo -e "${YELLOW}=============== 阶段 1: 开发验证测试 ===============${NC}"
    local start_time=$(date +%s.%N)
    
    if ./scripts/01_development_validation.sh > "$ORCHESTRATOR_RESULTS_DIR/01_development_validation.log" 2>&1; then
        local end_time=$(date +%s.%N)
        phase_result "开发验证测试" 0 "环境和基础功能验证通过" "$start_time" "$end_time"
        return 0
    else
        local end_time=$(date +%s.%N)
        phase_result "开发验证测试" 1 "验证失败，查看日志文件" "$start_time" "$end_time"
        echo "    日志文件: $ORCHESTRATOR_RESULTS_DIR/01_development_validation.log"
        return 1
    fi
}

run_performance_testing() {
    echo -e "${YELLOW}=============== 阶段 2: 性能测试 ===============${NC}"
    local start_time=$(date +%s.%N)
    
    if ./scripts/02_performance_testing.sh > "$ORCHESTRATOR_RESULTS_DIR/02_performance_testing.log" 2>&1; then
        local end_time=$(date +%s.%N)
        phase_result "性能测试" 0 "性能基准测试通过" "$start_time" "$end_time"
        return 0
    else
        local end_time=$(date +%s.%N)
        phase_result "性能测试" 1 "性能测试失败，查看日志文件" "$start_time" "$end_time"
        echo "    日志文件: $ORCHESTRATOR_RESULTS_DIR/02_performance_testing.log"
        return 1
    fi
}

run_integration_testing() {
    echo -e "${YELLOW}=============== 阶段 3: 集成测试 ===============${NC}"
    local start_time=$(date +%s.%N)
    
    if ./scripts/03_integration_testing.sh > "$ORCHESTRATOR_RESULTS_DIR/03_integration_testing.log" 2>&1; then
        local end_time=$(date +%s.%N)
        phase_result "集成测试" 0 "系统集成验证通过" "$start_time" "$end_time"
        return 0
    else
        local end_time=$(date +%s.%N)
        phase_result "集成测试" 1 "集成测试失败，查看日志文件" "$start_time" "$end_time"
        echo "    日志文件: $ORCHESTRATOR_RESULTS_DIR/03_integration_testing.log"
        return 1
    fi
}

# ============================================================================
# 主测试流程编排
# ============================================================================

echo -e "${PURPLE}🚀 开始测试编排流程...${NC}"
echo

case "$TEST_MODE" in
    "--quick"|"quick")
        echo -e "${CYAN}⚡ 快速测试模式 - 仅执行开发验证${NC}"
        run_development_validation
        ;;
    "--performance"|"performance")
        echo -e "${CYAN}🏃 性能测试模式${NC}"
        run_performance_testing
        ;;
    "--integration"|"integration")
        echo -e "${CYAN}🔗 集成测试模式${NC}"
        run_integration_testing
        ;;
    "--full"|"full"|"")
        echo -e "${CYAN}🎯 完整测试模式 - 所有阶段${NC}"
        echo
        
        # 阶段 1: 开发验证
        if ! run_development_validation; then
            echo -e "${RED}⚠️ 开发验证失败，但继续进行其他测试${NC}"
        fi
        echo
        
        # 阶段 2: 性能测试
        if ! run_performance_testing; then
            echo -e "${RED}⚠️ 性能测试失败，可能影响生产性能${NC}"
        fi
        echo
        
        # 阶段 3: 集成测试
        if ! run_integration_testing; then
            echo -e "${RED}⚠️ 集成测试失败，需要检查系统集成${NC}"
        fi
        ;;
    *)
        echo -e "${RED}❌ 未知的测试模式: $TEST_MODE${NC}"
        show_help
        exit 1
        ;;
esac

echo
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 测试编排总结报告${NC}"
echo -e "${BLUE}============================================================================${NC}"

# 生成详细报告
REPORT_FILE="$ORCHESTRATOR_RESULTS_DIR/orchestrator_report.txt"
{
    echo "BellhopPropagationModel v2.0 测试编排报告"
    echo "========================================"
    echo "报告生成时间: $(date)"
    echo "测试模式: $TEST_MODE"
    echo "项目路径: $PROJECT_ROOT"
    echo ""
    echo "测试统计:"
    echo "  总阶段数: $TOTAL_PHASES"
    echo "  成功阶段: $PASSED_PHASES"
    echo "  失败阶段: $((TOTAL_PHASES - PASSED_PHASES))"
    echo ""
    
    if [ ${#FAILED_PHASES[@]} -gt 0 ]; then
        echo "失败的阶段:"
        for failed_phase in "${FAILED_PHASES[@]}"; do
            echo "  - $failed_phase"
        done
        echo ""
    fi
    
    echo "详细结果:"
    for detail in "${PHASE_DETAILS[@]}"; do
        echo "  $detail"
    done
    echo ""
    
    echo "日志文件位置:"
    echo "  结果目录: $ORCHESTRATOR_RESULTS_DIR/"
    ls -la "$ORCHESTRATOR_RESULTS_DIR/"
} > "$REPORT_FILE"

echo "📋 测试编排统计:"
echo "  总阶段数: $TOTAL_PHASES"
echo "  成功阶段: $PASSED_PHASES"
echo "  失败阶段: $((TOTAL_PHASES - PASSED_PHASES))"

if [ ${#FAILED_PHASES[@]} -gt 0 ]; then
    echo
    echo "❌ 失败的阶段:"
    for failed_phase in "${FAILED_PHASES[@]}"; do
        echo "  - $failed_phase"
    done
fi

echo
echo "📁 结果文件:"
echo "  编排报告: $REPORT_FILE"
echo "  结果目录: $ORCHESTRATOR_RESULTS_DIR/"

# 计算成功率
if [ $TOTAL_PHASES -gt 0 ]; then
    success_rate=$(python3 -c "print(round($PASSED_PHASES * 100 / $TOTAL_PHASES, 1))")
    
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
else
    echo -e "${YELLOW}⚠️  没有执行任何测试阶段${NC}"
    exit_code=1
fi

echo
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}测试编排完成 - $(date)${NC}"
echo -e "${BLUE}============================================================================${NC}"

exit $exit_code
