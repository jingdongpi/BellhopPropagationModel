# Debian 11 ARM64 环境设置脚本
#!/bin/bash
set -ex

# 更新包列表
apt-get update

# 安装编译工具
apt-get install -y build-essential cmake gfortran git wget

# 安装 Python
PYTHON_VERSION=${1:-3.8}
apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python3-pip

# 创建符号链接
ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python

# 安装 Python 依赖
python -m pip install --upgrade pip
python -m pip install nuitka wheel setuptools

# 安装 NumPy 和 SciPy
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install "numpy>=2.0.0" scipy
fi

echo "=== Debian 11 ARM64 环境设置完成 ==="
