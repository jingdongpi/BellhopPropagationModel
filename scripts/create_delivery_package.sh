#!/bin/bash

# Bellhop传播模型交付包创建脚本
# 用途：创建完整的交付包，包含所有必要文件和文档

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DELIVERY_DIR="$PROJECT_ROOT/BellhopPropagationModel_Delivery"

echo "=== 创建交付包 ==="

# 进入项目根目录
cd "$PROJECT_ROOT"

# 检查编译产物是否存在
if [ ! -f "lib/libBellhopPropagationModel.so" ] || [ ! -f "examples/BellhopPropagationModel" ]; then
    echo "1. 编译项目..."
    "$SCRIPT_DIR/build.sh"
else
    echo "1. 发现编译产物，跳过编译..."
fi

echo "2. 复制核心文件..."

# 清理并创建交付目录
rm -rf "$DELIVERY_DIR"
mkdir -p "$DELIVERY_DIR"/{bin,lib,include,examples,docs}

# 复制可执行文件
cp examples/BellhopPropagationModel "$DELIVERY_DIR/bin/"

# 复制动态库
cp lib/libBellhopPropagationModel.so "$DELIVERY_DIR/lib/"

# 复制Cython扩展模块（从lib目录）
if [ -f "lib/bellhop_cython_core.cpython-39-x86_64-linux-gnu.so" ]; then
    cp lib/bellhop_cython_core.cpython-39-x86_64-linux-gnu.so "$DELIVERY_DIR/lib/"
fi
if [ -f "lib/bellhop_core_modules.cpython-39-x86_64-linux-gnu.so" ]; then
    cp lib/bellhop_core_modules.cpython-39-x86_64-linux-gnu.so "$DELIVERY_DIR/lib/"
fi

# 复制所有lib目录中的其他.so文件
for so_file in lib/*.so; do
    if [ -f "$so_file" ] && [ "$(basename "$so_file")" != "libBellhopPropagationModel.so" ]; then
        cp "$so_file" "$DELIVERY_DIR/lib/"
    fi
done

# 复制头文件
cp include/BellhopPropagationModelInterface.h "$DELIVERY_DIR/include/"

# 复制示例文件
cp examples/*.json "$DELIVERY_DIR/examples/" 2>/dev/null || true

# 复制文档
cp -r docs/* "$DELIVERY_DIR/docs/" 2>/dev/null || true
cp README.md "$DELIVERY_DIR/" 2>/dev/null || true

echo "3. 创建使用说明..."

# 创建交付包README
cat > "$DELIVERY_DIR/README.md" << 'EOF'
# Bellhop传播模型交付包

## 概述
这是 Bellhop 传播模型的完整交付包，采用 Cython+Python 优化方案，提供高性能的声学传播计算能力。

## 系统要求
- Linux x86_64 系统
- Python 3.9 或更高版本
- numpy 库
- 已安装 bellhop 二进制文件（位于系统 PATH 中）

## 安装依赖
```bash
# 安装Python依赖
pip install numpy

# 确保bellhop在PATH中
which bellhop  # 应该能找到bellhop可执行文件
```

## 目录结构
```
BellhopPropagationModel_Delivery/
├── README.md                    # 本文件
├── test.sh                      # 快速测试脚本
├── bin/
│   └── BellhopPropagationModel  # 主可执行文件
├── lib/
│   ├── libBellhopPropagationModel.so    # C++动态库
│   └── *.so                             # Cython扩展模块
├── include/
│   └── BellhopPropagationModelInterface.h  # C++接口头文件
├── examples/
│   ├── input*.json              # 输入示例
│   └── *.json                   # 其他示例文件
└── docs/                        # 详细文档
```

## 快速开始

### 1. 运行测试
```bash
./test.sh
```

### 2. 使用可执行文件
```bash
# 默认输入输出文件
./bin/BellhopPropagationModel

# 指定输入输出文件
./bin/BellhopPropagationModel input.json output.json
```

### 3. 环境配置
确保Python能找到Cython扩展模块：
```bash
export PYTHONPATH=$PWD/lib:$PYTHONPATH
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
```

## 注意事项
1. 本包依赖系统中已安装的 bellhop 二进制文件
2. 需要 Python 3.9+ 和 numpy 库
3. 所有路径配置都是相对于交付包根目录的

## 技术支持
如有问题，请检查：
1. Python版本和numpy安装
2. bellhop二进制文件是否在PATH中
3. 系统环境变量配置
EOF

echo "4. 创建快速测试脚本..."

# 创建测试脚本
cat > "$DELIVERY_DIR/test.sh" << 'EOF'
#!/bin/bash

# 快速测试脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Bellhop传播模型测试 ==="

# 设置环境变量
export PYTHONPATH="$PWD/lib:$PYTHONPATH"
export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"

echo "测试可执行文件..."

# 选择测试输入文件
TEST_INPUT=""
if [ -f "examples/input_minimal_test.json" ]; then
    TEST_INPUT="examples/input_minimal_test.json"
elif [ -f "examples/input.json" ]; then
    TEST_INPUT="examples/input.json"
else
    echo "错误: 未找到测试输入文件"
    exit 1
fi

echo "使用测试文件: $TEST_INPUT -> test_output.json"

# 运行测试
if ./bin/BellhopPropagationModel "$TEST_INPUT" test_output.json; then
    echo "✓ 测试成功"
    echo "✓ 输出文件: test_output.json"
    
    # 显示输出文件大小
    if [ -f "test_output.json" ]; then
        OUTPUT_SIZE=$(du -h test_output.json | cut -f1)
        echo "✓ 输出大小: $OUTPUT_SIZE"
    fi
else
    echo "✗ 测试失败"
    exit 1
fi

echo ""
echo "=== 测试完成 ==="
echo "如需更多测试，请参考 examples/ 目录中的其他输入文件"
EOF

chmod +x "$DELIVERY_DIR/test.sh"

# 计算包大小
PACKAGE_SIZE=$(du -sh "$DELIVERY_DIR" | cut -f1)

echo ""
echo "=== 交付包创建完成 ==="
echo "📦 交付包: BellhopPropagationModel_Delivery"
echo "📏 包大小: $PACKAGE_SIZE"
echo "🧪 测试命令: cd BellhopPropagationModel_Delivery && ./test.sh"
echo ""
echo "交付清单:"
echo "- bin/BellhopPropagationModel (可执行文件)"
echo "- lib/libBellhopPropagationModel.so (C++动态库)"
echo "- lib/*.so (Cython扩展模块)"
echo "- include/BellhopPropagationModelInterface.h (头文件)"
echo "- examples/ (输入输出示例)"
echo "- docs/ (使用文档)"
