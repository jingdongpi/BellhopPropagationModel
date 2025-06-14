#!/bin/bash

# Bellhop传播模型脚本管理器
# 统一管理所有项目脚本的入口

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# 显示帮助信息
show_help() {
    cat << EOF
Bellhop传播模型脚本管理器

用法: $0 <command> [options]

可用命令:
  build                     编译项目
  package                   创建交付包
  clean                     清理项目
  test                      运行测试
  help                      显示此帮助信息

示例:
  $0 build                  # 编译项目
  $0 package                # 创建交付包
  $0 clean                  # 清理项目
  $0 test                   # 运行测试

脚本位置: $SCRIPTS_DIR/
EOF
}

# 检查脚本目录是否存在
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "错误: 脚本目录不存在: $SCRIPTS_DIR"
    exit 1
fi

# 解析命令
case "${1:-help}" in
    build)
        echo "=== 执行编译 ==="
        exec "$SCRIPTS_DIR/build.sh" "${@:2}"
        ;;
    package)
        echo "=== 创建交付包 ==="
        exec "$SCRIPTS_DIR/create_delivery_package.sh" "${@:2}"
        ;;
    clean)
        echo "=== 清理项目 ==="
        exec "$SCRIPTS_DIR/cleanup.sh" "${@:2}"
        ;;
    test)
        echo "=== 运行测试 ==="
        # 先检查是否有交付包
        if [ -d "$SCRIPT_DIR/BellhopPropagationModel_Delivery" ]; then
            cd "$SCRIPT_DIR/BellhopPropagationModel_Delivery"
            if [ -f "test.sh" ]; then
                ./test.sh "${@:2}"
            else
                echo "错误: 交付包中未找到测试脚本"
                exit 1
            fi
        else
            echo "错误: 未找到交付包，请先运行: $0 package"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "错误: 未知命令 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac
