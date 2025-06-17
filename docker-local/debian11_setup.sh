#!/bin/bash
set -ex

# Debian 11 x86_64 环境设置脚本

# 更新包列表
apt-get update

# 安装编译工具
apt-get install -y build-essential cmake gfortran git wget

# 安装 Python
PYTHON_VERSION=${1:-3.9}

# Debian 11 默认支持的 Python 版本
if [[ "$PYTHON_VERSION" == "3.9" ]]; then
  apt-get install -y python3.9 python3.9-dev python3-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.10" ]]; then
  apt-get install -y python3.10 python3.10-dev python3-pip
  ln -sf /usr/bin/python3.10 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.11" ]]; then
  apt-get install -y python3.11 python3.11-dev python3-pip
  ln -sf /usr/bin/python3.11 /usr/local/bin/python
else
  # 对于不支持的版本，从源码编译
  echo "Python $PYTHON_VERSION 不在 Debian 11 默认仓库中，从源码编译..."
  apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
                     libnss3-dev libssl-dev libreadline-dev libffi-dev \
                     libsqlite3-dev wget libbz2-dev
  
  cd /tmp
  wget https://www.python.org/ftp/python/${PYTHON_VERSION}.0/Python-${PYTHON_VERSION}.0.tgz
  tar xzf Python-${PYTHON_VERSION}.0.tgz
  cd Python-${PYTHON_VERSION}.0
  ./configure --enable-optimizations --prefix=/usr/local
  make -j$(nproc)
  make altinstall
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
  
  # 安装 pip
  wget https://bootstrap.pypa.io/get-pip.py
  /usr/local/bin/python${PYTHON_VERSION} get-pip.py
fi

# 安装 Python 依赖
python -m pip install --upgrade pip
python -m pip install nuitka wheel setuptools

# 安装 NumPy 和 SciPy
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install "numpy>=2.0.0" scipy
fi

echo "=== Debian 11 x86_64 环境设置完成 ==="
