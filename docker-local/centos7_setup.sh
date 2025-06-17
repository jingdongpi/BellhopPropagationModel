#!/bin/bash
set -ex

# CentOS 7 x86_64 环境设置脚本

# 安装 EPEL 和基础工具
yum install -y epel-release centos-release-scl
yum update -y

# 安装编译工具
yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran
yum install -y cmake3 make git wget

# 创建符号链接
ln -sf /usr/bin/cmake3 /usr/bin/cmake

# 激活 devtoolset-7
source /opt/rh/devtoolset-7/enable
echo 'source /opt/rh/devtoolset-7/enable' >> ~/.bashrc

# 安装 Python
PYTHON_VERSION=${1:-3.8}
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  yum install -y python38 python38-devel python38-pip
  ln -sf /usr/bin/python3.8 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  yum install -y python39 python39-devel python39-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
else
  # 从源码编译其他版本
  yum install -y openssl-devel libffi-devel zlib-devel
  cd /tmp
  wget https://www.python.org/ftp/python/${PYTHON_VERSION}.0/Python-${PYTHON_VERSION}.0.tgz
  tar xzf Python-${PYTHON_VERSION}.0.tgz
  cd Python-${PYTHON_VERSION}.0
  ./configure --enable-optimizations --prefix=/usr/local
  make -j$(nproc)
  make altinstall
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
fi

# 安装 Python 依赖
python -m pip install --upgrade pip
python -m pip install nuitka wheel setuptools

# 安装 NumPy 和 SciPy（根据 Python 版本）
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install "numpy>=2.0.0" scipy
fi

echo "=== CentOS 7 x86_64 环境设置完成 ==="
