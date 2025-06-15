#!/bin/bash

# BellhopPropagationModel 项目交付脚本
# 用途：创建完整的项目交付包

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DELIVERY_DIR="$PROJECT_ROOT/BellhopPropagationModel_Delivery"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
PACKAGE_NAME="BellhopPropagationModel_v1.0.0_$TIMESTAMP"

# 日志函数
log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️  $1"
}

log_error() {
    echo "❌ $1"
}

# 清理旧的交付目录
cleanup_old_delivery() {
    log_info "清理旧的交付目录..."
    rm -rf "$DELIVERY_DIR"
    mkdir -p "$DELIVERY_DIR"
}

# 检查构建状态
check_build_status() {
    log_info "检查构建状态..."
    
    cd "$PROJECT_ROOT"
    
    # 检查动态库
    if [ ! -f "lib/libBellhopPropagationModel.so" ]; then
        log_error "动态库不存在，请先构建项目"
        log_info "运行: ./manager.sh build"
        exit 1
    fi
    
    # 检查可执行文件
    if [ ! -f "bin/BellhopPropagationModel" ]; then
        log_error "可执行文件不存在，请先构建项目"
        log_info "运行: ./manager.sh build"
        exit 1
    fi
    
    # 检查 Python 模块
    if [ ! -f "lib/bellhop_wrapper.cpython-39-x86_64-linux-gnu.so" ]; then
        log_warning "Python 模块可能缺失，但继续创建交付包"
    fi
    
    log_success "构建状态检查完成"
}

# 创建交付包结构
create_delivery_structure() {
    log_info "创建交付包结构..."
    
    cd "$DELIVERY_DIR"
    
    # 创建目录结构
    mkdir -p {bin,lib,include,examples,scripts}
    
    log_success "交付包目录结构创建完成"
}

# 复制核心文件
copy_core_files() {
    log_info "复制核心文件..."
    
    cd "$PROJECT_ROOT"
    
    # 复制二进制文件
    cp bin/BellhopPropagationModel "$DELIVERY_DIR/bin/"
    cp lib/libBellhopPropagationModel.so "$DELIVERY_DIR/lib/"
    
    # 复制头文件
    cp include/BellhopPropagationModelInterface.h "$DELIVERY_DIR/include/"
    
    # 复制 Python 模块（如果存在）
    cp lib/*.cpython-*.so "$DELIVERY_DIR/lib/" 2>/dev/null || log_warning "某些 Python 模块未找到"
    cp lib/__init__.py "$DELIVERY_DIR/lib/" 2>/dev/null || true
    
    log_success "核心文件复制完成"
}

# 复制示例文件
copy_examples() {
    log_info "复制示例文件..."
    
    cd "$PROJECT_ROOT"
    
    # 复制示例文件
    cp examples/use_library_example.cpp "$DELIVERY_DIR/examples/"
    cp examples/run_example.sh "$DELIVERY_DIR/examples/"
    
    # 复制输入示例
    cp input.json "$DELIVERY_DIR/examples/" 2>/dev/null || true
    cp examples/input_task*.json "$DELIVERY_DIR/examples/" 2>/dev/null || true
    
    log_success "示例文件复制完成"
}

# 复制交付说明文档
copy_delivery_readme() {
    log_info "复制交付说明文档..."
    
    cd "$PROJECT_ROOT"
    
    # 复制 docs/DELIVERY_GUIDE.md 作为交付包的 README.md
    if [ -f "docs/DELIVERY_GUIDE.md" ]; then
        cp "docs/DELIVERY_GUIDE.md" "$DELIVERY_DIR/README.md"
        log_success "交付说明文档复制完成"
    else
        log_error "未找到 docs/DELIVERY_GUIDE.md"
        log_info "创建简化版 README..."
        
        cat > "$DELIVERY_DIR/README.md" << 'EOF'
# BellhopPropagationModel 交付包

**版本**: v1.0.0  
**平台**: Linux x64

## 快速开始

1. 设置环境变量:
   ```bash
   export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
   ```

2. 运行快速开始脚本:
   ```bash
   ./scripts/quick_start.sh
   ```

3. 或直接运行可执行文件:
   ```bash
   ./bin/BellhopPropagationModel examples/input.json output.json
   ```

## 系统要求

- Linux 64位
- Python 3.8+
- numpy, scipy

更多详细信息请联系开发团队。
EOF
        log_warning "已创建简化版 README"
    fi
}

# 创建部署脚本
create_deployment_scripts() {
    log_info "创建部署脚本..."
    
    # 创建快速开始脚本
    cat > "$DELIVERY_DIR/scripts/quick_start.sh" << 'EOF'
#!/bin/bash

# BellhopPropagationModel 快速开始脚本

echo "=== BellhopPropagationModel 快速开始 ==="
echo

# 检查依赖
echo "检查系统依赖..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi
echo "✅ Python3: $(python3 --version)"

# 设置环境变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

export LD_LIBRARY_PATH="$PROJECT_DIR/lib:$LD_LIBRARY_PATH"

echo "✅ 环境变量已设置"
echo

# 运行示例
echo "运行示例..."
cd "$PROJECT_DIR/examples"

if [ -f "input.json" ]; then
    echo "使用默认输入文件运行..."
    ../bin/BellhopPropagationModel input.json output.json
    
    if [ -f "output.json" ]; then
        echo "✅ 计算完成，结果保存在 output.json"
        echo "输出文件大小: $(ls -lh output.json | awk '{print $5}')"
    else
        echo "❌ 计算失败"
        exit 1
    fi
else
    echo "❌ 输入文件 input.json 不存在"
    exit 1
fi

echo
echo "🎉 快速开始完成！"
echo "更多使用方法请参考 README.md"
EOF

    chmod +x "$DELIVERY_DIR/scripts/quick_start.sh"
    
    # 创建编译示例脚本
    cat > "$DELIVERY_DIR/scripts/compile_example.sh" << 'EOF'
#!/bin/bash

# 编译 C++ 示例程序

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "编译 C++ 示例程序..."

cd "$PROJECT_DIR/examples"

g++ -std=c++17 -Wall -O2 \
    -I../include \
    -o use_library_example \
    use_library_example.cpp \
    -L../lib \
    -lBellhopPropagationModel

if [ -f "use_library_example" ]; then
    echo "✅ 编译成功"
    echo "运行示例: ./use_library_example"
else
    echo "❌ 编译失败"
    exit 1
fi
EOF

    chmod +x "$DELIVERY_DIR/scripts/compile_example.sh"
    
    log_success "部署脚本创建完成"
}

# 生成版本信息
generate_version_info() {
    log_info "生成版本信息..."
    
    cat > "$DELIVERY_DIR/VERSION_INFO.txt" << EOF
BellhopPropagationModel 版本信息
========================================

版本号: v1.0.0
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
构建平台: $(uname -a)
Python版本: $(python3 --version 2>&1)
编译器: $(gcc --version | head -n1)

文件清单:
========================================
EOF

    cd "$DELIVERY_DIR"
    find . -type f | sort >> VERSION_INFO.txt
    
    echo "" >> VERSION_INFO.txt
    echo "文件大小统计:" >> VERSION_INFO.txt
    echo "========================================" >> VERSION_INFO.txt
    du -sh * >> VERSION_INFO.txt
    
    log_success "版本信息生成完成"
}

# 创建压缩包
create_package() {
    log_info "创建压缩包..."
    
    cd "$(dirname "$DELIVERY_DIR")"
    
    # 重命名目录
    mv "$(basename "$DELIVERY_DIR")" "$PACKAGE_NAME"
    
    # 创建 tar.gz 包
    tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
    
    # 创建 zip 包（如果 zip 命令可用）
    if command -v zip &> /dev/null; then
        zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" > /dev/null
        ZIP_CREATED=true
    else
        log_warning "zip 命令未找到，跳过 .zip 包创建"
        ZIP_CREATED=false
    fi
    
    # 显示包信息
    echo
    log_success "交付包创建完成:"
    echo "  📦 ${PACKAGE_NAME}.tar.gz ($(du -sh ${PACKAGE_NAME}.tar.gz | cut -f1))"
    if [ "$ZIP_CREATED" = true ]; then
        echo "  📦 ${PACKAGE_NAME}.zip ($(du -sh ${PACKAGE_NAME}.zip | cut -f1))"
    fi
    echo "  📁 ${PACKAGE_NAME}/ ($(du -sh ${PACKAGE_NAME} | cut -f1))"
    
    # 恢复目录名
    mv "$PACKAGE_NAME" "$(basename "$DELIVERY_DIR")"
}

# 显示交付总结
show_delivery_summary() {
    echo
    echo "================================================================="
    echo "🎉 BellhopPropagationModel 交付包创建完成!"
    echo "================================================================="
    echo
    echo "📍 交付位置: $PROJECT_ROOT"
    echo "📦 包文件:"
    cd "$PROJECT_ROOT"
    ls -lh "${PACKAGE_NAME}".* 2>/dev/null || echo "  (压缩包创建可能失败)"
    echo "📁 目录: $DELIVERY_DIR"
    echo
    echo "🚀 用户使用方法:"
    echo "  1. 解压: tar -xzf ${PACKAGE_NAME}.tar.gz"
    echo "  2. 进入: cd ${PACKAGE_NAME}"
    echo "  3. 快速开始: ./scripts/quick_start.sh"
    echo
    echo "✅ 交付完成!"
}

# 主函数
main() {
    echo "🚀 开始创建 BellhopPropagationModel 交付包..."
    echo
    
    cleanup_old_delivery
    check_build_status
    create_delivery_structure
    copy_core_files
    copy_examples
    copy_delivery_readme
    create_deployment_scripts
    generate_version_info
    create_package
    show_delivery_summary
}

# 运行主函数
main "$@"
