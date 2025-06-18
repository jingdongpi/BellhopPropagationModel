#!/bin/bash

# Python环境变量设置脚本
# 用途：一键设置当前路径的Python环境变量，包括LD_LIBRARY_PATH

set -e  # 遇到错误时退出

# 获取当前目录的绝对路径
CURRENT_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Python环境变量设置脚本 ===${NC}"
echo -e "${YELLOW}当前目录: ${CURRENT_DIR}${NC}"

# 检查Python安装
check_python() {
    echo -e "\n${BLUE}检查Python安装...${NC}"
    
    # 查找可用的Python版本
    PYTHON_VERSIONS=()
    for py in python3.11 python3.10 python3.9 python3.8 python3 python; do
        if command -v "$py" &> /dev/null; then
            PYTHON_VERSIONS+=("$py")
        fi
    done
    
    if [ ${#PYTHON_VERSIONS[@]} -eq 0 ]; then
        echo -e "${RED}错误: 未找到Python安装${NC}"
        exit 1
    fi
    
    PYTHON_CMD="${PYTHON_VERSIONS[0]}"
    PYTHON_VERSION=$($PYTHON_CMD --version | cut -d' ' -f2)
    echo -e "${GREEN}找到Python: $PYTHON_CMD (版本 $PYTHON_VERSION)${NC}"
}

# 查找Python相关路径
find_python_paths() {
    echo -e "\n${BLUE}查找Python相关路径...${NC}"
    
    # 获取Python可执行文件路径
    PYTHON_EXECUTABLE=$(which $PYTHON_CMD)
    PYTHON_PREFIX=$($PYTHON_CMD -c "import sys; print(sys.prefix)")
    PYTHON_EXEC_PREFIX=$($PYTHON_CMD -c "import sys; print(sys.exec_prefix)")
    
    # 获取Python库路径
    PYTHON_LIB_PATH=$($PYTHON_CMD -c "
import sys
import os
import sysconfig

# 获取标准库路径
stdlib_path = sysconfig.get_path('stdlib')
print(f'标准库路径: {stdlib_path}')

# 获取site-packages路径
site_packages = sysconfig.get_path('purelib')
print(f'Site-packages路径: {site_packages}')

# 获取动态库路径
lib_dynload = sysconfig.get_path('stdlib') + '/lib-dynload'
if os.path.exists(lib_dynload):
    print(f'动态库路径: {lib_dynload}')

# 获取可能的共享库路径
possible_lib_paths = [
    os.path.join(sys.prefix, 'lib'),
    os.path.join(sys.exec_prefix, 'lib'),
    os.path.join(sys.prefix, 'lib64'),
    os.path.join(sys.exec_prefix, 'lib64'),
]

for path in possible_lib_paths:
    if os.path.exists(path):
        print(f'共享库路径: {path}')
")
    
    echo -e "${GREEN}Python路径信息:${NC}"
    echo -e "  可执行文件: $PYTHON_EXECUTABLE"
    echo -e "  前缀路径: $PYTHON_PREFIX"
    echo -e "  执行前缀: $PYTHON_EXEC_PREFIX"
    echo "$PYTHON_LIB_PATH" | sed 's/^/  /'
}

# 查找当前目录中的库文件
find_local_libraries() {
    echo -e "\n${BLUE}查找当前目录中的库文件...${NC}"
    
    LOCAL_LIB_PATHS=()
    
    # 查找常见的库目录
    for dir in lib lib64 libs library libraries usr/lib usr/lib64; do
        if [ -d "$CURRENT_DIR/$dir" ]; then
            LOCAL_LIB_PATHS+=("$CURRENT_DIR/$dir")
            echo -e "${GREEN}找到库目录: $CURRENT_DIR/$dir${NC}"
        fi
    done
    
    # 查找.so文件
    SO_FILES=$(find "$CURRENT_DIR" -name "*.so*" -type f 2>/dev/null | head -10)
    if [ ! -z "$SO_FILES" ]; then
        echo -e "${GREEN}找到共享库文件:${NC}"
        echo "$SO_FILES" | sed 's/^/  /'
        
        # 将包含.so文件的目录添加到库路径
        while IFS= read -r so_file; do
            so_dir=$(dirname "$so_file")
            if [[ ! " ${LOCAL_LIB_PATHS[@]} " =~ " ${so_dir} " ]]; then
                LOCAL_LIB_PATHS+=("$so_dir")
            fi
        done <<< "$SO_FILES"
    fi
    
    # 添加当前目录本身
    LOCAL_LIB_PATHS+=("$CURRENT_DIR")
}

# 生成环境变量设置
generate_env_vars() {
    echo -e "\n${BLUE}生成环境变量设置...${NC}"
    
    # LD_LIBRARY_PATH
    LD_LIBRARY_NEW=""
    for path in "${LOCAL_LIB_PATHS[@]}"; do
        if [ ! -z "$LD_LIBRARY_NEW" ]; then
            LD_LIBRARY_NEW="$LD_LIBRARY_NEW:$path"
        else
            LD_LIBRARY_NEW="$path"
        fi
    done
    
    # 如果已有LD_LIBRARY_PATH，则追加
    if [ ! -z "$LD_LIBRARY_PATH" ]; then
        LD_LIBRARY_NEW="$LD_LIBRARY_NEW:$LD_LIBRARY_PATH"
    fi
    
    # PYTHONPATH
    PYTHONPATH_NEW="$CURRENT_DIR"
    if [ ! -z "$PYTHONPATH" ]; then
        PYTHONPATH_NEW="$PYTHONPATH_NEW:$PYTHONPATH"
    fi
    
    # PATH (添加当前目录到PATH)
    PATH_NEW="$CURRENT_DIR:$PATH"
}

# 显示将要设置的环境变量
show_env_vars() {
    echo -e "\n${BLUE}将要设置的环境变量:${NC}"
    echo -e "${YELLOW}LD_LIBRARY_PATH=${NC}$LD_LIBRARY_NEW"
    echo -e "${YELLOW}PYTHONPATH=${NC}$PYTHONPATH_NEW"
    echo -e "${YELLOW}PATH=${NC}$PATH_NEW"
}

# 应用环境变量
apply_env_vars() {
    echo -e "\n${BLUE}应用环境变量...${NC}"
    
    export LD_LIBRARY_PATH="$LD_LIBRARY_NEW"
    export PYTHONPATH="$PYTHONPATH_NEW"
    export PATH="$PATH_NEW"
    
    echo -e "${GREEN}环境变量已设置完成！${NC}"
}

# 生成设置脚本
generate_setup_script() {
    SETUP_SCRIPT="$CURRENT_DIR/setup_env.sh"
    
    cat > "$SETUP_SCRIPT" << EOF
#!/bin/bash
# 自动生成的Python环境变量设置脚本
# 生成时间: $(date)
# 当前目录: $CURRENT_DIR

export LD_LIBRARY_PATH="$LD_LIBRARY_NEW"
export PYTHONPATH="$PYTHONPATH_NEW"
export PATH="$PATH_NEW"

echo "Python环境变量已设置："
echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH"
echo "PYTHONPATH=\$PYTHONPATH"
echo "PATH=\$PATH"
EOF
    
    chmod +x "$SETUP_SCRIPT"
    echo -e "\n${GREEN}已生成设置脚本: $SETUP_SCRIPT${NC}"
    echo -e "${YELLOW}使用方法: source $SETUP_SCRIPT${NC}"
}

# 测试Python导入
test_python_import() {
    echo -e "\n${BLUE}测试Python环境...${NC}"
    
    # 测试基本导入
    if $PYTHON_CMD -c "import sys; print('Python版本:', sys.version)" 2>/dev/null; then
        echo -e "${GREEN}Python基本功能测试通过${NC}"
    else
        echo -e "${RED}Python基本功能测试失败${NC}"
    fi
    
    # 测试常用库
    for lib in numpy scipy pandas matplotlib; do
        if $PYTHON_CMD -c "import $lib" 2>/dev/null; then
            echo -e "${GREEN}$lib 导入成功${NC}"
        else
            echo -e "${YELLOW}$lib 未安装或导入失败${NC}"
        fi
    done
}

# 主函数
main() {
    check_python
    find_python_paths
    find_local_libraries
    generate_env_vars
    show_env_vars
    
    echo -e "\n${YELLOW}是否要应用这些环境变量? (y/n): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        apply_env_vars
        generate_setup_script
        test_python_import
        
        echo -e "\n${GREEN}=== 设置完成 ===${NC}"
        echo -e "${BLUE}提示:${NC}"
        echo -e "1. 当前shell中的环境变量已设置"
        echo -e "2. 要在新shell中使用，请运行: ${YELLOW}source $CURRENT_DIR/setup_env.sh${NC}"
        echo -e "3. 要永久设置，请将以下内容添加到 ~/.bashrc 或 ~/.zshrc:"
        echo -e "   ${YELLOW}source $CURRENT_DIR/setup_env.sh${NC}"
    else
        echo -e "${YELLOW}已取消设置${NC}"
    fi
}

# 运行主函数
main "$@"