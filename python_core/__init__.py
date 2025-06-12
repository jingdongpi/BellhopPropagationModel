"""
Bellhop声传播模型核心模块
从原始AcousticFastAPI项目复制的核心计算功能
"""

# 导入主要功能
try:
    from .bellhop import (
        call_Bellhop, 
        call_Bellhop_Rays, 
        calculate_transmission_loss,
        alphadiv,
        beamsnumber,
        find_cvgcRays
    )
    from .readwrite import read_shd, write_env, write_bathy, write_ssp
    from .project import ensure_project_dirs, get_project_root, get_tmp_path
except ImportError as e:
    print(f"Warning: Could not import some core modules: {e}")

__all__ = [
    'call_Bellhop',
    'call_Bellhop_Rays', 
    'calculate_transmission_loss',
    'alphadiv',
    'beamsnumber',
    'find_cvgcRays',
    'read_shd',
    'write_env', 
    'write_bathy',
    'write_ssp',
    'ensure_project_dirs',
    'get_project_root',
    'get_tmp_path'
]

__version__ = "1.0.0"
__author__ = "Acoustic Simulation Team"
