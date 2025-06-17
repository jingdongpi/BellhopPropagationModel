#!/bin/bash
set -ex

# Debian 11 x86_64 环境设置脚本

# 更新包列表
apt-get update

# 安装编译工具和基础包
apt-get install -y build-essential cmake gfortran git wget curl

# 安装 Python
PYTHON_VERSION=${1:-3.9}

echo "安装 Python $PYTHON_VERSION..."

# Debian 11 默认支持的 Python 版本
if [[ "$PYTHON_VERSION" == "3.9" ]]; then
  apt-get install -y python3.9 python3.9-dev python3-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.10" ]]; then
  # 尝试从包管理器安装，失败则从源码编译
  if apt-get install -y python3.10 python3.10-dev; then
    ln -sf /usr/bin/python3.10 /usr/local/bin/python
  else
    echo "从源码编译 Python 3.10..."
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
                       libnss3-dev libssl-dev libreadline-dev libffi-dev \
                       libsqlite3-dev wget libbz2-dev
    cd /tmp
    wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz
    tar xzf Python-3.10.12.tgz
    cd Python-3.10.12
    ./configure --enable-optimizations --prefix=/usr/local
    make -j$(nproc)
    make altinstall
    ln -sf /usr/local/bin/python3.10 /usr/local/bin/python
  fi
else
  # 对于其他版本（3.8, 3.11, 3.12），从源码编译
  echo "Python $PYTHON_VERSION 需要从源码编译..."
  apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
                     libnss3-dev libssl-dev libreadline-dev libffi-dev \
                     libsqlite3-dev wget libbz2-dev
  
  # 选择合适的下载版本
  case $PYTHON_VERSION in
    3.8)
      DOWNLOAD_VERSION="3.8.18"
      ;;
    3.11)
      DOWNLOAD_VERSION="3.11.7"
      ;;
    3.12)
      DOWNLOAD_VERSION="3.12.1"
      ;;
    *)
      DOWNLOAD_VERSION="${PYTHON_VERSION}.0"
      ;;
  esac
  
  cd /tmp
  wget https://www.python.org/ftp/python/${DOWNLOAD_VERSION}/Python-${DOWNLOAD_VERSION}.tgz
  tar xzf Python-${DOWNLOAD_VERSION}.tgz
  cd Python-${DOWNLOAD_VERSION}
  ./configure --enable-optimizations --prefix=/usr/local
  make -j$(nproc)
  make altinstall
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
fi

# 确保 pip 可用
if ! command -v pip &> /dev/null; then
  echo "安装 pip..."
  # 根据 Python 版本选择合适的 pip 安装脚本
  case $PYTHON_VERSION in
    3.8)
      echo "使用 Python 3.8 专用的 pip 安装脚本..."
      curl https://bootstrap.pypa.io/pip/3.8/get-pip.py -o get-pip.py
      ;;
    *)
      echo "使用最新的 pip 安装脚本..."
      curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
      ;;
  esac
  python get-pip.py
  rm get-pip.py
fi

# 验证 Python 安装
echo "验证 Python 安装..."
python --version
python -c "import sys; print(f'Python executable: {sys.executable}')"

# 安装 Python 依赖
echo "安装 Python 依赖..."
python -m pip install --upgrade pip
python -m pip install nuitka wheel setuptools

# 安装 NumPy 和 SciPy
echo "安装 NumPy 和 SciPy..."
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install numpy scipy
fi

echo "=== Debian 11 x86_64 环境设置完成 ==="
python --version
python -c "import numpy; print(f'NumPy version: {numpy.__version__}')"
