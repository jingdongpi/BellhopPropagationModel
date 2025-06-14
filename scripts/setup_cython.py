#!/usr/bin/env python3
"""
Cython编译脚本
将Python核心模块编译为Cython扩展
"""

from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
import numpy
import os
import shutil

# 尝试导入Cython，如果不存在则安装
try:
    from Cython.Build import cythonize
except ImportError:
    import subprocess
    import sys
    print("Cython not found, installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Cython"])
    from Cython.Build import cythonize

# 项目根目录 (setup_cython.py在scripts/目录下，需要回到上级目录)
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)  # 回到项目根目录

# 切换到项目根目录，使用相对路径
os.chdir(project_root)

# 使用相对路径定义目录
python_core_dir = "python_core"
python_wrapper_dir = "python_wrapper"
lib_dir = "lib"

# 自定义build_ext命令，将.so文件输出到lib/目录
class CustomBuildExt(build_ext):
    def run(self):
        # 先正常编译
        super().run()
        
        # 确保lib目录存在
        os.makedirs(lib_dir, exist_ok=True)
        
        # 将生成的.so文件移动到lib目录
        for ext in self.extensions:
            fullname = self.get_ext_fullname(ext.name)
            filename = self.get_ext_filename(fullname)
            
            # 查找可能的.so文件位置
            possible_paths = [
                os.path.join(self.build_lib, filename),  # 标准build位置
                filename,  # 根目录 (--inplace模式)
                os.path.basename(filename),  # 当前目录
            ]
            
            src_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    src_path = path
                    break
            
            if src_path:
                dst_path = os.path.join(lib_dir, os.path.basename(filename))
                print(f"Moving {src_path} to {dst_path}")
                shutil.move(src_path, dst_path)
                print(f"Cython extension {ext.name} compiled to {dst_path}")
            else:
                print(f"Warning: Could not find compiled extension {filename}")
                print(f"Searched in: {possible_paths}")

# 定义扩展模块
extensions = [
    Extension(
        "bellhop_cython_core",
        sources=[
            os.path.join(python_wrapper_dir, "bellhop_wrapper.py"),
        ],
        include_dirs=[
            numpy.get_include(),
            python_core_dir,
        ],
        define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")],
        language_level=3,
    ),
    Extension(
        "bellhop_core_modules",
        sources=[
            os.path.join(python_core_dir, "bellhop.py"),
            os.path.join(python_core_dir, "env.py"),
            os.path.join(python_core_dir, "readwrite.py"),
            os.path.join(python_core_dir, "config.py"),
        ],
        include_dirs=[
            numpy.get_include(),
        ],
        define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")],
        language_level=3,
    ),
]

# Cython编译指令
compiler_directives = {
    'language_level': 3,
    'boundscheck': False,
    'wraparound': False,
    'nonecheck': False,
    'cdivision': True,
    'embedsignature': True,
    'optimize.use_switch': True,
    'optimize.unpack_method_calls': True,
}

setup(
    name="BellhopCythonCore",
    ext_modules=cythonize(
        extensions,
        compiler_directives=compiler_directives,
        build_dir="build_cython",
        language_level=3,
    ),
    cmdclass={'build_ext': CustomBuildExt},
    zip_safe=False,
    include_dirs=[numpy.get_include()],
)
