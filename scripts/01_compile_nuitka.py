#!/usr/bin/env python3
"""
Nuitka编译脚本 - 简化版本
只编译关键模块，依赖用户预装的科学计算库
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def check_dependencies():
    """检查必要的依赖库"""
    missing_deps = []
    
    try:
        import numpy
        print(f"✓ NumPy {numpy.__version__}")
    except ImportError:
        missing_deps.append("numpy")
    
    try:
        import scipy
        print(f"✓ SciPy {scipy.__version__}")
    except ImportError:
        missing_deps.append("scipy")
    
    try:
        import nuitka
        print(f"✓ Nuitka")
    except ImportError:
        missing_deps.append("nuitka")
    
    if missing_deps:
        print(f"\n缺少依赖库: {', '.join(missing_deps)}")
        print("请运行: pip install " + " ".join(missing_deps))
        return False
    
    return True

def needs_recompile(source_file, output_file, force=False):
    """检查是否需要重新编译"""
    if force:
        return True, "强制重编译"
        
    if not output_file.exists():
        return True, "输出文件不存在"
    
    source_mtime = source_file.stat().st_mtime
    output_mtime = output_file.stat().st_mtime
    
    if source_mtime > output_mtime:
        return True, "源文件已修改"
    
    return False, "无需重编译"

def get_output_filename(source_file, lib_dir):
    """获取编译后的输出文件名"""
    # Python模块编译后的文件名格式：module.cpython-39-x86_64-linux-gnu.so
    module_name = source_file.stem
    # 简化：直接查找以模块名开头的.so文件
    for so_file in lib_dir.glob(f"{module_name}.cpython-*.so"):
        return so_file
    
    # 如果找不到，返回预期的文件名（用于首次编译）
    import platform
    python_version = f"{sys.version_info.major}{sys.version_info.minor}"
    if platform.system() == "Linux":
        return lib_dir / f"{module_name}.cpython-{python_version}-x86_64-linux-gnu.so"
    else:
        return lib_dir / f"{module_name}.cpython-{python_version}.so"

def compile_all_modules(project_root, force=False):
    """编译所有模块（python_core + python_wrapper），支持增量编译"""
    python_core_dir = project_root / "python_core"
    python_wrapper_dir = project_root / "python_wrapper"
    lib_dir = project_root / "lib"
    
    # 确保lib目录存在
    lib_dir.mkdir(exist_ok=True)
    
    print("开始编译所有模块（增量编译版本）...")
    if force:
        print("模式: 强制重编译所有文件")
    else:
        print("模式: 只编译有变化的文件，节省编译时间")
    
    # 最简参数配置
    base_cmd = [
        sys.executable, "-m", "nuitka",
        "--module",                          # 编译为Python扩展
        "--output-dir=" + str(lib_dir),      # 输出目录
        "--remove-output",                   # 清理临时文件
        "--no-pyi-file",                     # 不生成类型文件
        "--assume-yes-for-downloads",        # 自动确认下载
    ]
    
    total_compiled = 0
    total_skipped = 0
    
    # 1. 编译 python_core 模块
    print("\n=== 检查核心模块 ===")
    core_modules = ["bellhop.py", "readwrite.py", "env.py", "config.py", "project.py"]
    
    for module in core_modules:
        module_path = python_core_dir / module
        if module_path.exists():
            output_file = get_output_filename(module_path, lib_dir)
            needs_compile, reason = needs_recompile(module_path, output_file, force)
            
            if needs_compile:
                print(f"编译 python_core/{module} ({reason})...")
                
                cmd = base_cmd + [str(module_path)]
                
                try:
                    subprocess.run(cmd, check=True, cwd=project_root)
                    print(f"✓ {module} 编译成功")
                    total_compiled += 1
                except subprocess.CalledProcessError as e:
                    print(f"⚠ {module} 编译失败: {e}")
                    print("  继续编译其他模块...")
            else:
                print(f"⏭ 跳过 python_core/{module} ({reason})")
                total_skipped += 1
    
    # 2. 编译 python_wrapper 模块
    print("\n=== 检查包装器模块 ===")
    wrapper_modules = ["bellhop_wrapper.py"]
    
    for module in wrapper_modules:
        module_path = python_wrapper_dir / module
        if module_path.exists():
            output_file = get_output_filename(module_path, lib_dir)
            needs_compile, reason = needs_recompile(module_path, output_file, force)
            
            if needs_compile:
                print(f"编译 python_wrapper/{module} ({reason})...")
                
                cmd = base_cmd + [str(module_path)]
                
                try:
                    subprocess.run(cmd, check=True, cwd=project_root)
                    print(f"✓ {module} 编译成功")
                    total_compiled += 1
                except subprocess.CalledProcessError as e:
                    print(f"✗ {module} 编译失败: {e}")
                    return False
            else:
                print(f"⏭ 跳过 python_wrapper/{module} ({reason})")
                total_skipped += 1
        else:
            print(f"✗ 找不到模块: {module_path}")
            return False
    
    # 显示编译统计
    print(f"\n=== 编译统计 ===")
    print(f"编译文件数: {total_compiled}")
    print(f"跳过文件数: {total_skipped}")
    print(f"总文件数: {total_compiled + total_skipped}")
    
    if total_compiled > 0:
        print("✓ 有文件被重新编译")
    else:
        print("✓ 所有文件都是最新的，无需编译")
    
    return True

def create_simple_init(project_root):
    """创建简单的初始化文件"""
    lib_dir = project_root / "lib"
    
    init_content = '''"""
Bellhop传播模型 - 简化Nuitka版本
所有核心模块和包装器都已编译为库
"""

import sys
import os

# 添加路径
current_dir = os.path.dirname(__file__)
project_root = os.path.dirname(current_dir)
for path in [current_dir, 
             os.path.join(project_root, 'python_wrapper'),
             os.path.join(project_root, 'python_core')]:
    if path not in sys.path:
        sys.path.insert(0, path)

# 导入主要接口
try:
    # 优先使用编译后的包装器
    from bellhop_wrapper import solve_bellhop_propagation
    print("✓ 使用Nuitka编译的bellhop_wrapper")
except ImportError:
    # 回退到原始模块
    try:
        sys.path.insert(0, os.path.join(project_root, 'python_wrapper'))
        from bellhop_wrapper import solve_bellhop_propagation
        print("✓ 使用原始bellhop_wrapper")
    except ImportError as e:
        raise ImportError(f"无法加载bellhop_wrapper: {e}")

# 尝试导入编译后的核心模块（可选）
try:
    # 这些模块已编译为库，可以直接导入
    import bellhop
    import readwrite
    import env
    print("✓ 编译后的核心模块可用")
except ImportError:
    print("⚠ 使用原始核心模块")

__all__ = ['solve_bellhop_propagation']
'''
    
    init_file = lib_dir / "__init__.py"
    with open(init_file, 'w', encoding='utf-8') as f:
        f.write(init_content)
    
    print(f"✓ 初始化文件已创建: {init_file}")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Bellhop传播模型 - 增量Nuitka编译')
    parser.add_argument('--force', '-f', action='store_true', 
                       help='强制重编译所有文件（忽略时间戳检查）')
    args = parser.parse_args()
    
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    print("=== Bellhop传播模型 - 增量Nuitka编译 ===")
    print(f"项目根目录: {project_root}")
    if args.force:
        print("模式: 强制重编译所有文件")
    else:
        print("功能: 只编译有变化的文件，提高编译效率")
    
    # 检查依赖
    if not check_dependencies():
        sys.exit(1)
    
    # 编译所有模块
    if not compile_all_modules(project_root, force=args.force):
        sys.exit(1)
    
    # 创建简单初始化文件
    create_simple_init(project_root)
    
    print("\n=== 编译完成 ===")
    
    # 显示结果
    lib_dir = project_root / "lib"
    compiled_files = list(lib_dir.glob("*.so")) + list(lib_dir.glob("*.pyd"))
    
    if compiled_files:
        print("编译产物:")
        for file in compiled_files:
            size = file.stat().st_size / 1024  # KB
            print(f"  {file.name}: {size:.1f} KB")
    
    print("\n优势:")
    print("- 增量编译，只编译有变化的文件")  
    print("- 大幅提升重复编译的速度")
    print("- python_core 和 python_wrapper 都编译为库")
    print("- 依赖用户环境的numpy/scipy，避免版本冲突")
    print("- 仍然获得Nuitka的基本性能优化")
    
    return True

if __name__ == "__main__":
    main()
