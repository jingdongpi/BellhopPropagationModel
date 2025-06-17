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
PYTHON_VERSION=${1:-3.9}

echo "安装 Python $PYTHON_VERSION..."

if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  dnf install -y python38 python38-devel python38-pip
  ln -sf /usr/bin/python3.8 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  dnf install -y python39 python39-devel python39-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
else
  # 从源码编译其他版本 (3.10, 3.11, 3.12)
  echo "Python $PYTHON_VERSION 需要从源码编译..."
  dnf install -y openssl-devel libffi-devel zlib-devel bzip2-devel \
                 readline-devel sqlite-devel xz-devel tk-devel \
                 gdbm-devel libuuid-devel
  
  # 选择合适的下载版本
  case $PYTHON_VERSION in
    3.10)
      DOWNLOAD_VERSION="3.10.12"
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
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  python get-pip.py
  rm get-pip.py
fi

# 验证 Python 安装
echo "验证 Python 安装..."
python --version
python -c "import sys; print(f'Python executable: {sys.executable}')"
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
