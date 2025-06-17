#!/bin/bash
# CentOS 8 ARM64 环境设置脚本
set -ex

# 替换软件源（CentOS 8 已EOL）
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* || true
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* || true

# 安装基础工具
dnf update -y
dnf groupinstall -y "Development Tools"
dnf install -y cmake gcc-c++ gcc-gfortran git wget

# 安装 Python
PYTHON_VERSION=${1:-3.8}
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  dnf install -y python38 python38-devel python38-pip
  ln -sf /usr/bin/python3.8 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  dnf install -y python39 python39-devel python39-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
else
  # 从源码编译其他版本
  dnf install -y openssl-devel libffi-devel zlib-devel
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

# 安装 NumPy 和 SciPy
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install "numpy>=2.0.0" scipy
fi

echo "=== CentOS 8 ARM64 环境设置完成 ==="
