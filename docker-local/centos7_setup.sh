#!/bin/bash
set -ex

# CentOS 7 x86_64 环境设置脚本

# 修复 CentOS 7 EOL 仓库问题
echo "修复 CentOS 7 EOL 仓库问题..."
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# 清理并重建 yum 缓存
yum clean all
yum makecache

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

echo "安装 Python $PYTHON_VERSION..."

if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  yum install -y python38 python38-devel python38-pip
  ln -sf /usr/bin/python3.8 /usr/local/bin/python
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  yum install -y python39 python39-devel python39-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
else
  # 从源码编译其他版本 (3.10, 3.11, 3.12)
  echo "Python $PYTHON_VERSION 需要从源码编译..."
  yum install -y openssl-devel libffi-devel zlib-devel bzip2-devel \
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
  ./configure --enable-optimizations --enable-shared --prefix=/usr/local
  make -j$(nproc)
  make altinstall
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
  
  # 确保动态库可以被找到
  echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf
  ldconfig
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
fi

# 确保 pip 可用
if ! command -v pip &> /dev/null; then
  echo "安装 pip..."
  # 根据 Python 版本选择合适的 pip 安装脚本
  case $PYTHON_VERSION in
    3.6)
      echo "使用 Python 3.6 专用的 pip 安装脚本..."
      curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
      ;;
    3.7)
      echo "使用 Python 3.7 专用的 pip 安装脚本..."
      curl https://bootstrap.pypa.io/pip/3.7/get-pip.py -o get-pip.py
      ;;
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
python -m pip install --upgrade pip
python -m pip install nuitka wheel setuptools

# 安装 NumPy 和 SciPy（根据 Python 版本）
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  python -m pip install "numpy>=1.20.0,<2.0.0" scipy
else
  python -m pip install "numpy>=2.0.0" scipy
fi

echo "=== CentOS 7 x86_64 环境设置完成 ==="
