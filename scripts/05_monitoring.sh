#!/bin/bash

# ============================================================================
# 监控和日志管理脚本 - Monitoring & Log Management
# ============================================================================
# 功能：监控系统状态、管理日志文件、生成监控报告
# 使用：./scripts/05_monitoring.sh [--status|--logs|--clean|--report|--watch]
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

# 监控配置
MONITOR_DIR="monitoring"
LOG_RETENTION_DAYS=30
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=80
ALERT_THRESHOLD_DISK=90

# 解析命令行参数
ACTION="${1:-status}"

# 创建监控目录
mkdir -p "$MONITOR_DIR"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 BellhopPropagationModel - 监控和日志管理${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "监控时间: $(date)"
echo "操作模式: $ACTION"
echo

# ============================================================================
# 1. 系统状态监控
# ============================================================================
if [ "$ACTION" = "--status" ] || [ "$ACTION" = "--report" ]; then
    echo -e "${YELLOW}1. 💻 系统状态监控${NC}"
    
    # CPU使用率
    cpu_usage=$(python3 -c "
import psutil
cpu_percent = psutil.cpu_percent(interval=1)
print(f'{cpu_percent:.1f}')
")
    
    echo "  🔥 CPU使用率: ${cpu_usage}%"
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        echo -e "    ${RED}⚠️ CPU使用率过高！${NC}"
    fi
    
    # 内存使用率
    memory_info=$(python3 -c "
import psutil
mem = psutil.virtual_memory()
used_percent = mem.percent
available_gb = mem.available / 1024 / 1024 / 1024
total_gb = mem.total / 1024 / 1024 / 1024
print(f'{used_percent:.1f} {available_gb:.1f} {total_gb:.1f}')
")
    
    memory_percent=$(echo $memory_info | awk '{print $1}')
    memory_available=$(echo $memory_info | awk '{print $2}')
    memory_total=$(echo $memory_info | awk '{print $3}')
    
    echo "  🧠 内存使用率: ${memory_percent}% (可用: ${memory_available}GB / ${memory_total}GB)"
    if (( $(echo "$memory_percent > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        echo -e "    ${RED}⚠️ 内存使用率过高！${NC}"
    fi
    
    # 磁盘使用率
    disk_usage=$(df -h . | awk 'NR==2 {print $5}' | tr -d '%')
    disk_available=$(df -h . | awk 'NR==2 {print $4}')
    
    echo "  💽 磁盘使用率: ${disk_usage}% (可用: ${disk_available})"
    if (( disk_usage > ALERT_THRESHOLD_DISK )); then
        echo -e "    ${RED}⚠️ 磁盘空间不足！${NC}"
    fi
    
    # 进程监控
    bellhop_processes=$(pgrep -f "bellhop" | wc -l)
    python_processes=$(pgrep -f "python.*bellhop" | wc -l)
    
    echo "  🔄 运行进程:"
    echo "    Bellhop进程: $bellhop_processes"
    echo "    Python相关进程: $python_processes"
    
    # 网络状态
    network_connections=$(netstat -an 2>/dev/null | grep ":80\|:443\|:8000" | wc -l)
    echo "    网络连接: $network_connections"
    
    echo
fi

# ============================================================================
# 2. 日志文件管理
# ============================================================================
if [ "$ACTION" = "--logs" ] || [ "$ACTION" = "--report" ]; then
    echo -e "${YELLOW}2. 📋 日志文件管理${NC}"
    
    # 统计日志文件
    log_dirs=("validation_results" "performance_results" "integration_results" "comprehensive_test_results" "data")
    total_log_files=0
    total_log_size=0
    
    echo "  📊 日志文件统计:"
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            file_count=$(find "$log_dir" -type f | wc -l)
            dir_size=$(du -sh "$log_dir" 2>/dev/null | cut -f1)
            echo "    $log_dir: $file_count 文件, $dir_size"
            total_log_files=$((total_log_files + file_count))
        fi
    done
    
    echo "  📈 总计: $total_log_files 个日志文件"
    
    # 检查错误日志
    if [ -f "data/error_log.txt" ]; then
        error_count=$(wc -l < "data/error_log.txt")
        echo "  🚨 错误日志: $error_count 条记录"
        
        if [ $error_count -gt 0 ]; then
            echo "    最近错误:"
            tail -3 "data/error_log.txt" | sed 's/^/      /'
        fi
    fi
    
    # 检查大文件
    echo "  📦 大文件检查 (>10MB):"
    find . -type f -size +10M 2>/dev/null | while read -r file; do
        file_size=$(du -sh "$file" | cut -f1)
        echo "    $file: $file_size"
    done
    
    echo
fi

# ============================================================================
# 3. 性能监控
# ============================================================================
if [ "$ACTION" = "--status" ] || [ "$ACTION" = "--report" ]; then
    echo -e "${YELLOW}3. ⚡ 性能监控${NC}"
    
    # 最近测试结果
    if [ -f "performance_results/performance_log.csv" ]; then
        echo "  📊 最近性能测试结果:"
        tail -5 "performance_results/performance_log.csv" | while IFS=',' read -r test_name calc_time data_points timestamp; do
            if [ -n "$test_name" ]; then
                echo "    $test_name: ${calc_time}s ($timestamp)"
            fi
        done
    else
        echo "  📊 无性能测试记录"
    fi
    
    # 系统负载
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
    echo "  ⚖️ 系统负载: $load_avg"
    
    echo
fi

# ============================================================================
# 4. 日志清理
# ============================================================================
if [ "$ACTION" = "--clean" ]; then
    echo -e "${YELLOW}4. 🧹 日志清理${NC}"
    
    echo "  🗑️ 清理超过 $LOG_RETENTION_DAYS 天的日志文件..."
    
    cleaned_count=0
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            echo "    清理目录: $log_dir"
            old_files=$(find "$log_dir" -type f -mtime +$LOG_RETENTION_DAYS 2>/dev/null)
            if [ -n "$old_files" ]; then
                echo "$old_files" | while read -r file; do
                    rm -f "$file"
                    cleaned_count=$((cleaned_count + 1))
                    echo "      删除: $file"
                done
            fi
        fi
    done
    
    # 压缩旧日志
    echo "  📦 压缩旧日志文件..."
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            find "$log_dir" -name "*.log" -mtime +7 -not -name "*.gz" 2>/dev/null | while read -r log_file; do
                gzip "$log_file"
                echo "      压缩: $log_file"
            done
        fi
    done
    
    # 清理临时文件
    echo "  🧽 清理临时文件..."
    if [ -d "data/tmp" ]; then
        find "data/tmp" -type f -mtime +1 -delete 2>/dev/null || true
        echo "      清理 data/tmp 目录"
    fi
    
    echo -e "  ${GREEN}✅ 清理完成${NC}"
    echo
fi

# ============================================================================
# 5. 监控报告生成
# ============================================================================
if [ "$ACTION" = "--report" ]; then
    echo -e "${YELLOW}5. 📄 生成监控报告${NC}"
    
    report_file="$MONITOR_DIR/monitoring_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# BellhopPropagationModel 监控报告

## 报告信息
- 生成时间: $(date)
- 系统: $(uname -a)
- 项目路径: $PROJECT_ROOT

## 系统资源状态

### CPU和内存
- CPU使用率: ${cpu_usage}%
- 内存使用率: ${memory_percent}%
- 可用内存: ${memory_available}GB / ${memory_total}GB
- 系统负载: $load_avg

### 磁盘空间
- 使用率: ${disk_usage}%
- 可用空间: ${disk_available}

### 进程状态
- Bellhop进程: $bellhop_processes 个
- Python相关进程: $python_processes 个
- 网络连接: $network_connections 个

## 日志文件统计
- 总日志文件数: $total_log_files
- 错误日志记录: $([ -f "data/error_log.txt" ] && wc -l < "data/error_log.txt" || echo "0") 条

## 性能数据
EOF

    # 添加性能数据
    if [ -f "performance_results/performance_log.csv" ]; then
        echo "### 最近性能测试" >> "$report_file"
        echo "| 测试名称 | 计算时间(s) | 数据点 | 测试时间 |" >> "$report_file"
        echo "|---------|-------------|--------|----------|" >> "$report_file"
        tail -5 "performance_results/performance_log.csv" | while IFS=',' read -r test_name calc_time data_points timestamp; do
            if [ -n "$test_name" ]; then
                echo "| $test_name | $calc_time | $data_points | $timestamp |" >> "$report_file"
            fi
        done
    fi
    
    cat >> "$report_file" << EOF

## 告警信息
EOF

    # 添加告警信息
    alerts=()
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        alerts+=("CPU使用率过高: ${cpu_usage}%")
    fi
    if (( $(echo "$memory_percent > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        alerts+=("内存使用率过高: ${memory_percent}%")
    fi
    if (( disk_usage > ALERT_THRESHOLD_DISK )); then
        alerts+=("磁盘空间不足: ${disk_usage}%")
    fi
    
    if [ ${#alerts[@]} -gt 0 ]; then
        for alert in "${alerts[@]}"; do
            echo "- ⚠️ $alert" >> "$report_file"
        done
    else
        echo "- ✅ 系统状态正常" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 建议
- 定期运行性能测试以监控系统性能
- 保持日志文件清理以节省磁盘空间
- 监控错误日志以及时发现问题
- 在高负载时考虑性能优化

---
*报告由监控脚本自动生成*
EOF
    
    echo -e "  ${GREEN}✅ 监控报告已生成: $report_file${NC}"
    echo
fi

# ============================================================================
# 6. 实时监控
# ============================================================================
if [ "$ACTION" = "--watch" ]; then
    echo -e "${YELLOW}6. 👁️ 实时监控模式${NC}"
    echo "按 Ctrl+C 退出监控"
    echo
    
    while true; do
        clear
        echo -e "${BLUE}============================================================================${NC}"
        echo -e "${BLUE}📊 BellhopPropagationModel - 实时监控 $(date)${NC}"
        echo -e "${BLUE}============================================================================${NC}"
        
        # 系统资源
        cpu_current=$(python3 -c "import psutil; print(f'{psutil.cpu_percent(interval=1):.1f}')")
        mem_current=$(python3 -c "import psutil; mem=psutil.virtual_memory(); print(f'{mem.percent:.1f}')")
        
        echo -e "${CYAN}系统资源:${NC}"
        echo "  CPU: ${cpu_current}%"
        echo "  内存: ${mem_current}%"
        
        # 进程状态
        bellhop_count=$(pgrep -f "bellhop" | wc -l)
        python_count=$(pgrep -f "python.*bellhop" | wc -l)
        
        echo -e "${CYAN}进程状态:${NC}"
        echo "  Bellhop: $bellhop_count"
        echo "  Python: $python_count"
        
        # 最近错误
        if [ -f "data/error_log.txt" ] && [ -s "data/error_log.txt" ]; then
            echo -e "${CYAN}最近错误:${NC}"
            tail -2 "data/error_log.txt" | sed 's/^/  /'
        fi
        
        echo
        echo "刷新间隔: 5秒 | 按 Ctrl+C 退出"
        
        sleep 5
    done
fi

# ============================================================================
# 监控总结
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 监控操作完成${NC}"
echo -e "${BLUE}============================================================================${NC}"

case $ACTION in
    "--status")
        echo "系统状态监控完成"
        ;;
    "--logs")
        echo "日志文件检查完成"
        ;;
    "--clean")
        echo "日志清理完成"
        ;;
    "--report")
        echo "监控报告生成完成"
        ;;
    "--watch")
        echo "实时监控已退出"
        ;;
    *)
        echo "使用方法: $0 [--status|--logs|--clean|--report|--watch]"
        ;;
esac

echo
echo -e "${CYAN}可用操作:${NC}"
echo "  --status : 检查系统状态"
echo "  --logs   : 管理日志文件"
echo "  --clean  : 清理旧日志"
echo "  --report : 生成监控报告"
echo "  --watch  : 实时监控模式"
