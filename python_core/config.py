"""
Bellhop配置文件
"""
import os
from pathlib import Path

"""
Bellhop配置文件
"""
import os
from pathlib import Path

# 项目根目录和内置二进制文件路径
PROJECT_ROOT = Path(__file__).parent.parent
BUILTIN_BIN_DIR = PROJECT_ROOT / "bin"

# 优先使用项目内置的二进制文件
def get_binary_path():
    """获取二进制文件路径，优先使用项目内置版本"""
    
    # 1. 首先检查项目内置二进制目录
    builtin_bellhop = BUILTIN_BIN_DIR / "bellhop"
    if builtin_bellhop.exists():
        return str(BUILTIN_BIN_DIR)
    
    # 2. 如果项目内没有，检查系统PATH
    import shutil
    if shutil.which("bellhop"):
        return str(Path(shutil.which("bellhop")).parent)
    
    # 3. 检查常见安装路径
    possible_paths = [
        "/usr/local/bin",
        "/opt/at/bin", 
        "/usr/bin",
        "/home/shunli/pro/at/bin",  # 保留用户原有路径作为备选
    ]
    
    for path in possible_paths:
        bellhop_path = Path(path) / "bellhop"
        if bellhop_path.exists():
            return str(path)
    
    # 4. 如果都没找到，返回项目内置目录（即使为空）
    print(f"Warning: bellhop binary not found. Using project bin directory: {BUILTIN_BIN_DIR}")
    print("Please run: ./scripts/manage.sh binaries  # to collect binaries")
    return str(BUILTIN_BIN_DIR)

# 设置二进制文件路径
AtBinPath = get_binary_path()

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
