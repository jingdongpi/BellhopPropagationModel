#!/bin/bash
set -ex

# CentOS 7 x86_64 环境设置脚本

# 修复 CentOS 7 EOL 仓库问题（彻底重建）
echo "修复 CentOS 7 EOL 仓库问题..."

# 备份原始仓库文件
cp -r /etc/yum.repos.d /etc/yum.repos.d.backup 2>/dev/null || true

# 完全清理现有仓库配置，避免冲突和重复
echo "清理现有仓库配置..."
rm -f /etc/yum.repos.d/CentOS-*.repo
rm -f /etc/yum.repos.d/*scl*.repo
rm -f /etc/yum.repos.d/*SCL*.repo
rm -f /etc/yum.repos.d/epel*.repo
rm -f /etc/yum.repos.d/*AliYun*.repo

# 清理yum缓存
yum clean all || true

# 创建国内镜像源配置（使用阿里云镜像）
cat > /etc/yum.repos.d/CentOS-AliYun.repo << 'EOF'
[base]
name=CentOS-7 - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/os/x86_64/
        http://mirrors.cloud.aliyuncs.com/centos/7/os/x86_64/
        http://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-7 - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/updates/x86_64/
        http://mirrors.cloud.aliyuncs.com/centos/7/updates/x86_64/
        http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/extras/x86_64/
        http://mirrors.cloud.aliyuncs.com/centos/7/extras/x86_64/
        http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-7 - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/centosplus/x86_64/
        http://mirrors.cloud.aliyuncs.com/centos/7/centosplus/x86_64/
        http://vault.centos.org/7.9.2009/centosplus/x86_64/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

[sclo-rh]
name=CentOS-7 - SCLo rh
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/sclo/x86_64/rh/
        http://vault.centos.org/7.9.2009/sclo/x86_64/rh/
gpgcheck=1
enabled=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-SIG-SCLo

[sclo-sclo]
name=CentOS-7 - SCLo sclo
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7/sclo/x86_64/sclo/
        http://vault.centos.org/7.9.2009/sclo/x86_64/sclo/
gpgcheck=1
enabled=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-SIG-SCLo

[epel]
name=Extra Packages for Enterprise Linux 7 - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/epel/7/x86_64/
        http://mirrors.cloud.aliyuncs.com/epel/7/x86_64/
        https://dl.fedoraproject.org/pub/epel/7/x86_64/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/epel/RPM-GPG-KEY-EPEL-7
EOF

# 重建 yum 缓存
echo "重建yum缓存..."
yum clean all
yum makecache || (
    echo "⚠️  makecache失败，尝试基础缓存..."
    yum makecache fast || true
)

# 测试仓库连接
echo "测试仓库连接..."
yum repolist enabled || (
    echo "⚠️  repolist失败，但继续安装..."
    true
)

# 跳过额外的仓库安装（已在配置文件中包含）
echo "✓ 所有仓库已配置完成"

# 系统更新（容错处理）
echo "系统更新..."
yum update -y || (
    echo "⚠️  yum update 失败，继续安装必要包..."
    true
)
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
  echo "Python 3.9 在 CentOS 7 中需要从源码编译..."
  # 先尝试yum安装，如果失败则从源码编译
  if yum install -y python39 python39-devel python39-pip 2>/dev/null; then
    echo "✓ 通过yum成功安装Python 3.9"
    # 创建python符号链接
    if command -v python3.9 >/dev/null 2>&1; then
      ln -sf $(which python3.9) /usr/local/bin/python
      echo "✓ 创建符号链接: $(which python3.9) -> /usr/local/bin/python"
    fi
  else
    echo "yum安装失败，从源码编译Python 3.9..."
    
    # 安装编译依赖
    yum install -y openssl-devel libffi-devel zlib-devel bzip2-devel \
                   readline-devel sqlite-devel xz-devel tk-devel \
                   gdbm-devel libuuid-devel
    
    cd /tmp
    wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz
    tar xzf Python-3.9.18.tgz
    cd Python-3.9.18
    ./configure --enable-optimizations --enable-shared --prefix=/usr/local
    make -j$(nproc)
    make altinstall
    
    # 确保动态库可以被找到
    echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf
    ldconfig
    
    # 创建python符号链接
    if [ -f /usr/local/bin/python3.9 ]; then
      ln -sf /usr/local/bin/python3.9 /usr/local/bin/python
      echo "✓ 创建符号链接: /usr/local/bin/python3.9 -> /usr/local/bin/python"
    fi
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
  echo "检测可用的Python解释器..."
  
  # 尝试多种Python命令检测
  PYTHON_CMD=""
  
  if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
    PYTHON_CMD="python${PYTHON_VERSION}"
    echo "✓ 找到: python${PYTHON_VERSION}"
  elif [ -f /usr/local/bin/python${PYTHON_VERSION} ]; then
    PYTHON_CMD="/usr/local/bin/python${PYTHON_VERSION}"
    echo "✓ 找到: /usr/local/bin/python${PYTHON_VERSION}"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
    echo "✓ 找到: python3"
    python3 --version
  elif [ -f /usr/local/bin/python ]; then
    PYTHON_CMD="/usr/local/bin/python"
    echo "✓ 找到: /usr/local/bin/python"
    /usr/local/bin/python --version
  elif command -v python >/dev/null 2>&1; then
    # 检查是否是Python 3
    if python --version 2>&1 | grep -q "Python 3"; then
      PYTHON_CMD="python"
      echo "✓ 找到: python (Python 3)"
      python --version
    else
      echo "⚠️  找到python但是Python 2版本，继续查找..."
    fi
  fi
  
  if [ -z "$PYTHON_CMD" ]; then
    echo "❌ 未找到合适的Python 3解释器"
    echo "调试信息："
    echo "  which python: $(which python 2>/dev/null || echo '未找到')"
    echo "  which python3: $(which python3 2>/dev/null || echo '未找到')"
    echo "  ls /usr/bin/python*: $(ls /usr/bin/python* 2>/dev/null || echo '未找到')"
    echo "  ls /usr/local/bin/python*: $(ls /usr/local/bin/python* 2>/dev/null || echo '未找到')"
    exit 1
  fi
  
  echo "使用 $PYTHON_CMD 运行 pip 安装脚本..."
  $PYTHON_CMD get-pip.py
  
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

# 测试仓库配置
echo "=== 测试仓库配置 ==="
yum repolist enabled | head -10
echo "可用的仓库数量: $(yum repolist enabled | grep -c "repolist:")"

echo "=== CentOS 7 环境设置完成 ==="
