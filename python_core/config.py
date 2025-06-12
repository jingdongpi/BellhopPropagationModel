"""
Bellhop配置文件
"""
import os
from pathlib import Path

# Bellhop二进制文件路径
AtBinPath = "/home/shunli/pro/at/bin"

# 验证Bellhop二进制文件是否存在
bellhop_executable = os.path.join(AtBinPath, "bellhop")
if os.path.exists(bellhop_executable):
    print(f"Found Bellhop binary: {bellhop_executable}")
else:
    print(f"Bellhop binary not found: {bellhop_executable}")
    # 备用路径列表
    possible_paths = [
        "/usr/local/bin",
        "/opt/at/bin", 
        "/home/shunli/pro/AcousticFastAPI/at/bin",
        "/usr/bin"
    ]
    
    for path in possible_paths:
        bellhop_path = os.path.join(path, "bellhop")
        if os.path.exists(bellhop_path):
            AtBinPath = path
            print(f"Found Bellhop in alternative path: {bellhop_path}")
            break

# 工作目录配置 - 使用统一的项目管理
try:
    from .project import ensure_project_dirs, get_project_root, get_data_path, get_tmp_path
    ensure_project_dirs()
    WORK_DIR = str(Path(__file__).parent)
    DATA_DIR = get_data_path()
    TMP_DIR = get_tmp_path()
except ImportError:
    # 备用方案
    from pathlib import Path
    WORK_DIR = str(Path(__file__).parent)
    DATA_DIR = str(Path(__file__).parent.parent / "data")
    TMP_DIR = str(Path(__file__).parent.parent / "data" / "tmp")
    Path(TMP_DIR).mkdir(parents=True, exist_ok=True)

# 静默模式 - 生产环境不输出配置信息
