#!/bin/bash
# CentOS 8 ARM64 环境设置脚本
set -ex

# 替换软件源（CentOS 8 已EOL）
echo "配置 CentOS 8 软件源..."
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* || true
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* || true

# 清理缓存并更新
dnf clean all || true
dnf makecache || true

# 安装基础工具
dnf update -y
dnf groupinstall -y "Development Tools"
dnf install -y cmake gcc-c++ gcc-gfortran git wget

# 安装 Python
PYTHON_VERSION=${1:-3.9}

echo "安装 Python $PYTHON_VERSION..."

if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  echo "安装 Python 3.8 系统包..."
  dnf install -y python38 python38-devel python38-pip
  ln -sf /usr/bin/python3.8 /usr/local/bin/python
  ln -sf /usr/bin/pip3.8 /usr/local/bin/pip || true
elif [[ "$PYTHON_VERSION" == "3.9" ]]; then
  echo "安装 Python 3.9 系统包..."
  dnf install -y python39 python39-devel python39-pip
  ln -sf /usr/bin/python3.9 /usr/local/bin/python
  ln -sf /usr/bin/pip3.9 /usr/local/bin/pip || true
else
  # 从源码编译其他版本 (3.10, 3.11, 3.12)
  echo "Python $PYTHON_VERSION 需要从源码编译..."
  
  # 安装完整的编译依赖，特别注意SSL支持
  dnf install -y openssl-devel libffi-devel zlib-devel bzip2-devel \
                 readline-devel sqlite-devel xz-devel tk-devel \
                 gdbm-devel libuuid-devel ncurses-devel expat-devel \
                 libdb-devel nss-devel
  
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
  echo "下载 Python ${DOWNLOAD_VERSION}..."
  
  # 清理之前的下载
  rm -rf Python-${DOWNLOAD_VERSION}*
  
  # 尝试多个下载源
  if ! wget --timeout=30 --tries=3 https://www.python.org/ftp/python/${DOWNLOAD_VERSION}/Python-${DOWNLOAD_VERSION}.tgz; then
    echo "官方源下载失败，尝试备用源..."
    wget --timeout=30 --tries=3 https://cdn.npmmirror.com/binaries/python/${DOWNLOAD_VERSION}/Python-${DOWNLOAD_VERSION}.tgz || {
      echo "下载失败，回退到系统Python..."
      dnf install -y python3 python3-devel python3-pip
      ln -sf /usr/bin/python3 /usr/local/bin/python
      return 0
    }
  fi
  
  tar xzf Python-${DOWNLOAD_VERSION}.tgz
  cd Python-${DOWNLOAD_VERSION}
  
  # 为Python 3.10+添加强制SSL配置
  if [[ "$PYTHON_VERSION" =~ ^3\.(1[0-9]|[2-9][0-9])$ ]]; then
    echo "配置Python ${PYTHON_VERSION} SSL强制编译..."
    
    # 创建强制SSL模块编译配置
    cat > Modules/Setup.local << 'EOF'
# 强制编译SSL模块
_ssl _ssl.c \
    -I/usr/include/openssl \
    -L/usr/lib64 -L/usr/lib \
    -lssl -lcrypto

_hashlib _hashopenssl.c \
    -I/usr/include/openssl \
    -L/usr/lib64 -L/usr/lib \
    -lssl -lcrypto
EOF

    # 创建setup.cfg配置
    cat > setup.cfg << 'EOF'
[build_ext]
include_dirs=/usr/include/openssl:/usr/include
library_dirs=/usr/lib64:/usr/lib
EOF
  fi
  
  echo "配置并编译 Python..."
  
  # 设置SSL相关环境变量
  export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:$PKG_CONFIG_PATH"
  export LDFLAGS="-L/usr/lib64 -L/usr/lib -Wl,-rpath,/usr/lib64"
  export CPPFLAGS="-I/usr/include/openssl"
  
  # 配置编译选项，确保SSL支持
  ./configure \
    --enable-optimizations \
    --prefix=/usr/local \
    --enable-shared \
    --with-ensurepip=install \
    --enable-loadable-sqlite-extensions \
    --with-ssl-default-suites=openssl \
    --with-openssl=/usr \
    --with-openssl-rpath=auto
  
  echo "开始编译Python ${PYTHON_VERSION}..."
  if ! make -j$(nproc); then
    echo "并行编译失败，尝试单线程编译..."
    make clean
    make -j1
  fi
  
  # 验证SSL模块编译
  echo "验证SSL模块编译..."
  if ./python -c "import ssl; print(f'SSL version: {ssl.OPENSSL_VERSION}')" 2>/dev/null; then
    echo "✓ SSL模块编译成功"
  else
    echo "❌ SSL模块编译失败，尝试手动构建..."
    make build_ssl || true
  fi
  
  make altinstall
  
  # 创建符号链接
  ln -sf /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python
  
  # 更新动态库路径
  echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf
  ldconfig
  
  # 验证安装
  echo "验证Python安装..."
  if /usr/local/bin/python${PYTHON_VERSION} -c "import ssl; print('✓ SSL module OK')" 2>/dev/null; then
    echo "✓ Python SSL功能正常"
  else
    echo "❌ Python SSL功能异常"
  fi
fi

# 确保 pip 可用（带SSL容错）
if ! command -v pip &> /dev/null; then
  echo "安装 pip..."
  
  # 首先测试Python的HTTPS功能
  if python -c "
import urllib.request
try:
    urllib.request.urlopen('https://pypi.org/simple/', timeout=10)
    print('✓ HTTPS连接正常')
except Exception as e:
    print(f'❌ HTTPS连接失败: {e}')
    raise
" 2>/dev/null; then
    echo "✓ Python HTTPS功能正常，使用HTTPS下载pip"
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  else
    echo "❌ Python HTTPS功能异常，使用备用方案..."
    # 尝试通过dnf安装
    if dnf install -y python3-pip; then
      echo "✓ 通过dnf安装pip成功"
      ln -sf /usr/bin/pip3 /usr/local/bin/pip 2>/dev/null || true
    else
      echo "尝试HTTP下载pip..."
      curl -k http://bootstrap.pypa.io/get-pip.py -o get-pip.py || {
        echo "所有pip安装方法都失败"
        exit 1
      }
    fi
  fi
  
  if [ -f get-pip.py ]; then
    python get-pip.py
    rm get-pip.py
  fi
fi

# 验证 Python 安装
echo "验证 Python 安装..."
python --version
python -c "import sys; print(f'Python executable: {sys.executable}')"

# 安装 Python 依赖（带SSL容错）
echo "安装Python依赖包..."

# 尝试升级pip（带容错）
if ! python -m pip install --upgrade pip; then
  echo "HTTPS升级失败，尝试使用信任的主机..."
  python -m pip install --upgrade pip --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org || {
    echo "pip升级失败，继续使用当前版本..."
  }
fi

# 安装基本依赖（带容错）
if ! python -m pip install nuitka wheel setuptools; then
  echo "HTTPS安装失败，使用信任主机方式..."
  python -m pip install nuitka wheel setuptools \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org || {
    echo "依赖安装失败，尝试国内镜像..."
    python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple nuitka wheel setuptools \
      --trusted-host pypi.tuna.tsinghua.edu.cn || {
      echo "所有方式都失败，继续构建（可能影响某些功能）..."
    }
  }
fi

# 安装 NumPy 和 SciPy（带容错）
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  NUMPY_SPEC="numpy>=1.20.0,<2.0.0"
else
  NUMPY_SPEC="numpy>=2.0.0"
fi

if ! python -m pip install "$NUMPY_SPEC" scipy; then
  echo "HTTPS安装科学库失败，使用信任主机方式..."
  python -m pip install "$NUMPY_SPEC" scipy \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org || {
    echo "科学库安装失败，尝试国内镜像..."
    python -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple "$NUMPY_SPEC" scipy \
      --trusted-host pypi.tuna.tsinghua.edu.cn || {
      echo "科学库安装失败，继续构建（可能影响某些功能）..."
    }
  }
fi

echo "=== CentOS 8 ARM64 环境设置完成 ==="
