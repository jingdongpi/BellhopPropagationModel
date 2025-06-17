#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强的 Nuitka 编译脚本 - 跨平台版本
支持 Linux 和 Windows 平台的 Python 模块编译
"""

import os
import sys
import subprocess
import shutil
import platform
from pathlib import Path

# Windows编码修复：强制UTF-8
if platform.system() == 'Windows':
    # 设置环境变量
    os.environ['PYTHONIOENCODING'] = 'utf-8'
    os.environ['PYTHONUTF8'] = '1'
    
    # 重新配置stdout和stderr
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')

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
        try:
            version = nuitka.__version__
        except AttributeError:
            # 某些版本的 Nuitka 可能没有 __version__ 属性
            version = "已安装"
        print(f"✓ Nuitka {version}")
    except ImportError:
        missing_deps.append("nuitka")
    
    if missing_deps:
        print(f"❌ Missing required dependencies: {', '.join(missing_deps)}")
        print("Please run: pip install " + " ".join(missing_deps))
        return False
    
    return True

def get_platform_info():
    """获取平台相关信息"""
    system = platform.system()
    architecture = platform.machine()
    python_version = f"{sys.version_info.major}{sys.version_info.minor}"
    
    if system == "Windows":
        if architecture == "AMD64":
            arch_suffix = "win_amd64"
        elif architecture == "x86":
            arch_suffix = "win32"
        else:
            arch_suffix = "win_amd64"  # 默认
        extension = ".pyd"
        module_suffix = f".cp{python_version}-{arch_suffix}"
    elif system == "Linux":
        if architecture == "x86_64":
            arch_suffix = "x86_64-linux-gnu"
        elif architecture == "i686":
            arch_suffix = "i386-linux-gnu"
        else:
            arch_suffix = "x86_64-linux-gnu"  # 默认
        extension = ".so"
        module_suffix = f".cpython-{python_version}-{arch_suffix}"
    else:
        # macOS 或其他
        extension = ".so"
        module_suffix = f".cpython-{python_version}-darwin"
    
    return {
        "system": system,
        "architecture": architecture,
        "python_version": python_version,
        "extension": extension,
        "module_suffix": module_suffix
    }

def get_output_filename(source_file, lib_dir, platform_info):
    """获取编译后的输出文件名"""
    module_name = source_file.stem
    
    # 查找现有的编译文件
    pattern = f"{module_name}.cp*{platform_info['extension']}"
    for existing_file in lib_dir.glob(pattern):
        return existing_file
    
    # 如果没有找到，返回预期的文件名
    expected_name = f"{module_name}{platform_info['module_suffix']}{platform_info['extension']}"
    return lib_dir / expected_name

def needs_recompile(source_file, output_file, force=False):
    """检查是否需要重新编译"""
    if force:
        return True, "强制重编译"
    
    if not output_file.exists():
        return True, "目标文件不存在"
    
    source_mtime = source_file.stat().st_mtime
    output_mtime = output_file.stat().st_mtime
    
    if source_mtime > output_mtime:
        return True, "源文件已修改"
    
    return False, "无需重编译"

def get_nuitka_command(source_file, lib_dir, platform_info):
    """构建 Nuitka 编译命令"""
    base_cmd = [
        sys.executable, "-m", "nuitka",
        "--module",                          # 编译为Python扩展
        "--output-dir=" + str(lib_dir),      # 输出目录
        "--remove-output",                   # 清理临时文件
        "--no-pyi-file",                     # 不生成类型文件
        "--assume-yes-for-downloads",        # 自动确认下载
    ]
    
    # Windows 特定设置
    if platform_info["system"] == "Windows":
        # Windows 可能需要额外的编译器设置
        if shutil.which("gcc"):
            base_cmd.extend(["--mingw64"])
    
    base_cmd.append(str(source_file))
    return base_cmd

def compile_module(source_file, lib_dir, platform_info, force=False):
    """编译单个模块"""
    output_file = get_output_filename(source_file, lib_dir, platform_info)
    needs_compile, reason = needs_recompile(source_file, output_file, force)
    
    if not needs_compile:
        print(f"⏭️  Skip {source_file.name} ({reason})")
        return True
    
    print(f"🔨 Compiling {source_file.name} ({reason})...")
    
    cmd = get_nuitka_command(source_file, lib_dir, platform_info)
    
    try:
        # 设置环境变量
        env = os.environ.copy()
        
        # Windows 特定环境设置
        if platform_info["system"] == "Windows":
            # 确保 MinGW 在 PATH 中
            mingw_paths = [
                "C:\\tools\\mingw64\\bin",
                "C:\\mingw64\\bin",
                "C:\\mingw32\\bin"
            ]
            for mingw_path in mingw_paths:
                if os.path.exists(mingw_path):
                    env["PATH"] = mingw_path + os.pathsep + env.get("PATH", "")
                    break
        
        result = subprocess.run(cmd, check=True, capture_output=True, text=True, env=env)
        print(f"✅ {source_file.name} compilation successful")
        
        # 验证输出文件
        output_file = get_output_filename(source_file, lib_dir, platform_info)
        if output_file.exists():
            print(f"   Output: {output_file.name}")
        else:
            print(f"⚠️  Warning: Compilation succeeded but expected output file {output_file.name} not found")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ {source_file.name} compilation failed")
        print(f"   Error: {e}")
        if e.stdout:
            print(f"   stdout: {e.stdout}")
        if e.stderr:
            print(f"   stderr: {e.stderr}")
        return False

def compile_all_modules(project_root, force=False):
    """编译所有模块"""
    platform_info = get_platform_info()
    print(f"平台信息: {platform_info['system']} {platform_info['architecture']}")
    print(f"Python版本: {platform_info['python_version']}")
    print(f"模块后缀: {platform_info['module_suffix']}{platform_info['extension']}")
    
    python_core_dir = project_root / "python_core"
    python_wrapper_dir = project_root / "python_wrapper"
    lib_dir = project_root / "lib"
    
    # 确保lib目录存在
    lib_dir.mkdir(exist_ok=True)
    
    print("\n=== Starting Module Compilation ===")
    if force:
        print("Mode: Force recompile all files")
    else:
        print("Mode: Incremental compilation (only changed files)")
    
    total_compiled = 0
    total_skipped = 0
    total_failed = 0
    
    # 编译 python_core 模块
    print("\n--- Compiling Core Modules ---")
    core_modules = ["bellhop.py", "readwrite.py", "env.py", "project.py"]
    
    for module in core_modules:
        module_path = python_core_dir / module
        if module_path.exists():
            if compile_module(module_path, lib_dir, platform_info, force):
                total_compiled += 1
            else:
                total_failed += 1
        else:
            print(f"⚠️  Skip non-existent module: {module}")
    
    # 编译 python_wrapper 模块
    print("\n--- Compiling Wrapper Modules ---")
    wrapper_modules = ["bellhop_wrapper.py"]
    
    for module in wrapper_modules:
        module_path = python_wrapper_dir / module
        if module_path.exists():
            if compile_module(module_path, lib_dir, platform_info, force):
                total_compiled += 1
            else:
                total_failed += 1
        else:
            print(f"⚠️  Skip non-existent module: {module}")
    
    # 总结
    print(f"\n=== Compilation Complete ===")
    print(f"Successfully compiled: {total_compiled} modules")
    print(f"Failed compilation: {total_failed} modules")
    
    if total_failed > 0:
        print(f"❌ {total_failed} modules failed to compile")
        return False
    else:
        print("✅ All modules compiled successfully")
        return True

def main():
    """主函数"""
    project_root = Path(__file__).parent.parent
    
    print("=== Nuitka Cross-Platform Module Compiler ===")
    print(f"Project root: {project_root}")
    print(f"Platform: {platform.system()}")
    
    # 检查依赖
    if not check_dependencies():
        sys.exit(1)
    
    # 解析参数
    force = "--force" in sys.argv or "-f" in sys.argv
    
    # 编译模块
    success = compile_all_modules(project_root, force=force)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
