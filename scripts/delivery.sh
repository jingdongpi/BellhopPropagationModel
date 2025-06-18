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

echo "📖 更多使用方法:"
echo "  - 查看项目文档: cat README.md"
echo "  - 环境变量自助配置: ./python_env_setup.sh"
echo "  - 测试动态库示例: cd examples && ./run_example.sh"
echo "  - 运行C++可执行文件: ./bin/BellhopPropagationModel examples/input.json output.json"
echo
echo "💡 如果遇到库找不到的问题，请运行: ./python_env_setup.sh"

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
    
    # 创建目录结构 - 简化版，不包含scripts目录
    mkdir -p {bin,lib,include,examples}
    
    log_success "交付包目录结构创建完成"
}

# 复制核心文件
copy_core_files() {
    log_info "复制核心文件..."
    
    cd "$PROJECT_ROOT"
    
    # 复制二进制文件
    cp bin/BellhopPropagationModel "$DELIVERY_DIR/bin/"
    
    # 复制 bellhop 二进制文件（重要！）
    if [ -f "bin/bellhop" ]; then
        cp bin/bellhop "$DELIVERY_DIR/bin/"
        log_success "bellhop 二进制文件已复制"
    else
        log_error "bellhop 二进制文件不存在: bin/bellhop"
        log_info "请确保 bellhop 二进制文件位于 bin/ 目录中"
        exit 1
    fi
    
    # 复制动态库
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
    
    # 复制示例源代码
    cp examples/use_library_example.cpp "$DELIVERY_DIR/examples/"
    
    # 复制输入示例文件（确保从正确位置复制）
    if [ -f "examples/input.json" ]; then
        cp examples/input.json "$DELIVERY_DIR/examples/"
        log_success "input.json 已复制到示例目录"
    else
        log_warning "input.json 未找到，示例可能无法正常运行"
    fi
    
    # 复制其他输入任务文件
    cp examples/input_task*.json "$DELIVERY_DIR/examples/" 2>/dev/null || true
    
    # 复制 examples 中的运行脚本
    if [ -f "examples/run_example.sh" ]; then
        cp examples/run_example.sh "$DELIVERY_DIR/examples/"
        chmod +x "$DELIVERY_DIR/examples/run_example.sh"
        log_success "run_example.sh 已复制到 examples 目录"
    else
        log_warning "examples/run_example.sh 未找到"
    fi
    
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

1. **运行快速开始脚本**（推荐）:
   ```bash
   ./quick_start.sh
   ```

2. **或手动设置环境变量后运行**:
   ```bash
   # 设置动态库路径（必需）
   export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
   
   # 运行计算
   ./bin/BellhopPropagationModel examples/input.json output.json
   ```

3. **测试动态库示例**:
   ```bash
   cd examples
   ./run_example.sh
   ```

## 环境变量自助配置

如果遇到Python库找不到的问题，可以使用提供的环境配置脚本：

```bash
# 运行环境配置脚本
./python_env_setup.sh

# 脚本会自动：
# 1. 检测系统中的Python安装
# 2. 查找项目中的库文件
# 3. 自动生成环境变量配置
# 4. 生成setup_env.sh脚本

# 使用生成的环境配置（立即生效）
source setup_env.sh

# 或者永久配置（添加到shell配置文件）
echo "source $(pwd)/setup_env.sh" >> ~/.bashrc
```

### 手动配置环境变量
如果自动配置脚本无法使用，可以手动设置：

```bash
# 必需的环境变量
export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"
export PYTHONPATH="$PWD/lib:$PYTHONPATH"
export PATH="$PWD:$PATH"

# 保存到文件以便重复使用
echo 'export LD_LIBRARY_PATH="'$PWD'/lib:$LD_LIBRARY_PATH"' > setup_env.sh
echo 'export PYTHONPATH="'$PWD'/lib:$PYTHONPATH"' >> setup_env.sh
echo 'export PATH="'$PWD':$PATH"' >> setup_env.sh
chmod +x setup_env.sh

# 之后使用
source setup_env.sh
```

## 使用方法

### 1. 快速开始（推荐）
```bash
./quick_start.sh
```

### 2. 直接运行可执行文件
```bash
./bin/BellhopPropagationModel examples/input.json output.json
```

### 3. 测试动态库示例
```bash
cd examples
./run_example.sh
```

### 4. 环境问题自助修复
```bash
./python_env_setup.sh
```

## 常见问题解决

### 找不到动态库
**错误**: `error while loading shared libraries: libBellhopPropagationModel.so`

**解决**: 
1. 确保在项目根目录下运行
2. 设置LD_LIBRARY_PATH：`export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH`
3. 或运行快速开始脚本：`./quick_start.sh`
4. 或使用环境配置脚本：`./python_env_setup.sh`

### Python模块导入失败
**错误**: `ModuleNotFoundError: No module named 'bellhop_wrapper'`

**解决**:
1. 设置PYTHONPATH：`export PYTHONPATH=$PWD/lib:$PYTHONPATH`
2. 或使用环境配置脚本：`./python_env_setup.sh`

### 权限问题
**错误**: `Permission denied`

**解决**:
```bash
chmod +x bin/BellhopPropagationModel
chmod +x bin/bellhop
chmod +x quick_start.sh
chmod +x examples/run_example.sh
chmod +x python_env_setup.sh
```

## 文件说明

### 核心文件
- `bin/BellhopPropagationModel` - 主要可执行文件
- `bin/bellhop` - Bellhop声学传播计算引擎
- `lib/libBellhopPropagationModel.so` - 动态库
- `lib/*.cpython-*.so` - Python扩展模块

### 脚本文件
- `quick_start.sh` - 快速开始脚本，自动设置环境并运行示例
- `python_env_setup.sh` - 环境变量自助配置脚本
- `examples/run_example.sh` - 动态库使用示例脚本

### 示例文件
- `examples/input.json` - 输入参数示例
- `examples/use_library_example.cpp` - 动态库使用示例代码

## 重要说明

⚠️  **必须设置 `LD_LIBRARY_PATH`**：项目使用自定义动态库，系统无法在标准路径中找到，因此必须设置此环境变量指向 `lib/` 目录。

💡 **推荐使用快速开始脚本**：`./quick_start.sh` 会自动配置环境变量并运行示例。

💡 **推荐使用环境配置脚本**：`./python_env_setup.sh` 会自动检测并配置所有必需的环境变量，避免手动配置错误。

## 系统要求

- Linux 64位
- Python 3.8+
- numpy, scipy

## 支持

如果遇到问题：
1. 首先尝试运行快速开始脚本：`./quick_start.sh`
2. 如果有环境变量问题，运行：`./python_env_setup.sh`
3. 查看examples目录中的示例：`cd examples && ./run_example.sh`

更多详细信息请联系开发团队。
EOF
        log_warning "已创建简化版 README"
    fi
    
    # 复制 scripts 文件夹中的 README.md（如果存在，作为参考）
    # 注意：实际交付包中不包含scripts目录
    if [ -f "scripts/README.md" ]; then
        log_info "scripts/README.md 存在，但不会复制到交付包（简化交付）"
    fi
}

# 复制用户脚本文件
copy_user_scripts() {
    log_info "复制用户必需的脚本文件..."
    
    cd "$PROJECT_ROOT"
    
    # 只复制用户需要的Python环境配置脚本到根目录
    if [ -f "scripts/python_env_setup.sh" ]; then
        cp scripts/python_env_setup.sh "$DELIVERY_DIR/"
        chmod +x "$DELIVERY_DIR/python_env_setup.sh"
        log_success "python_env_setup.sh 已复制到根目录"
    else
        log_warning "scripts/python_env_setup.sh 未找到"
    fi
    
    # 不再复制scripts目录，所有脚本都放在合适的位置
    log_success "用户脚本文件复制完成"
}

# 创建部署脚本
create_deployment_scripts() {
    log_info "创建部署脚本..."
    
    # 创建快速开始脚本（放在项目根目录）
    cat > "$DELIVERY_DIR/quick_start.sh" << 'EOF'
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
PROJECT_DIR="$SCRIPT_DIR"

export LD_LIBRARY_PATH="$PROJECT_DIR/lib:$LD_LIBRARY_PATH"
export PYTHONPATH="$PROJECT_DIR/lib:$PYTHONPATH"

echo "✅ 环境变量已设置"
echo "  - LD_LIBRARY_PATH: $PROJECT_DIR/lib"
echo "  - PYTHONPATH: $PROJECT_DIR/lib"
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
echo
echo "📖 更多使用方法:"
echo "  - 查看项目文档: cat README.md"
echo "  - 查看脚本说明: cat scripts/README.md"
echo "  - 环境变量自助配置: ./scripts/python_env_setup.sh"
echo "  - 测试动态库示例: cd examples && ./run_example.sh"
echo "  - 运行C++可执行文件: ./bin/BellhopPropagationModel examples/input.json output.json"
echo
echo "💡 如果遇到库找不到的问题，请运行: ./python_env_setup.sh"
EOF

    chmod +x "$DELIVERY_DIR/quick_start.sh"
    
    log_info "注意：quick_start.sh 脚本已放在项目根目录"
    log_info "注意：run_example.sh 脚本已从 examples 目录复制"
    
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
    echo "  3. 快速开始: ./quick_start.sh"
    echo "  4. 动态库示例: cd examples && ./run_example.sh"
    echo "  5. 环境配置: ./python_env_setup.sh"
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
    copy_user_scripts
    copy_delivery_readme
    create_deployment_scripts
    generate_version_info
    create_package
    show_delivery_summary
}

# 运行主函数
main "$@"
