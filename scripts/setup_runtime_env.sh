#!/bin/bash

# Bellhop传播模型运行时环境设置脚本
# 用于解决不同Python安装环境下的动态库链接问题

set -e

echo "=== Bellhop传播模型运行时环境设置 ==="

# 检测Python安装
PYTHON_CMD=$(which python3 2>/dev/null || which python 2>/dev/null || echo "")
if [ -z "$PYTHON_CMD" ]; then
    echo "❌ 未找到Python，请确保Python已正确安装"
    exit 1
fi

echo "✓ 找到Python: $PYTHON_CMD"
PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "✓ Python版本: $PYTHON_VERSION"

# 检测Python库路径
echo "正在检测Python库路径..."
PYTHON_LIB_PATHS=$($PYTHON_CMD -c "
import sys
import os
import sysconfig

lib_paths = []

# 方法1: 使用sysconfig
try:
    lib_dir = sysconfig.get_config_var('LIBDIR')
    if lib_dir and os.path.exists(lib_dir):
        lib_paths.append(lib_dir)
except:
    pass

# 方法2: 从可执行文件路径推断
exe_path = sys.executable
if exe_path:
    bin_dir = os.path.dirname(exe_path)
    prefix = os.path.dirname(bin_dir)
    for potential in [
        os.path.join(prefix, 'lib'),
        os.path.join(prefix, 'lib64'),
        os.path.join(bin_dir, '..', 'lib'),
        os.path.join(bin_dir, '..', 'lib64'),
    ]:
        real_path = os.path.realpath(potential)
        if os.path.exists(real_path) and real_path not in lib_paths:
            lib_paths.append(real_path)

# 方法3: 标准位置
for std_path in ['/usr/lib', '/usr/lib64', '/usr/local/lib', '/usr/local/lib64']:
    if os.path.exists(std_path) and std_path not in lib_paths:
        lib_paths.append(std_path)

print(':'.join(lib_paths))
")

echo "检测到的Python库路径:"
for path in $(echo $PYTHON_LIB_PATHS | tr ':' ' '); do
    echo "  - $path"
    # 查找Python动态库
    for so_name in "libpython${PYTHON_VERSION}.so" "libpython${PYTHON_VERSION}.so.1.0" "libpython${PYTHON_VERSION%%.*}.so"; do
        if [ -f "$path/$so_name" ]; then
            echo "    ✓ 找到: $so_name"
        fi
    done
done

# 生成环境变量设置脚本
cat > bellhop_env.sh << EOF
#!/bin/bash
# Bellhop传播模型运行时环境变量

# 添加Python库路径到LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$PYTHON_LIB_PATHS:\$LD_LIBRARY_PATH"

# 确保Python路径正确
export PYTHONPATH="\$PYTHONPATH"

echo "✓ 已设置运行时环境变量"
echo "LD_LIBRARY_PATH: \$LD_LIBRARY_PATH"
EOF

chmod +x bellhop_env.sh

echo ""
echo "=== 设置完成 ==="
echo "生成了环境设置脚本: bellhop_env.sh"
echo ""
echo "使用方法:"
echo "1. 设置环境变量:"
echo "   source ./bellhop_env.sh"
echo ""
echo "2. 运行Bellhop程序:"
echo "   ./bin/BellhopPropagationModel input.json output.json"
echo ""
echo "或者一次性运行:"
echo "   LD_LIBRARY_PATH=\"$PYTHON_LIB_PATHS:\$LD_LIBRARY_PATH\" ./bin/BellhopPropagationModel input.json output.json"
