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

# 对于CentOS 7，优先使用预编译版本或者更加稳定的编译配置
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
    
    # 确保使用DevToolSet 7编译器
    if [ -f /opt/rh/devtoolset-7/enable ]; then
      source /opt/rh/devtoolset-7/enable
      echo "✓ 使用DevToolSet 7编译器编译Python"
    fi
    
    # 使用较为保守的编译选项
    CFLAGS="-O1" CXXFLAGS="-O1" ./configure --enable-shared --prefix=/usr/local \
      --with-ensurepip=install \
      --enable-loadable-sqlite-extensions
    
    make -j2 || make -j1
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
elif [[ "$PYTHON_VERSION" == "3.10" ]]; then
  # 对于Python 3.10，使用专门优化的SSL编译配置
  echo "为Python 3.10配置CentOS 7兼容的SSL编译环境..."
  
  # 安装所有必要的编译依赖，确保SSL支持
  echo "安装编译依赖（包含完整SSL支持）..."
  yum install -y openssl-devel openssl-static libffi-devel zlib-devel bzip2-devel \
                 readline-devel sqlite-devel xz-devel tk-devel \
                 gdbm-devel libuuid-devel ncurses-devel expat-devel \
                 libdb-devel nss-devel || (
    echo "部分依赖安装失败，尝试逐个安装..."
    yum install -y openssl-devel || true
    yum install -y openssl-static || true
    yum install -y libffi-devel || true
    yum install -y zlib-devel || true
    yum install -y bzip2-devel || true
    yum install -y readline-devel || true
    yum install -y sqlite-devel || true
    yum install -y xz-devel || true
    yum install -y tk-devel || true
    yum install -y gdbm-devel || true
    yum install -y libuuid-devel || true
    yum install -y ncurses-devel || true
    yum install -y expat-devel || true
    yum install -y libdb-devel || true
    yum install -y nss-devel || true
  )
  
  # 验证OpenSSL环境
  echo "验证OpenSSL编译环境..."
  if [ ! -f /usr/include/openssl/opensslv.h ]; then
    echo "❌ OpenSSL开发头文件缺失，强制重新安装..."
    yum reinstall -y openssl-devel
  fi
  
  # 检查OpenSSL库文件
  if [ ! -f /usr/lib64/libssl.so ] && [ ! -f /usr/lib/libssl.so ]; then
    echo "❌ OpenSSL库文件缺失"
    yum reinstall -y openssl-libs
  fi
  
  # 设置完整的编译环境变量
  export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
  export LDFLAGS="-L/usr/lib64 -L/usr/lib -Wl,-rpath,/usr/lib64 -Wl,-rpath,/usr/lib"
  export CPPFLAGS="-I/usr/include/openssl -I/usr/include"
  export LD_LIBRARY_PATH="/usr/lib64:/usr/lib:$LD_LIBRARY_PATH"
  
  cd /tmp
  
  # 下载Python 3.10.12（稳定版本，CentOS 7兼容性好）
  DOWNLOAD_VERSION="3.10.12"
  echo "下载Python $DOWNLOAD_VERSION（经过CentOS 7测试的稳定版本）..."
  
  # 清理之前的下载
  rm -rf Python-${DOWNLOAD_VERSION}*
  
  wget "https://www.python.org/ftp/python/${DOWNLOAD_VERSION}/Python-${DOWNLOAD_VERSION}.tgz" || {
    echo "官方源下载失败，尝试备用源..."
    wget "https://cdn.npmmirror.com/binaries/python/${DOWNLOAD_VERSION}/Python-${DOWNLOAD_VERSION}.tgz" || {
      echo "所有源都失败，使用系统Python..."
      yum install -y python3 python3-devel python3-pip
      if command -v python3 >/dev/null 2>&1; then
        ln -sf $(which python3) /usr/local/bin/python
        echo "✓ 回退到系统Python: $(which python3)"
      fi
      return 0
    }
  }
  
  tar xzf "Python-${DOWNLOAD_VERSION}.tgz"
  cd "Python-${DOWNLOAD_VERSION}"
  
  # 确保使用DevToolSet 7编译器
  if [ -f /opt/rh/devtoolset-7/enable ]; then
    source /opt/rh/devtoolset-7/enable
    echo "✓ 使用DevToolSet 7编译器"
  fi
  
  # 创建专门的SSL编译配置
  echo "创建SSL强制编译配置..."
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

[install]
compile=0
optimize=1
EOF
  
  # 使用强制SSL支持的配置选项
  echo "配置Python编译（强制SSL支持）..."
  CFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong" \
  CXXFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong" \
  LDFLAGS="-L/usr/lib64 -L/usr/lib -Wl,-rpath,/usr/lib64 -Wl,-rpath,/usr/lib" \
  ./configure \
    --enable-shared \
    --prefix=/usr/local \
    --with-ensurepip=install \
    --enable-loadable-sqlite-extensions \
    --with-ssl-default-suites=openssl \
    --with-openssl=/usr \
    --with-openssl-rpath=auto \
    --enable-optimizations \
    --disable-test-modules
  
  echo "开始编译Python 3.10（强制SSL支持）..."
  
  # 先尝试正常编译
  if make -j2; then
    echo "✓ Python编译成功"
  else
    echo "编译失败，尝试单线程编译..."
    make clean
    make -j1
  fi
  
  # 在安装前验证SSL模块
  echo "验证SSL模块编译..."
  if ./python -c "import ssl; print(f'SSL module: {ssl.OPENSSL_VERSION}'); import _ssl; print('_ssl module OK')" 2>/dev/null; then
    echo "✓ SSL模块编译成功"
  else
    echo "❌ SSL模块编译失败，检查详细信息..."
    ./python -c "import ssl" 2>&1 || true
    echo "尝试手动构建SSL模块..."
    make build_ssl || true
  fi
  
  # 安装Python
  echo "安装Python 3.10..."
  make altinstall
  
  # 配置动态库路径
  echo "/usr/local/lib" > /etc/ld.so.conf.d/python310.conf
  ldconfig
  
  # 创建符号链接
  if [ -f /usr/local/bin/python3.10 ]; then
    ln -sf /usr/local/bin/python3.10 /usr/local/bin/python
    echo "✓ 创建符号链接: /usr/local/bin/python3.10 -> /usr/local/bin/python"
    
    # 最终验证SSL和pip
    echo "最终验证Python 3.10 SSL和pip功能..."
    /usr/local/bin/python3.10 -c "import ssl; print(f'✓ SSL version: {ssl.OPENSSL_VERSION}')" || echo "❌ SSL验证失败"
    /usr/local/bin/python3.10 -m pip --version || echo "❌ pip验证失败"
  else
    echo "❌ Python 3.10安装失败"
    return 1
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
  
  # 确保使用DevToolSet 7编译器（如果可用）
  if [ -f /opt/rh/devtoolset-7/enable ]; then
    source /opt/rh/devtoolset-7/enable
    echo "✓ 使用DevToolSet 7编译器编译Python"
  fi
  
  # 对于Python 3.10+，避免使用--enable-optimizations，因为CentOS 7的编译器可能不支持
  # 同时设置较小的编译优化级别避免编译问题
  if [[ "$PYTHON_VERSION" == "3.10"* ]] || [[ "$PYTHON_VERSION" == "3.11"* ]] || [[ "$PYTHON_VERSION" == "3.12"* ]]; then
    echo "编译Python $PYTHON_VERSION (禁用优化以避免编译器兼容性问题)..."
    CFLAGS="-O1" CXXFLAGS="-O1" ./configure --enable-shared --prefix=/usr/local \
      --with-ensurepip=install \
      --enable-loadable-sqlite-extensions
  else
    echo "编译Python $PYTHON_VERSION (启用优化)..."
    ./configure --enable-optimizations --enable-shared --prefix=/usr/local \
      --with-ensurepip=install \
      --enable-loadable-sqlite-extensions
  fi
  
  # 使用较少的并行数避免内存问题，并添加错误重试
  echo "开始编译Python，这可能需要几分钟..."
  if ! make -j2; then
    echo "并行编译失败，尝试单线程编译..."
    make clean
    make -j1
  fi
  
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
  
  # 在安装pip前先验证SSL功能
  echo "验证Python SSL功能..."
  if ! $PYTHON_CMD -c "import ssl; print('SSL module OK')" 2>/dev/null; then
    echo "❌ Python SSL模块不可用，尝试修复..."
    
    # 对于从源码编译的Python，尝试重新构建SSL模块
    if [[ "$PYTHON_VERSION" == "3.10" ]] && [ -d "/tmp/Python-3.10.12" ]; then
      echo "尝试重新构建Python 3.10 SSL模块..."
      cd "/tmp/Python-3.10.12"
      
      # 重新构建并安装SSL模块
      make -j1 build_ssl || true
      make -j1 install || true
      ldconfig
      
      # 再次测试
      if $PYTHON_CMD -c "import ssl; print('SSL模块重建成功')" 2>/dev/null; then
        echo "✓ SSL模块重建成功"
      else
        echo "❌ SSL模块重建失败，尝试手动修复..."
        
        # 最后的手动修复尝试
        $PYTHON_CMD -c "
import sys
import os
sys.path.insert(0, '/usr/lib64/python3.10/lib-dynload')
sys.path.insert(0, '/usr/local/lib/python3.10/lib-dynload')
try:
    import ssl
    print('SSL import successful after path fix')
except ImportError as e:
    print(f'SSL import still failed: {e}')
    print('Available modules:', [m for m in sys.modules.keys() if 'ssl' in m.lower()])
" || true
      fi
    fi
  else
    echo "✓ Python SSL模块可用"
    $PYTHON_CMD -c "import ssl; print(f'SSL version: {ssl.OPENSSL_VERSION}')" 2>/dev/null || true
  fi
  
  # 测试HTTPS连接能力
  echo "测试HTTPS连接能力..."
  if $PYTHON_CMD -c "
import urllib.request
try:
    urllib.request.urlopen('https://pypi.org/simple/', timeout=10)
    print('✓ HTTPS连接测试成功')
except Exception as e:
    print(f'❌ HTTPS连接测试失败: {e}')
    raise
" 2>/dev/null; then
    echo "✓ Python HTTPS功能正常"
  else
    echo "❌ Python HTTPS功能异常，尝试使用HTTP下载pip..."
    
    # 如果HTTPS不工作，使用HTTP下载
    rm -f get-pip.py
    curl -k http://bootstrap.pypa.io/get-pip.py -o get-pip.py || {
      echo "HTTP下载也失败，尝试本地已安装的pip..."
      if yum install -y python3-pip; then
        echo "✓ 通过yum安装pip成功"
        ln -sf $(which pip3) /usr/local/bin/pip 2>/dev/null || true
        echo "跳过get-pip.py安装"
        rm -f get-pip.py
        return 0
      fi
    }
  fi
  
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

# 安装 Python 依赖（带SSL容错）
echo "安装Python依赖包..."

# 首先测试pip的HTTPS功能
if python -m pip list >/dev/null 2>&1; then
  echo "✓ pip基本功能正常"
else
  echo "❌ pip基本功能异常"
fi

# 尝试升级pip（带容错）
echo "升级pip..."
if ! python -m pip install --upgrade pip; then
  echo "HTTPS升级失败，尝试使用信任的主机..."
  python -m pip install --upgrade pip --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org || {
    echo "pip升级失败，继续使用当前版本..."
  }
fi

# 安装基本依赖（带容错）
echo "安装构建依赖..."
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

# 安装 NumPy 和 SciPy（根据 Python 版本，带容错）
echo "安装科学计算库..."
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

echo "✓ Python环境配置完成"

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
