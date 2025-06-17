#!/bin/bash
set -ex

# CentOS 7 x86_64 环境设置脚本

# 修复 CentOS 7 EOL 仓库问题（全面修复）
echo "修复 CentOS 7 EOL 仓库问题..."

# 备份原始仓库文件
cp -r /etc/yum.repos.d /etc/yum.repos.d.backup || true

# 修复主要 CentOS 仓库
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# 修复 SCL 仓库问题
if [ -f /etc/yum.repos.d/CentOS-SCLo-scl.repo ]; then
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-SCLo-scl*.repo
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-SCLo-scl*.repo
fi

# 创建或更新 vault.centos.org 仓库配置
cat > /etc/yum.repos.d/CentOS-Vault.repo << 'EOF'
[base]
name=CentOS-7 - Base
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[centosplus]
name=CentOS-7 - Plus
baseurl=http://vault.centos.org/7.9.2009/centosplus/x86_64/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[sclo-rh]
name=CentOS-7 - SCLo rh
baseurl=http://vault.centos.org/7.9.2009/sclo/x86_64/rh/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOF

# 清理并重建 yum 缓存
yum clean all || true
yum makecache fast || yum makecache || true

# 安装 EPEL （使用备用方法）
echo "安装 EPEL..."
yum install -y epel-release || (
    echo "EPEL 安装失败，使用 rpm 直接安装..."
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true
)

# 安装 SCL
echo "安装 centos-release-scl..."
yum install -y centos-release-scl || (
    echo "SCL 安装失败，尝试手动配置..."
    rpm -Uvh http://vault.centos.org/7.9.2009/extras/x86_64/Packages/centos-release-scl-2-3.el7.centos.noarch.rpm || true
)

# 系统更新（容错处理）
echo "系统更新..."
yum update -y || (
    echo "⚠️  yum update 失败，继续安装必要包..."
    true
)

# 安装编译工具（容错处理）
echo "安装编译工具..."
yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran || (
    echo "DevToolSet 7 安装失败，尝试安装基础 gcc..."
    yum install -y gcc gcc-c++ gcc-gfortran || true
)

echo "安装其他构建工具..."
yum install -y cmake3 make git wget || (
    echo "部分工具安装失败，尝试逐个安装..."
    yum install -y make || true
    yum install -y git || true
    yum install -y wget || true
    yum install -y cmake3 || yum install -y cmake || true
)

# 创建符号链接（容错处理）
ln -sf /usr/bin/cmake3 /usr/bin/cmake 2>/dev/null || ln -sf /usr/bin/cmake /usr/bin/cmake || true

# 激活 devtoolset-7（如果可用）
if [ -f /opt/rh/devtoolset-7/enable ]; then
    source /opt/rh/devtoolset-7/enable
    echo 'source /opt/rh/devtoolset-7/enable' >> ~/.bashrc
    echo "✓ DevToolSet 7 已激活"
else
    echo "⚠️  DevToolSet 7 不可用，使用系统默认编译器"
fi

# 安装 Python
PYTHON_VERSION=${1:-3.8}

echo "安装 Python $PYTHON_VERSION..."

if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  yum install -y python38 python38-devel python38-pip || (
    echo "Python 3.8 yum 安装失败，尝试其他方法..."
    yum install -y python3 python3-devel python3-pip || true
  )
  # 创建python符号链接，优先使用具体版本
  if command -v python3.8 >/dev/null 2>&1; then
    ln -sf $(which python3.8) /usr/local/bin/python
    echo "✓ 创建符号链接: $(which python3.8) -> /usr/local/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    ln -sf $(which python3) /usr/local/bin/python
    echo "✓ 创建符号链接: $(which python3) -> /usr/local/bin/python"
  fi
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  yum install -y python39 python39-devel python39-pip || (
    echo "Python 3.9 yum 安装失败，尝试其他方法..."
    yum install -y python3 python3-devel python3-pip || true
  )
  # 创建python符号链接，优先使用具体版本
  if command -v python3.9 >/dev/null 2>&1; then
    ln -sf $(which python3.9) /usr/local/bin/python
    echo "✓ 创建符号链接: $(which python3.9) -> /usr/local/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    ln -sf $(which python3) /usr/local/bin/python
    echo "✓ 创建符号链接: $(which python3) -> /usr/local/bin/python"
  fi
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
  
  # 确保动态库可以被找到
  echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf
  ldconfig
  
  # 创建python符号链接
  if [ -f /usr/local/bin/python${PYTHON_VERSION} ]; then
    ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
    echo "✓ 创建符号链接: /usr/local/bin/python${PYTHON_VERSION} -> /usr/local/bin/python"
  fi
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
  
  # 使用正确的Python版本运行pip安装脚本
  if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
    echo "使用 python${PYTHON_VERSION} 运行 pip 安装脚本..."
    python${PYTHON_VERSION} get-pip.py
  elif [ -f /usr/local/bin/python${PYTHON_VERSION} ]; then
    echo "使用 /usr/local/bin/python${PYTHON_VERSION} 运行 pip 安装脚本..."
    /usr/local/bin/python${PYTHON_VERSION} get-pip.py
  elif command -v python3 >/dev/null 2>&1; then
    echo "使用 python3 运行 pip 安装脚本..."
    python3 get-pip.py
  else
    echo "❌ 未找到合适的Python 3解释器"
    exit 1
  fi
  
  rm get-pip.py
fi

# 验证 Python 安装
echo "验证 Python 安装..."

# 确保python命令指向正确的版本
if command -v python >/dev/null 2>&1; then
    echo "当前 python 命令: $(python --version)"
    echo "Python 路径: $(which python)"
else
    echo "⚠️  python 命令不可用，创建符号链接..."
    if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
        ln -sf $(which python${PYTHON_VERSION}) /usr/local/bin/python
    elif [ -f /usr/local/bin/python${PYTHON_VERSION} ]; then
        ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
    fi
fi

# 再次验证
python --version
python -c "import sys; print('Python executable:', sys.executable)"

# 验证pip
if command -v pip >/dev/null 2>&1; then
    echo "✓ pip 版本: $(pip --version)"
elif python -m pip --version >/dev/null 2>&1; then
    echo "✓ pip 模块: $(python -m pip --version)"
else
    echo "❌ pip 不可用"
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

# 验证安装结果
echo "=== 验证安装结果 ==="

# 检查编译器
if command -v gcc >/dev/null 2>&1; then
    echo "✓ gcc: $(gcc --version | head -1)"
else
    echo "❌ gcc 未安装"
fi

if command -v g++ >/dev/null 2>&1; then
    echo "✓ g++: $(g++ --version | head -1)"
else
    echo "❌ g++ 未安装"
fi

# 检查cmake
if command -v cmake >/dev/null 2>&1; then
    echo "✓ cmake: $(cmake --version | head -1)"
else
    echo "❌ cmake 未安装"
fi

# 检查Python
if command -v python >/dev/null 2>&1; then
    echo "✓ python: $(python --version)"
    echo "  路径: $(which python)"
else
    echo "❌ python 未安装"
fi

# 检查pip
if command -v pip >/dev/null 2>&1 || python -m pip --version >/dev/null 2>&1; then
    echo "✓ pip: $(python -m pip --version)"
else
    echo "❌ pip 未安装"
fi

echo "=== CentOS 7 环境设置完成 ==="
