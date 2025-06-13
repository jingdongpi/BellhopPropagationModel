#!/bin/bash

# ============================================================================
# BellhopPropagationModel 脚本管理器 - Script Manager
# ============================================================================
# 功能：统一管理所有项目脚本、提供交互式菜单、快速执行常用操作
# 使用：./scripts_manager.sh 或直接运行显示菜单
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="/home/shunli/AcousticProjects/BellhopPropagationModel"
cd "$PROJECT_ROOT"

# 脚本路径
SCRIPTS_DIR="scripts"

# 显示项目logo和信息
show_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "============================================================================"
    echo "🔊 BellhopPropagationModel v2.0 - 脚本管理器"
    echo "============================================================================"
    echo -e "${NC}"
    echo -e "${CYAN}项目特性: 多频率批处理 + 射线筛选优化 + 完整Python接口${NC}"
    echo -e "${CYAN}项目路径: $PROJECT_ROOT${NC}"
    echo -e "${CYAN}管理时间: $(date)${NC}"
    echo
}

# 显示脚本状态
show_script_status() {
    echo -e "${YELLOW}📋 脚本状态检查:${NC}"
    
    scripts=(
        "00_environment_setup.sh:环境配置"
        "01_development_validation.sh:开发验证"
        "02_performance_testing.sh:性能测试"
        "03_integration_testing.sh:集成测试"
        "04_deployment.sh:部署脚本"
        "05_monitoring.sh:监控管理"
        "06_maintenance.sh:清理维护"
        "99_test_orchestrator.sh:测试编排器"
    )
    
    for script_info in "${scripts[@]}"; do
        script_name=${script_info%:*}
        script_desc=${script_info#*:}
        script_path="$SCRIPTS_DIR/$script_name"
        
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            echo -e "  ${GREEN}✅ $script_desc${NC} ($script_name)"
        elif [ -f "$script_path" ]; then
            echo -e "  ${YELLOW}⚠️ $script_desc${NC} ($script_name) - 需要执行权限"
        else
            echo -e "  ${RED}❌ $script_desc${NC} ($script_name) - 文件缺失"
        fi
    done
    echo
}

# 显示主菜单
show_main_menu() {
    echo -e "${PURPLE}${BOLD}📋 主菜单 - 请选择操作:${NC}"
    echo
    echo -e "${CYAN}🔧 环境和配置:${NC}"
    echo "  1) 环境配置检查         (00_environment_setup.sh)"
    echo "  2) 开发环境验证         (01_development_validation.sh)"
    echo
    echo -e "${CYAN}🧪 测试操作:${NC}"
    echo "  3) 性能测试            (02_performance_testing.sh)"
    echo "  4) 集成测试            (03_integration_testing.sh)"
    echo "  5) 测试编排器           (99_test_orchestrator.sh)"
    echo
    echo -e "${CYAN}📦 部署和运维:${NC}"
    echo "  6) 项目部署            (04_deployment.sh)"
    echo "  7) 系统监控            (05_monitoring.sh)"
    echo "  8) 清理维护            (06_maintenance.sh)"
    echo
    echo -e "${CYAN}🚀 快速操作:${NC}"
    echo "  q) 快速验证 (环境检查+基础测试)"
    echo "  f) 完整测试 (所有测试阶段)"
    echo "  c) 清理系统 (清理+维护)"
    echo "  m) 监控状态 (系统监控)"
    echo
    echo -e "${CYAN}ℹ️ 其他:${NC}"
    echo "  h) 显示帮助"
    echo "  s) 脚本状态检查"
    echo "  0) 退出"
    echo
}

# 显示帮助信息
show_help() {
    echo -e "${YELLOW}📖 脚本使用说明:${NC}"
    echo
    echo -e "${BOLD}各脚本功能说明:${NC}"
    echo
    echo -e "${GREEN}00_environment_setup.sh${NC} - 环境配置"
    echo "  检查和配置开发环境、安装依赖、设置权限"
    echo "  使用: ./scripts/00_environment_setup.sh [--check|--install|--clean]"
    echo
    echo -e "${GREEN}01_development_validation.sh${NC} - 开发验证"
    echo "  验证开发环境、代码质量、基础功能、射线筛选优化"
    echo "  使用: ./scripts/01_development_validation.sh"
    echo
    echo -e "${GREEN}02_performance_testing.sh${NC} - 性能测试"
    echo "  测试计算性能、多频率优化、射线筛选效果"
    echo "  使用: ./scripts/02_performance_testing.sh"
    echo
    echo -e "${GREEN}03_integration_testing.sh${NC} - 集成测试"
    echo "  测试功能集成、端到端流程、数据流验证"
    echo "  使用: ./scripts/03_integration_testing.sh"
    echo
    echo -e "${GREEN}04_deployment.sh${NC} - 部署脚本"
    echo "  构建项目、打包部署、生成发布版本"
    echo "  使用: ./scripts/04_deployment.sh [--build|--package|--install|--release]"
    echo
    echo -e "${GREEN}05_monitoring.sh${NC} - 监控管理"
    echo "  监控系统状态、管理日志、生成报告"
    echo "  使用: ./scripts/05_monitoring.sh [--status|--logs|--clean|--report|--watch]"
    echo
    echo -e "${GREEN}06_maintenance.sh${NC} - 清理维护"
    echo "  清理临时文件、维护项目、备份数据"
    echo "  使用: ./scripts/06_maintenance.sh [--clean|--reset|--backup|--optimize|--all]"
    echo
    echo -e "${GREEN}99_test_orchestrator.sh${NC} - 测试编排器"
    echo "  协调执行所有测试脚本、管理测试流程、生成综合报告"
    echo "  使用: ./scripts/99_test_orchestrator.sh [--quick|--full|--performance|--integration]"
    echo
    echo -e "${BOLD}推荐工作流程:${NC}"
    echo "1. 首次使用: 00_environment_setup.sh --install"
    echo "2. 开发验证: 01_development_validation.sh"
    echo "3. 性能测试: 02_performance_testing.sh"
    echo "4. 集成测试: 03_integration_testing.sh"
    echo "5. 部署发布: 04_deployment.sh --package"
    echo "6. 定期维护: 06_maintenance.sh --all"
    echo
}

# 执行脚本
execute_script() {
    local script_name="$1"
    local script_args="$2"
    local script_desc="$3"
    
    local script_path="$SCRIPTS_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}❌ 错误: 脚本文件不存在: $script_path${NC}"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        echo -e "${YELLOW}⚠️ 设置执行权限...${NC}"
        chmod +x "$script_path"
    fi
    
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}🚀 执行: $script_desc${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${CYAN}脚本: $script_name${NC}"
    echo -e "${CYAN}参数: $script_args${NC}"
    echo -e "${CYAN}时间: $(date)${NC}"
    echo
    
    if [ -n "$script_args" ]; then
        "$script_path" $script_args
    else
        "$script_path"
    fi
    
    local exit_code=$?
    echo
    echo -e "${BLUE}============================================================================${NC}"
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ $script_desc 执行成功${NC}"
    else
        echo -e "${RED}❌ $script_desc 执行失败 (退出码: $exit_code)${NC}"
    fi
    echo -e "${BLUE}============================================================================${NC}"
    echo
    
    read -p "按 Enter 键继续..." -r
    return $exit_code
}

# 快速操作函数
quick_validation() {
    echo -e "${CYAN}🚀 执行快速验证...${NC}"
    execute_script "00_environment_setup.sh" "--check" "环境检查"
    if [ $? -eq 0 ]; then
        execute_script "01_development_validation.sh" "" "开发验证"
    fi
}

full_testing() {
    echo -e "${CYAN}🧪 执行完整测试编排...${NC}"
    execute_script "99_test_orchestrator.sh" "--full" "完整测试编排套件"
}

system_cleanup() {
    echo -e "${CYAN}🧹 执行系统清理...${NC}"
    execute_script "06_maintenance.sh" "--clean" "系统清理"
    execute_script "05_monitoring.sh" "--clean" "日志清理"
}

monitor_status() {
    echo -e "${CYAN}📊 显示系统监控...${NC}"
    execute_script "05_monitoring.sh" "--status" "系统状态监控"
}

# 主循环
main_loop() {
    while true; do
        show_banner
        show_script_status
        show_main_menu
        
        echo -ne "${BOLD}请选择操作 [1-8/q/f/c/m/h/s/0]: ${NC}"
        read -r choice
        echo
        
        case $choice in
            1)
                echo -e "${CYAN}选择环境配置操作:${NC}"
                echo "  1) 检查环境 (--check)"
                echo "  2) 安装依赖 (--install)"
                echo "  3) 清理环境 (--clean)"
                echo -ne "请选择 [1-3]: "
                read -r env_choice
                case $env_choice in
                    1) execute_script "00_environment_setup.sh" "--check" "环境检查" ;;
                    2) execute_script "00_environment_setup.sh" "--install" "依赖安装" ;;
                    3) execute_script "00_environment_setup.sh" "--clean" "环境清理" ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                ;;
            2)
                execute_script "01_development_validation.sh" "" "开发环境验证"
                ;;
            3)
                execute_script "02_performance_testing.sh" "" "性能测试"
                ;;
            4)
                execute_script "03_integration_testing.sh" "" "集成测试"
                ;;
            5)
                echo -e "${CYAN}选择测试编排模式:${NC}"
                echo "  1) 快速测试 (--quick)"
                echo "  2) 完整测试 (--full)"
                echo "  3) 性能专项 (--performance)"
                echo "  4) 集成专项 (--integration)"
                echo -ne "请选择 [1-4]: "
                read -r test_choice
                case $test_choice in
                    1) execute_script "99_test_orchestrator.sh" "--quick" "快速测试编排" ;;
                    2) execute_script "99_test_orchestrator.sh" "--full" "完整测试编排" ;;
                    3) execute_script "99_test_orchestrator.sh" "--performance" "性能专项编排" ;;
                    4) execute_script "99_test_orchestrator.sh" "--integration" "集成专项编排" ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                ;;
            6)
                echo -e "${CYAN}选择部署操作:${NC}"
                echo "  1) 构建项目 (--build)"
                echo "  2) 打包部署 (--package)"
                echo "  3) 系统安装 (--install)"
                echo "  4) 发布版本 (--release)"
                echo -ne "请选择 [1-4]: "
                read -r deploy_choice
                case $deploy_choice in
                    1) execute_script "04_deployment.sh" "--build" "项目构建" ;;
                    2) execute_script "04_deployment.sh" "--package" "打包部署" ;;
                    3) execute_script "04_deployment.sh" "--install" "系统安装" ;;
                    4) execute_script "04_deployment.sh" "--release" "发布版本" ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                ;;
            7)
                echo -e "${CYAN}选择监控操作:${NC}"
                echo "  1) 系统状态 (--status)"
                echo "  2) 日志管理 (--logs)"
                echo "  3) 清理日志 (--clean)"
                echo "  4) 生成报告 (--report)"
                echo "  5) 实时监控 (--watch)"
                echo -ne "请选择 [1-5]: "
                read -r monitor_choice
                case $monitor_choice in
                    1) execute_script "05_monitoring.sh" "--status" "系统状态检查" ;;
                    2) execute_script "05_monitoring.sh" "--logs" "日志文件管理" ;;
                    3) execute_script "05_monitoring.sh" "--clean" "日志清理" ;;
                    4) execute_script "05_monitoring.sh" "--report" "监控报告生成" ;;
                    5) execute_script "05_monitoring.sh" "--watch" "实时监控" ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                ;;
            8)
                echo -e "${CYAN}选择维护操作:${NC}"
                echo "  1) 清理临时文件 (--clean)"
                echo "  2) 重置环境 (--reset)"
                echo "  3) 数据备份 (--backup)"
                echo "  4) 性能优化 (--optimize)"
                echo "  5) 全面维护 (--all)"
                echo -ne "请选择 [1-5]: "
                read -r maint_choice
                case $maint_choice in
                    1) execute_script "06_maintenance.sh" "--clean" "清理临时文件" ;;
                    2) execute_script "06_maintenance.sh" "--reset" "环境重置" ;;
                    3) execute_script "06_maintenance.sh" "--backup" "数据备份" ;;
                    4) execute_script "06_maintenance.sh" "--optimize" "性能优化" ;;
                    5) execute_script "06_maintenance.sh" "--all" "全面维护" ;;
                    *) echo -e "${RED}无效选择${NC}" ;;
                esac
                ;;
            q|Q)
                quick_validation
                ;;
            f|F)
                full_testing
                ;;
            c|C)
                system_cleanup
                ;;
            m|M)
                monitor_status
                ;;
            h|H)
                show_help
                read -p "按 Enter 键继续..." -r
                ;;
            s|S)
                echo -e "${CYAN}详细脚本状态:${NC}"
                show_script_status
                read -p "按 Enter 键继续..." -r
                ;;
            0)
                echo -e "${GREEN}👋 感谢使用 BellhopPropagationModel 脚本管理器！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 检查是否在正确的目录
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo -e "${RED}❌ 错误: 未找到 scripts 目录${NC}"
    echo "请确保在项目根目录下运行此脚本"
    exit 1
fi

# 启动主循环
main_loop
