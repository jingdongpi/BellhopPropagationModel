#!/usr/bin/env python3
"""
检查Nuitka编译产物的依赖关系
验证是否真的独立运行
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def check_file_dependencies(file_path):
    """检查文件的动态链接库依赖"""
    if not os.path.exists(file_path):
        return None, f"文件不存在: {file_path}"
    
    try:
        # Linux: 使用 ldd
        if shutil.which('ldd'):
            result = subprocess.run(['ldd', file_path], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip().split('\n'), None
        
        # 或者使用 objdump
        if shutil.which('objdump'):
            result = subprocess.run(['objdump', '-p', file_path], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                deps = [line.strip() for line in lines if 'NEEDED' in line]
                return deps, None
        
        return None, "未找到依赖检查工具 (ldd/objdump)"
        
    except Exception as e:
        return None, f"检查依赖时出错: {e}"

def analyze_python_dependency(deps):
    """分析是否依赖Python"""
    if not deps:
        return False, []
    
    python_deps = []
    for dep in deps:
        if any(keyword in dep.lower() for keyword in ['python', 'libpython']):
            python_deps.append(dep)
    
    return len(python_deps) > 0, python_deps

def check_project_binaries():
    """检查项目二进制文件的依赖"""
    project_root = Path(__file__).parent.parent
    
    print("=== Nuitka编译产物依赖关系分析 ===\n")
    
    # 检查的文件列表
    files_to_check = [
        ("C++可执行文件", project_root / "examples" / "BellhopPropagationModel"),
        ("C++动态库", project_root / "lib" / "libBellhopPropagationModel.so"),
    ]
    
    # 查找Nuitka编译的扩展模块
    lib_dir = project_root / "lib"
    if lib_dir.exists():
        for file_path in lib_dir.glob("*.so"):
            if file_path.name != "libBellhopPropagationModel.so":
                files_to_check.append((f"Nuitka扩展模块", file_path))
    
    all_results = {}
    
    for file_type, file_path in files_to_check:
        print(f"📁 {file_type}: {file_path.name}")
        
        if not file_path.exists():
            print(f"   ⚠ 文件不存在")
            print()
            continue
        
        deps, error = check_file_dependencies(str(file_path))
        
        if error:
            print(f"   ✗ {error}")
        else:
            has_python, python_deps = analyze_python_dependency(deps)
            
            # 统计总依赖数
            total_deps = len(deps) if deps else 0
            system_libs = []
            other_libs = []
            
            if deps:
                for dep in deps:
                    if any(lib in dep.lower() for lib in ['libc', 'libm', 'libdl', 'libpthread', 'linux-vdso']):
                        system_libs.append(dep)
                    elif not any(keyword in dep.lower() for keyword in ['python']):
                        other_libs.append(dep)
            
            print(f"   📊 总依赖: {total_deps}")
            print(f"   🐍 Python依赖: {'是' if has_python else '否'}")
            print(f"   🔧 系统库: {len(system_libs)}")
            print(f"   📚 其他库: {len(other_libs)}")
            
            if has_python:
                print(f"   🔍 Python相关依赖:")
                for dep in python_deps:
                    print(f"      • {dep.strip()}")
            
            all_results[file_type] = {
                'path': str(file_path),
                'has_python': has_python,
                'python_deps': python_deps,
                'total_deps': total_deps,
                'system_libs': len(system_libs),
                'other_libs': len(other_libs)
            }
        
        print()
    
    # 总结
    print("="*60)
    print("📋 依赖关系总结:")
    print()
    
    python_dependent_files = []
    independent_files = []
    
    for file_type, info in all_results.items():
        if info['has_python']:
            python_dependent_files.append(file_type)
        else:
            independent_files.append(file_type)
    
    if python_dependent_files:
        print("🐍 需要Python运行时的文件:")
        for file_type in python_dependent_files:
            print(f"   • {file_type}")
        print()
    
    if independent_files:
        print("✅ 不依赖Python的文件:")
        for file_type in independent_files:
            print(f"   • {file_type}")
        print()
    
    print("🎯 结论:")
    if python_dependent_files:
        print("   ⚠ 当前方案仍然需要Python运行时环境")
        print("   📝 这是因为使用了Nuitka的--module模式")
        print("   💡 要真正独立运行，需要:")
        print("      1. 使用Nuitka --standalone模式重写整个应用")
        print("      2. 或静态链接Python运行时")
        print("      3. 或重写为纯C++实现")
    else:
        print("   ✅ 所有文件都独立运行，无需Python环境")
    
    print()
    print("🔧 当前交付要求:")
    print("   • 用户系统需要安装Python 3.9+")
    print("   • 或在交付包中包含Python运行时")
    print("   • 已包含bellhop二进制文件，无需额外配置")

def check_python_availability():
    """检查当前Python环境"""
    print("\n" + "="*60)
    print("🐍 当前Python环境信息:")
    print(f"   版本: {sys.version}")
    print(f"   执行文件: {sys.executable}")
    print(f"   安装路径: {sys.prefix}")
    
    # 检查关键库
    key_modules = ['numpy', 'scipy', 'nuitka']
    print("\n📦 关键依赖包:")
    
    for module in key_modules:
        try:
            __import__(module)
            print(f"   ✅ {module}")
        except ImportError:
            print(f"   ❌ {module} (未安装)")

def main():
    """主函数"""
    check_project_binaries()
    check_python_availability()
    
    print("\n" + "="*60)
    print("💡 建议:")
    print("1. 当前方案适合有Python环境的部署")
    print("2. 如需真正独立运行，考虑以下选项:")
    print("   a) 使用PyInstaller --onefile模式")
    print("   b) 使用Nuitka --standalone --onefile")
    print("   c) 在交付包中包含便携式Python")
    print("3. 或明确告知用户Python环境要求")

if __name__ == '__main__':
    main()
