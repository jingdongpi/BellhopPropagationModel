#!/bin/bash

# 双远程仓库管理脚本
# 用于同时管理Gitea和GitHub仓库

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
双远程仓库管理脚本

用法: $0 [选项]

选项:
    help              显示此帮助信息
    status            显示当前远程仓库状态
    add-github        添加GitHub远程仓库（需要提供GitHub仓库URL）
    push-all          推送到所有远程仓库
    push-gitea        仅推送到Gitea
    push-github       仅推送到GitHub
    sync              同步所有远程仓库
    setup-github      交互式设置GitHub仓库

示例:
    $0 add-github https://github.com/username/BellhopPropagationModel.git
    $0 push-all
    $0 sync

EOF
}

# 检查远程仓库状态
check_status() {
    log_info "当前远程仓库配置："
    git remote -v
    echo ""
    
    log_info "当前分支状态："
    git status --short
    echo ""
    
    log_info "最近提交："
    git log --oneline -5
}

# 添加GitHub远程仓库
add_github_remote() {
    local github_url=$1
    
    if [ -z "$github_url" ]; then
        log_error "请提供GitHub仓库URL"
        echo "用法: $0 add-github https://github.com/username/repo.git"
        return 1
    fi
    
    # 检查是否已存在github远程仓库
    if git remote | grep -q "^github$"; then
        log_warning "GitHub远程仓库已存在，将更新URL"
        git remote set-url github "$github_url"
    else
        log_info "添加GitHub远程仓库..."
        git remote add github "$github_url"
    fi
    
    log_success "GitHub远程仓库配置完成"
    log_info "当前远程仓库："
    git remote -v
}

# 推送到所有远程仓库
push_all() {
    local branch=${1:-main}
    
    log_info "推送到所有远程仓库 (分支: $branch)..."
    
    # 推送到Gitea
    if git remote | grep -q "^origin$"; then
        log_info "推送到Gitea (origin)..."
        git push origin "$branch"
        log_success "Gitea推送完成"
    fi
    
    # 推送到GitHub
    if git remote | grep -q "^github$"; then
        log_info "推送到GitHub..."
        git push github "$branch"
        log_success "GitHub推送完成"
    else
        log_warning "GitHub远程仓库未配置，跳过"
    fi
    
    log_success "所有远程仓库推送完成"
}

# 推送到Gitea
push_gitea() {
    local branch=${1:-main}
    log_info "推送到Gitea..."
    git push origin "$branch"
    log_success "Gitea推送完成"
}

# 推送到GitHub
push_github() {
    local branch=${1:-main}
    
    if ! git remote | grep -q "^github$"; then
        log_error "GitHub远程仓库未配置"
        log_info "请先运行: $0 add-github <github-url>"
        return 1
    fi
    
    log_info "推送到GitHub..."
    git push github "$branch"
    log_success "GitHub推送完成"
}

# 同步远程仓库
sync_repos() {
    local branch=${1:-main}
    
    log_info "同步远程仓库..."
    
    # 确保本地是最新的
    log_info "获取远程更新..."
    git fetch --all
    
    # 推送到所有远程仓库
    push_all "$branch"
    
    # 推送标签
    log_info "同步标签..."
    if git remote | grep -q "^origin$"; then
        git push origin --tags || log_warning "Gitea标签推送失败"
    fi
    
    if git remote | grep -q "^github$"; then
        git push github --tags || log_warning "GitHub标签推送失败"
    fi
    
    log_success "仓库同步完成"
}

# 交互式设置GitHub仓库
setup_github() {
    echo "=== GitHub仓库设置向导 ==="
    echo ""
    
    echo "请访问 https://github.com 并创建新仓库："
    echo "1. 点击右上角的 '+' 号"
    echo "2. 选择 'New repository'"
    echo "3. 输入仓库名称: BellhopPropagationModel"
    echo "4. 选择 Public 或 Private"
    echo "5. 不要初始化 README 或 .gitignore"
    echo "6. 点击 'Create repository'"
    echo ""
    
    read -p "创建完成后，请输入GitHub仓库URL: " github_url
    
    if [ -z "$github_url" ]; then
        log_error "URL不能为空"
        return 1
    fi
    
    # 验证URL格式
    if [[ ! "$github_url" =~ ^https://github\.com/.+/.+\.git$ ]]; then
        log_warning "URL格式可能不正确，应该类似: https://github.com/username/repo.git"
        read -p "是否继续? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    add_github_remote "$github_url"
    
    echo ""
    read -p "是否立即推送代码到GitHub? (Y/n): " push_confirm
    if [[ ! "$push_confirm" =~ ^[Nn]$ ]]; then
        push_github
        log_success "GitHub仓库设置完成！"
        echo ""
        echo "GitHub Actions将在代码推送后自动开始构建。"
        echo "你可以在 GitHub 仓库的 Actions 标签页查看构建状态。"
    fi
}

# 主程序
case "$1" in
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    "status")
        check_status
        ;;
    "add-github")
        add_github_remote "$2"
        ;;
    "push-all")
        push_all "$2"
        ;;
    "push-gitea")
        push_gitea "$2"
        ;;
    "push-github")
        push_github "$2"
        ;;
    "sync")
        sync_repos "$2"
        ;;
    "setup-github")
        setup_github
        ;;
    *)
        log_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
