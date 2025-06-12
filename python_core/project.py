"""
Bellhop项目管理模块 - 生产环境统一版本
集成目录管理、路径配置和工具函数
"""
import os
from pathlib import Path

class BellhopProject:
    """Bellhop项目统一管理类"""
    
    def __init__(self):
        # 自动检测项目根目录
        current_file = Path(__file__).resolve()
        self.root = current_file.parent.parent
        
        # 定义项目路径
        self.data_dir = self.root / 'data'
        self.tmp_dir = self.data_dir / 'tmp'
        self.lib_dir = self.root / 'lib'
        self.examples_dir = self.root / 'examples'
    
    def ensure_dirs(self):
        """确保必要目录存在"""
        for dir_path in [self.data_dir, self.tmp_dir, self.lib_dir, self.examples_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
    
    def get_temp_file(self, filename):
        """获取临时文件路径"""
        self.tmp_dir.mkdir(parents=True, exist_ok=True)
        return str(self.tmp_dir / filename)

# 全局实例
_project = BellhopProject()

# 公共接口
def ensure_project_dirs():
    """确保项目目录存在"""
    _project.ensure_dirs()

def get_project_root():
    """获取项目根目录"""
    return str(_project.root)

def get_data_path():
    """获取数据目录路径"""
    return str(_project.data_dir)

def get_tmp_path():
    """获取临时目录路径"""
    return str(_project.tmp_dir)

def get_temp_file_path(filename):
    """获取临时文件路径"""
    return _project.get_temp_file(filename)

def ensure_dir(file_path):
    """确保文件路径的目录存在"""
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        os.makedirs(directory, exist_ok=True)

# 向后兼容的别名
ensure_data_dirs = ensure_project_dirs
get_project_path = lambda name: str(getattr(_project, f'{name}_dir', _project.root))
