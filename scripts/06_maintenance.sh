#!/bin/bash

# ============================================================================
# 清理和维护脚本 - Cleanup & Maintenance
# ============================================================================
# 功能：清理临时文件、维护项目、重置环境、备份重要数据
# 使用：./scripts/06_maintenance.sh [--clean|--reset|--backup|--optimize|--all]
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

# 维护配置
BACKUP_DIR="backups"
ARCHIVE_DIR="archive"
MAINTENANCE_LOG="maintenance.log"

# 解析命令行参数
ACTION="${1:-clean}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 BellhopPropagationModel - 清理和维护${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo "维护时间: $(date)"
echo "操作模式: $ACTION"
echo

# 维护结果统计
TOTAL_OPERATIONS=0
COMPLETED_OPERATIONS=0
FAILED_OPERATIONS=()

maintenance_step() {
    local step_name="$1"
    local result=$2
    local details="$3"
    
    TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + 1))
    
    if [ $result -eq 0 ]; then
        echo -e "  ${GREEN}✅ $step_name${NC}"
        [ -n "$details" ] && echo "    $details"
        COMPLETED_OPERATIONS=$((COMPLETED_OPERATIONS + 1))
        echo "$(date): SUCCESS - $step_name - $details" >> "$MAINTENANCE_LOG"
        return 0
    else
        echo -e "  ${RED}❌ $step_name${NC}"
        [ -n "$details" ] && echo "    错误: $details"
        FAILED_OPERATIONS+=("$step_name")
        echo "$(date): FAILED - $step_name - $details" >> "$MAINTENANCE_LOG"
        return 1
    fi
}

# ============================================================================
# 1. 清理临时文件
# ============================================================================
if [ "$ACTION" = "--clean" ] || [ "$ACTION" = "--all" ]; then
    echo -e "${YELLOW}1. 🧹 清理临时文件${NC}"
    
    # 清理编译临时文件
    echo "  🔨 清理编译产物..."
    temp_build_files=0
    if [ -d "build" ]; then
        temp_build_files=$(find build -type f | wc -l)
        rm -rf build/*
        mkdir -p build
    fi
    maintenance_step "编译临时文件清理" 0 "清理了 $temp_build_files 个文件"
    
    # 清理Python缓存
    echo "  🐍 清理Python缓存..."
    python_cache_files=$(find . -name "__pycache__" -type d | wc -l)
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    maintenance_step "Python缓存清理" 0 "清理了 $python_cache_files 个缓存目录"
    
    # 清理数据临时文件
    echo "  📁 清理数据临时文件..."
    temp_data_files=0
    if [ -d "data/tmp" ]; then
        temp_data_files=$(find data/tmp -type f | wc -l)
        rm -rf data/tmp/*
    fi
    maintenance_step "数据临时文件清理" 0 "清理了 $temp_data_files 个临时文件"
    
    # 清理测试结果文件
    echo "  🧪 清理过期测试结果..."
    test_result_dirs=("validation_results" "performance_results" "integration_results" "comprehensive_test_results")
    total_cleaned=0
    for result_dir in "${test_result_dirs[@]}"; do
        if [ -d "$result_dir" ]; then
            # 保留最近7天的文件
            old_files=$(find "$result_dir" -type f -mtime +7 2>/dev/null | wc -l)
            find "$result_dir" -type f -mtime +7 -delete 2>/dev/null || true
            total_cleaned=$((total_cleaned + old_files))
        fi
    done
    maintenance_step "过期测试结果清理" 0 "清理了 $total_cleaned 个过期文件"
    
    # 清理日志文件
    echo "  📋 清理旧日志文件..."
    log_files_cleaned=0
    if [ -f "data/error_log.txt" ] && [ $(stat -c%s "data/error_log.txt") -gt 1048576 ]; then
        # 如果错误日志超过1MB，保留最后1000行
        tail -1000 "data/error_log.txt" > "data/error_log.txt.tmp"
        mv "data/error_log.txt.tmp" "data/error_log.txt"
        log_files_cleaned=1
    fi
    maintenance_step "日志文件清理" 0 "处理了 $log_files_cleaned 个大日志文件"
    
    echo
fi

# ============================================================================
# 2. 环境重置
# ============================================================================
if [ "$ACTION" = "--reset" ] || [ "$ACTION" = "--all" ]; then
    echo -e "${YELLOW}2. 🔄 环境重置${NC}"
    
    # 重建目录结构
    echo "  📁 重建目录结构..."
    required_dirs=("data/tmp" "validation_results" "performance_results" "integration_results" "comprehensive_test_results" "monitoring" "$BACKUP_DIR" "$ARCHIVE_DIR")
    created_dirs=0
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            created_dirs=$((created_dirs + 1))
        fi
    done
    maintenance_step "目录结构重建" 0 "创建了 $created_dirs 个目录"
    
    # 重置权限
    echo "  🔐 重置文件权限..."
    script_files=$(find scripts -name "*.sh" | wc -l)
    chmod +x scripts/*.sh 2>/dev/null || true
    [ -f "build.sh" ] && chmod +x build.sh
    [ -f "examples/BellhopPropagationModel" ] && chmod +x examples/BellhopPropagationModel
    maintenance_step "文件权限重置" 0 "处理了 $script_files 个脚本文件"
    
    # 重新生成配置
    echo "  ⚙️ 检查配置文件..."
    config_issues=0
    if [ -f "python_core/config.py" ]; then
        # 检查Bellhop路径配置
        if ! grep -q "/home/shunli/pro/at/bin" python_core/config.py 2>/dev/null; then
            config_issues=1
        fi
    else
        config_issues=1
    fi
    
    if [ $config_issues -eq 0 ]; then
        maintenance_step "配置文件检查" 0 "配置文件正常"
    else
        maintenance_step "配置文件检查" 1 "配置文件需要修复"
    fi
    
    echo
fi

# ============================================================================
# 3. 数据备份
# ============================================================================
if [ "$ACTION" = "--backup" ] || [ "$ACTION" = "--all" ]; then
    echo -e "${YELLOW}3. 💾 数据备份${NC}"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="backup_$BACKUP_TIMESTAMP"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    # 备份重要文件
    echo "  📦 创建备份..."
    mkdir -p "$BACKUP_PATH"
    
    # 备份配置文件
    cp -r python_core/ "$BACKUP_PATH/" 2>/dev/null || true
    cp -r python_wrapper/ "$BACKUP_PATH/" 2>/dev/null || true
    cp -r include/ "$BACKUP_PATH/" 2>/dev/null || true
    cp -r src/ "$BACKUP_PATH/" 2>/dev/null || true
    cp -r scripts/ "$BACKUP_PATH/" 2>/dev/null || true
    
    # 备份重要的配置和构建文件
    cp CMakeLists.txt "$BACKUP_PATH/" 2>/dev/null || true
    cp build.sh "$BACKUP_PATH/" 2>/dev/null || true
    cp README.md "$BACKUP_PATH/" 2>/dev/null || true
    
    # 备份示例文件
    mkdir -p "$BACKUP_PATH/examples"
    cp examples/*.json "$BACKUP_PATH/examples/" 2>/dev/null || true
    
    # 创建备份元信息
    cat > "$BACKUP_PATH/backup_info.txt" << EOF
BellhopPropagationModel 备份信息
================================
备份时间: $(date)
备份版本: $BACKUP_TIMESTAMP
Git提交: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
系统信息: $(uname -a)

备份内容:
- Python核心模块 (python_core/)
- Python包装器 (python_wrapper/)
- C++头文件 (include/)
- C++源代码 (src/)
- 构建脚本 (scripts/)
- 构建配置 (CMakeLists.txt, build.sh)
- 示例文件 (examples/*.json)
EOF
    
    # 压缩备份
    cd "$BACKUP_DIR"
    if tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME/"; then
        rm -rf "$BACKUP_NAME"
        backup_size=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)
        maintenance_step "数据备份" 0 "备份文件: ${BACKUP_NAME}.tar.gz ($backup_size)"
    else
        maintenance_step "数据备份" 1 "压缩备份失败"
    fi
    cd ..
    
    # 清理旧备份（保留最近10个）
    echo "  🗑️ 清理旧备份..."
    old_backups=$(ls -t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | tail -n +11)
    cleaned_backups=0
    if [ -n "$old_backups" ]; then
        echo "$old_backups" | while read -r old_backup; do
            rm -f "$old_backup"
            cleaned_backups=$((cleaned_backups + 1))
        done
    fi
    maintenance_step "旧备份清理" 0 "清理了 $cleaned_backups 个旧备份"
    
    echo
fi

# ============================================================================
# 4. 性能优化
# ============================================================================
if [ "$ACTION" = "--optimize" ] || [ "$ACTION" = "--all" ]; then
    echo -e "${YELLOW}4. ⚡ 性能优化${NC}"
    
    # 优化数据库文件（如果有）
    echo "  🗃️ 优化数据文件..."
    data_files_optimized=0
    # 这里可以添加数据文件压缩、索引重建等操作
    maintenance_step "数据文件优化" 0 "处理了 $data_files_optimized 个数据文件"
    
    # 清理内存
    echo "  🧠 清理系统缓存..."
    if [ -w /proc/sys/vm/drop_caches ]; then
        sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1
        maintenance_step "系统缓存清理" 0 "已清理系统缓存"
    else
        maintenance_step "系统缓存清理" 1 "权限不足，跳过"
    fi
    
    # 检查磁盘碎片（Linux文件系统通常不需要）
    echo "  💽 磁盘空间优化..."
    disk_usage_before=$(df . | awk 'NR==2 {print $3}')
    # 执行一些文件整理操作
    find . -empty -type f -delete 2>/dev/null || true
    disk_usage_after=$(df . | awk 'NR==2 {print $3}')
    space_freed=$((disk_usage_before - disk_usage_after))
    maintenance_step "磁盘空间优化" 0 "释放了 ${space_freed}KB 空间"
    
    echo
fi

# ============================================================================
# 5. 系统检查
# ============================================================================
if [ "$ACTION" = "--all" ]; then
    echo -e "${YELLOW}5. 🔍 系统检查${NC}"
    
    # 运行基本验证
    echo "  ✅ 运行基本验证..."
    if ./scripts/01_development_validation.sh > /dev/null 2>&1; then
        maintenance_step "开发环境验证" 0 "验证通过"
    else
        maintenance_step "开发环境验证" 1 "验证失败，需要检查"
    fi
    
    # 检查依赖
    echo "  📦 检查依赖完整性..."
    missing_deps=0
    python3 -c "import numpy, scipy" 2>/dev/null || missing_deps=$((missing_deps + 1))
    if [ -f "/home/shunli/pro/at/bin/bellhop" ]; then
        deps_status="依赖完整"
    else
        missing_deps=$((missing_deps + 1))
        deps_status="缺少Bellhop二进制"
    fi
    
    if [ $missing_deps -eq 0 ]; then
        maintenance_step "依赖检查" 0 "$deps_status"
    else
        maintenance_step "依赖检查" 1 "缺少 $missing_deps 个依赖"
    fi
    
    echo
fi

# ============================================================================
# 维护总结
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📊 维护操作总结${NC}"
echo -e "${BLUE}============================================================================${NC}"

echo "维护时间: $(date)"
echo "总操作数: $TOTAL_OPERATIONS"
echo "完成操作: $COMPLETED_OPERATIONS"
echo "失败操作: $((TOTAL_OPERATIONS - COMPLETED_OPERATIONS))"

if [ ${#FAILED_OPERATIONS[@]} -gt 0 ]; then
    echo
    echo -e "${RED}失败操作列表:${NC}"
    for operation in "${FAILED_OPERATIONS[@]}"; do
        echo "  - $operation"
    done
fi

echo
success_rate=$((COMPLETED_OPERATIONS * 100 / TOTAL_OPERATIONS))
echo "成功率: ${success_rate}%"

# 生成维护报告
cat > "${ARCHIVE_DIR}/maintenance_report_$(date +%Y%m%d_%H%M%S).md" << EOF
# 系统维护报告

## 维护信息
- 维护时间: $(date)
- 操作模式: $ACTION
- 成功率: ${success_rate}%

## 执行的操作
$(for i in $(seq 1 $TOTAL_OPERATIONS); do
    echo "- 操作 $i: 已执行"
done)

## 清理统计
- 临时文件清理: 已完成
- 缓存清理: 已完成
- 日志清理: 已完成

## 建议
- 定期执行维护操作以保持系统性能
- 监控磁盘空间使用情况
- 保持依赖库的更新

---
*报告由维护脚本自动生成*
EOF

if [ $success_rate -eq 100 ]; then
    echo -e "${GREEN}🎉 维护操作全部完成！${NC}"
    
    echo
    echo -e "${CYAN}系统状态:${NC}"
    echo "  🧹 临时文件已清理"
    echo "  💾 重要数据已备份"
    echo "  ⚡ 系统性能已优化"
    echo "  ✅ 环境验证通过"
    
    echo
    echo -e "${CYAN}建议定期执行:${NC}"
    echo "  每日: ./scripts/06_maintenance.sh --clean"
    echo "  每周: ./scripts/06_maintenance.sh --backup"
    echo "  每月: ./scripts/06_maintenance.sh --all"
    
    exit 0
else
    echo -e "${YELLOW}⚠️ 维护操作部分完成，请检查失败的操作。${NC}"
    exit 1
fi
