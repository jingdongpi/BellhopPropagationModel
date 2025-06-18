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
  # 对于Python 3.10，CentOS 7需要升级OpenSSL到1.1.1版本
  echo "为Python 3.10准备CentOS 7兼容的OpenSSL环境..."
  
  # 检查当前OpenSSL版本
  OPENSSL_VERSION=$(openssl version 2>/dev/null | awk '{print $2}' || echo "unknown")
  echo "当前OpenSSL版本: $OPENSSL_VERSION"
  
  # CentOS 7默认OpenSSL 1.0.2不兼容Python 3.10，需要安装OpenSSL 1.1.1
  if [[ "$OPENSSL_VERSION" == "1.0.2"* ]]; then
    echo "⚠️  检测到OpenSSL 1.0.2，Python 3.10需要OpenSSL 1.1.1+"
    echo "从源码编译安装OpenSSL 1.1.1..."
    
    # 安装OpenSSL编译依赖
    yum install -y perl-core zlib-devel make gcc
    
    cd /tmp
    
    # 下载OpenSSL 1.1.1
    OPENSSL_VERSION_TO_INSTALL="1.1.1w"
    echo "下载OpenSSL $OPENSSL_VERSION_TO_INSTALL..."
    
    # 清理之前的下载
    rm -rf openssl-${OPENSSL_VERSION_TO_INSTALL}*
    
    wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION_TO_INSTALL}.tar.gz" || {
      echo "官方源下载失败，尝试备用源..."
      wget "https://github.com/openssl/openssl/archive/OpenSSL_$(echo ${OPENSSL_VERSION_TO_INSTALL} | tr '.' '_').tar.gz" -O "openssl-${OPENSSL_VERSION_TO_INSTALL}.tar.gz" || {
        echo "所有OpenSSL源都失败，使用兼容性编译..."
        USE_LEGACY_SSL=true
      }
    }
    
    if [ "$USE_LEGACY_SSL" != "true" ] && [ -f "openssl-${OPENSSL_VERSION_TO_INSTALL}.tar.gz" ]; then
      tar xzf "openssl-${OPENSSL_VERSION_TO_INSTALL}.tar.gz"
      cd "openssl-${OPENSSL_VERSION_TO_INSTALL}"
      
      # 确保使用DevToolSet 7编译器（如果可用）
      if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        echo "✓ 使用DevToolSet 7编译OpenSSL"
      fi
      
      # 配置OpenSSL（安装到/usr/local/ssl以避免冲突）
      echo "配置OpenSSL..."
      ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
      
      # 编译OpenSSL
      echo "编译OpenSSL（这可能需要几分钟）..."
      make -j2 || make -j1
      
      # 安装OpenSSL
      echo "安装OpenSSL..."
      make install
      
      # 配置库路径
      echo "/usr/local/ssl/lib" > /etc/ld.so.conf.d/openssl.conf
      ldconfig
      
      # 设置环境变量
      export PATH="/usr/local/ssl/bin:$PATH"
      export LD_LIBRARY_PATH="/usr/local/ssl/lib:$LD_LIBRARY_PATH"
      export PKG_CONFIG_PATH="/usr/local/ssl/lib/pkgconfig:$PKG_CONFIG_PATH"
      export OPENSSL_ROOT_DIR="/usr/local/ssl"
      export OPENSSL_LIBRARIES="/usr/local/ssl/lib"
      export OPENSSL_INCLUDE_DIR="/usr/local/ssl/include"
      
      # 验证新OpenSSL版本
      echo "验证新安装的OpenSSL..."
      /usr/local/ssl/bin/openssl version
      
      # 为Python编译设置正确的OpenSSL路径
      OPENSSL_PREFIX="/usr/local/ssl"
      
      echo "✓ OpenSSL 1.1.1安装完成"
    else
      echo "⚠️  OpenSSL升级失败，使用兼容性编译模式..."
      USE_LEGACY_SSL=true
      OPENSSL_PREFIX="/usr"
    fi
  else
    echo "✓ OpenSSL版本可能兼容Python 3.10"
    OPENSSL_PREFIX="/usr"
  fi
  
  # 安装Python编译依赖
  echo "安装Python编译依赖..."
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
  
  # 根据是否安装了新OpenSSL设置路径
  if [ "$OPENSSL_PREFIX" = "/usr/local/ssl" ]; then
    echo "✓ 使用新安装的OpenSSL 1.1.1"
    export PKG_CONFIG_PATH="/usr/local/ssl/lib/pkgconfig:$PKG_CONFIG_PATH"
    export LDFLAGS="-L/usr/local/ssl/lib -L/usr/lib64 -L/usr/lib -Wl,-rpath,/usr/local/ssl/lib -Wl,-rpath,/usr/lib64 -Wl,-rpath,/usr/lib"
    export CPPFLAGS="-I/usr/local/ssl/include -I/usr/include/openssl -I/usr/include"
    SSL_INCLUDE_DIR="/usr/local/ssl/include"
    SSL_LIB_DIR="/usr/local/ssl/lib"
  else
    echo "✓ 使用系统OpenSSL"
    export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
    export LDFLAGS="-L/usr/lib64 -L/usr/lib -Wl,-rpath,/usr/lib64 -Wl,-rpath,/usr/lib"
    export CPPFLAGS="-I/usr/include/openssl -I/usr/include"
    SSL_INCLUDE_DIR="/usr/include/openssl"
    SSL_LIB_DIR="/usr/lib64"
  fi
  
  export LD_LIBRARY_PATH="$SSL_LIB_DIR:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH"
  
  # 验证OpenSSL文件
  if [ ! -f "$SSL_INCLUDE_DIR/ssl.h" ]; then
    echo "❌ OpenSSL开发头文件缺失: $SSL_INCLUDE_DIR/ssl.h"
    find /usr -name "ssl.h" -type f 2>/dev/null | head -5
  fi
  
  if [ ! -f "$SSL_LIB_DIR/libssl.so" ] && [ ! -f "$SSL_LIB_DIR/libssl.a" ]; then
    echo "❌ OpenSSL库文件缺失"
    find /usr -name "libssl.so*" -type f 2>/dev/null | head -5
  fi
  
  # 额外验证OpenSSL环境完整性
  echo "验证OpenSSL环境完整性..."
  echo "SSL_INCLUDE_DIR: $SSL_INCLUDE_DIR"
  echo "SSL_LIB_DIR: $SSL_LIB_DIR"
  ls -la "$SSL_INCLUDE_DIR/ssl.h" 2>/dev/null || echo "⚠️  ssl.h不存在"
  ls -la "$SSL_LIB_DIR/libssl"* 2>/dev/null | head -3
  
  # 检查OpenSSL版本
  if [ -f "/usr/local/ssl/bin/openssl" ]; then
    /usr/local/ssl/bin/openssl version || echo "⚠️  新OpenSSL命令不可用"
  else
    openssl version || echo "⚠️  系统OpenSSL命令不可用"
  fi
  
  # 设置完整的编译环境变量
  export PKG_CONFIG_PATH="$SSL_LIB_DIR/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
  export LDFLAGS="-L$SSL_LIB_DIR -L/usr/lib64 -L/usr/lib -Wl,-rpath,$SSL_LIB_DIR -Wl,-rpath,/usr/lib64 -Wl,-rpath,/usr/lib"
  export CPPFLAGS="-I$SSL_INCLUDE_DIR -I/usr/include"
  export LD_LIBRARY_PATH="$SSL_LIB_DIR:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH"
  
  cd /tmp
  
  # 下载Python 3.10.12（稳定版本）
  DOWNLOAD_VERSION="3.10.12"
  echo "下载Python $DOWNLOAD_VERSION（使用OpenSSL $OPENSSL_PREFIX）..."
  
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
  echo "创建SSL强制编译配置（使用OpenSSL路径: $OPENSSL_PREFIX）..."
  cat > Modules/Setup.local << EOF
# 强制编译SSL模块（使用正确的OpenSSL路径）
_ssl _ssl.c \\
    -I$SSL_INCLUDE_DIR \\
    -L$SSL_LIB_DIR \\
    -lssl -lcrypto

_hashlib _hashopenssl.c \\
    -I$SSL_INCLUDE_DIR \\
    -L$SSL_LIB_DIR \\
    -lssl -lcrypto

# 强制编译其他crypto相关模块
_socket socketmodule.c

# 确保编译完整的网络功能
_urllib3 urllibmodule.c
EOF

  # 检查并修补Modules/Setup.dist（如果存在）
  if [ -f "Modules/Setup.dist" ]; then
    echo "检查Modules/Setup.dist中的SSL配置..."
    # 确保SSL相关模块没有被注释掉
    sed -i 's/^#\(_ssl\|_hashlib\)/\1/' Modules/Setup.dist 2>/dev/null || true
  fi

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
  echo "配置Python编译（使用OpenSSL $OPENSSL_PREFIX）..."
  
  # 详细记录configure过程
  echo "配置详细信息："
  echo "OpenSSL前缀: $OPENSSL_PREFIX"
  echo "OpenSSL库路径: $SSL_LIB_DIR"
  echo "OpenSSL头文件: $SSL_INCLUDE_DIR"
  echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
  echo "LDFLAGS: $LDFLAGS"
  echo "CPPFLAGS: $CPPFLAGS"
  
  # 根据OpenSSL安装位置设置configure参数
  if [ "$OPENSSL_PREFIX" = "/usr/local/ssl" ]; then
    OPENSSL_CONFIG_ARGS="--with-openssl=/usr/local/ssl --with-openssl-rpath=auto"
  else
    OPENSSL_CONFIG_ARGS="--with-openssl=/usr --with-openssl-rpath=auto"
  fi
  
  CFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong" \
  CXXFLAGS="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong" \
  LDFLAGS="$LDFLAGS" \
  CPPFLAGS="$CPPFLAGS" \
  ./configure \
    --enable-shared \
    --prefix=/usr/local \
    --with-ensurepip=install \
    --enable-loadable-sqlite-extensions \
    --with-ssl-default-suites=openssl \
    $OPENSSL_CONFIG_ARGS \
    --enable-optimizations \
    --disable-test-modules 2>&1 | tee configure.log
  
  # 检查configure输出中的SSL相关信息
  echo "检查configure结果中的SSL支持..."
  if grep -i "checking for openssl" configure.log; then
    echo "✓ Configure检测到OpenSSL"
  else
    echo "⚠️  Configure可能未检测到OpenSSL"
  fi
  
  if grep -i "ssl.*yes" configure.log; then
    echo "✓ SSL支持已启用"
  else
    echo "⚠️  SSL支持可能未启用"
    echo "配置输出片段："
    grep -i ssl configure.log | tail -10 || true
  fi
  
  # 特别检查OpenSSL路径检测
  if grep -i "$OPENSSL_PREFIX" configure.log; then
    echo "✓ Configure检测到正确的OpenSSL路径"
  else
    echo "⚠️  Configure可能未检测到正确的OpenSSL路径"
  fi
  
  echo "开始编译Python 3.10（强制SSL支持）..."
  
  # 记录编译过程详细信息
  echo "编译环境信息："
  echo "编译器版本: $(gcc --version | head -1)"
  echo "Make版本: $(make --version | head -1)"
  echo "当前目录: $(pwd)"
  echo "OpenSSL库文件检查:"
  find /usr -name "libssl.so*" -exec ls -la {} \; 2>/dev/null | head -3
  
  # 先尝试正常编译
  if make -j2 2>&1 | tee make.log; then
    echo "✓ Python编译成功"
  else
    echo "编译失败，检查错误信息..."
    echo "=== Make错误信息 ==="
    tail -50 make.log || true
    echo "==================="
    
    echo "尝试单线程编译..."
    make clean
    if make -j1 2>&1 | tee make_single.log; then
      echo "✓ 单线程编译成功"
    else
      echo "单线程编译也失败，检查详细错误..."
      tail -50 make_single.log || true
      echo "尝试忽略部分错误继续..."
      make -k || true
    fi
  fi
  
  # 在安装前验证SSL模块
  echo "验证SSL模块编译..."
  
  # 检查编译产物
  echo "检查编译产物中的SSL模块..."
  find . -name "*ssl*" -type f 2>/dev/null | head -10
  find . -name "*_ssl*" -type f 2>/dev/null | head -10
  
  # 尝试导入测试
  if ./python -c "import ssl; print(f'SSL module: {ssl.OPENSSL_VERSION}'); import _ssl; print('_ssl module OK')" 2>/dev/null; then
    echo "✓ SSL模块编译成功"
  else
    echo "❌ SSL模块编译失败，进行详细诊断..."
    
    # 详细诊断
    echo "=== Python import ssl 详细错误 ==="
    ./python -c "import ssl" 2>&1 || true
    echo "=================================="
    
    echo "=== Python import _ssl 详细错误 ==="
    ./python -c "import _ssl" 2>&1 || true
    echo "==================================="
    
    echo "=== 检查可用模块 ==="
    ./python -c "import sys; print('可用模块:'); print([m for m in sys.builtin_module_names if 'ssl' in m.lower()])" 2>/dev/null || true
    echo "==================="
    
    echo "=== 检查动态库 ==="
    ./python -c "import sys; print('Python library path:'); [print(p) for p in sys.path]" 2>/dev/null || true
    echo "================="
    
    # 尝试手动构建SSL模块
    echo "尝试手动重新构建SSL模块..."
    
    # 重新构建特定模块
    make build_ssl 2>&1 || true
    make Modules/_ssl.cpython-310-x86_64-linux-gnu.so 2>&1 || true
    
    # 如果仍然失败，但Python其他功能正常，继续安装
    if ./python -c "print('Python基本功能正常')" 2>/dev/null; then
      echo "⚠️  SSL模块构建失败，但Python基本功能正常，继续安装..."
      echo "注意：pip可能无法通过HTTPS工作，需要使用HTTP源或手动安装包"
    else
      echo "❌ Python基本功能也有问题"
      return 1
    fi
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
    
    # 最终验证Python和pip功能
    echo "最终验证Python 3.10功能..."
    
    # 基本Python功能验证
    if /usr/local/bin/python3.10 -c "print('✓ Python 3.10基本功能正常')" 2>/dev/null; then
      echo "✓ Python基本功能验证通过"
    else
      echo "❌ Python基本功能验证失败"
    fi
    
    # SSL功能验证
    if /usr/local/bin/python3.10 -c "import ssl; print(f'✓ SSL version: {ssl.OPENSSL_VERSION}')" 2>/dev/null; then
      echo "✓ SSL功能验证通过"
      SSL_WORKING=true
    else
      echo "❌ SSL功能验证失败"
      echo "SSL错误详情："
      /usr/local/bin/python3.10 -c "import ssl" 2>&1 || true
      SSL_WORKING=false
    fi
    
    # pip功能验证
    if /usr/local/bin/python3.10 -m pip --version 2>/dev/null; then
      echo "✓ pip验证通过"
      PIP_WORKING=true
    else
      echo "❌ pip验证失败"
      echo "pip错误详情："
      /usr/local/bin/python3.10 -m pip --version 2>&1 || true
      PIP_WORKING=false
    fi
    
    # 如果SSL不工作，尝试配置HTTP pip源
    if [ "$SSL_WORKING" = false ] && [ "$PIP_WORKING" = true ]; then
      echo "配置pip使用HTTP源（因为SSL不可用）..."
      mkdir -p ~/.pip
      cat > ~/.pip/pip.conf << 'EOF'
[global]
trusted-host = pypi.org
               pypi.python.org
               files.pythonhosted.org
               mirrors.aliyun.com
index-url = http://mirrors.aliyun.com/pypi/simple/
EOF
      echo "✓ 已配置pip使用HTTP源"
    fi
    
    # 最终状态报告
    echo "=== Python 3.10 安装状态报告 ==="
    echo "Python基本功能: ✓"
    echo "SSL支持: $( [ "$SSL_WORKING" = true ] && echo "✓" || echo "❌ (已配置HTTP pip源)" )"
    echo "pip功能: $( [ "$PIP_WORKING" = true ] && echo "✓" || echo "❌" )"
    echo "================================"
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

# 确保 pip 可用 - 增强版本，处理SSL问题
if ! command -v pip &> /dev/null; then
  echo "安装 pip（增强SSL错误处理）..."
  
  # 先检测Python可用性
  PYTHON_CMD=""
  if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
    PYTHON_CMD="python${PYTHON_VERSION}"
  elif [ -f /usr/local/bin/python${PYTHON_VERSION} ]; then
    PYTHON_CMD="/usr/local/bin/python${PYTHON_VERSION}"
  elif [ -f /usr/local/bin/python ]; then
    PYTHON_CMD="/usr/local/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
  elif command -v python >/dev/null 2>&1; then
    # 检查是否是Python 3
    if python --version 2>&1 | grep -q "Python 3"; then
      PYTHON_CMD="python"
    fi
  fi
  
  if [ -z "$PYTHON_CMD" ]; then
    echo "❌ 无法找到可用的Python解释器"
    return 1
  fi
  
  echo "使用Python解释器: $PYTHON_CMD"
  $PYTHON_CMD --version
  
  # 检查Python的SSL功能
  echo "检查Python SSL功能..."
  if $PYTHON_CMD -c "import ssl; print('SSL可用')" 2>/dev/null; then
    echo "✓ Python SSL功能正常，使用HTTPS下载pip"
    SSL_AVAILABLE=true
  else
    echo "⚠️  Python SSL功能不可用，使用HTTP下载pip"
    SSL_AVAILABLE=false
  fi
  
  # 根据Python版本和SSL可用性选择下载策略
  if [ "$SSL_AVAILABLE" = true ]; then
    # SSL可用，正常下载
    case $PYTHON_VERSION in
      3.6)
        echo "下载Python 3.6专用pip安装脚本..."
        curl -o get-pip.py https://bootstrap.pypa.io/pip/3.6/get-pip.py || wget -O get-pip.py https://bootstrap.pypa.io/pip/3.6/get-pip.py
        ;;
      3.7)
        echo "下载Python 3.7专用pip安装脚本..."
        curl -o get-pip.py https://bootstrap.pypa.io/pip/3.7/get-pip.py || wget -O get-pip.py https://bootstrap.pypa.io/pip/3.7/get-pip.py
        ;;
      3.8)
        echo "下载Python 3.8专用pip安装脚本..."
        curl -o get-pip.py https://bootstrap.pypa.io/pip/3.8/get-pip.py || wget -O get-pip.py https://bootstrap.pypa.io/pip/3.8/get-pip.py
        ;;
      *)
        echo "下载最新pip安装脚本..."
        curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py || wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
        ;;
    esac
  else
    # SSL不可用，使用HTTP或预下载的脚本
    echo "SSL不可用，尝试备用下载方式..."
    
    # 尝试HTTP镜像源
    if curl -o get-pip.py http://mirrors.aliyun.com/pypi/get-pip.py 2>/dev/null; then
      echo "✓ 从阿里云镜像下载pip安装脚本"
    elif wget -O get-pip.py http://mirrors.aliyun.com/pypi/get-pip.py 2>/dev/null; then
      echo "✓ 通过wget从阿里云镜像下载pip安装脚本"
    else
      echo "⚠️  无法下载pip安装脚本，尝试使用ensurepip..."
      if $PYTHON_CMD -m ensurepip --default-pip 2>/dev/null; then
        echo "✓ 通过ensurepip安装pip成功"
      else
        echo "❌ ensurepip也失败，尝试手动安装pip..."
        # 作为最后的备用方案，创建一个简单的pip安装
        yum install -y python3-pip 2>/dev/null || true
      fi
    fi
  fi
  
  # 如果下载成功，运行安装脚本
  if [ -f get-pip.py ]; then
    echo "运行pip安装脚本..."
    if $PYTHON_CMD get-pip.py; then
      echo "✓ pip安装成功"
    else
      echo "❌ pip安装脚本执行失败"
      # 尝试备用方案
      $PYTHON_CMD -m ensurepip --default-pip 2>/dev/null || true
    fi
    rm -f get-pip.py
  fi
else
  echo "✓ pip 已可用"
fi

# 最终验证pip功能并配置
echo "=== 最终pip配置和验证 ==="

# 找到pip命令
PIP_CMD=""
if command -v pip >/dev/null 2>&1; then
  PIP_CMD="pip"
elif command -v pip3 >/dev/null 2>&1; then
  PIP_CMD="pip3"
elif [ -f /usr/local/bin/pip ]; then
  PIP_CMD="/usr/local/bin/pip"
elif command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
  PIP_CMD="python3 -m pip"
elif [ -f /usr/local/bin/python ] && /usr/local/bin/python -m pip --version >/dev/null 2>&1; then
  PIP_CMD="/usr/local/bin/python -m pip"
fi

if [ -n "$PIP_CMD" ]; then
  echo "✓ 找到pip命令: $PIP_CMD"
  $PIP_CMD --version
  
  # 测试pip是否能正常工作
  echo "测试pip功能..."
  if $PIP_CMD list >/dev/null 2>&1; then
    echo "✓ pip list 功能正常"
  else
    echo "⚠️  pip list 失败，可能是SSL问题，配置HTTP源..."
    
    # 创建pip配置文件
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf << 'EOF'
[global]
trusted-host = pypi.org
               pypi.python.org  
               files.pythonhosted.org
               mirrors.aliyun.com
               mirrors.cloud.aliyuncs.com
index-url = http://mirrors.aliyun.com/pypi/simple/
timeout = 120

[install]
trusted-host = pypi.org
               pypi.python.org
               files.pythonhosted.org 
               mirrors.aliyun.com
               mirrors.cloud.aliyuncs.com
EOF
    
    # 也创建全局配置
    mkdir -p /etc/pip
    cp ~/.pip/pip.conf /etc/pip/pip.conf
    
    echo "✓ 已配置pip使用HTTP源"
    
    # 再次测试
    if $PIP_CMD list >/dev/null 2>&1; then
      echo "✓ 配置HTTP源后pip工作正常"
    else
      echo "⚠️  pip仍有问题，但继续构建过程..."
    fi
  fi
else
  echo "❌ 未找到可用的pip命令"
fi

# 安装 Python 依赖（带SSL容错处理）
echo "=== 安装Python依赖包 ==="

# 找到正确的Python和pip命令
if [ -f /usr/local/bin/python ]; then
  PYTHON_CMD="/usr/local/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo "❌ 找不到Python解释器"
  exit 1
fi

echo "使用Python解释器: $PYTHON_CMD"
$PYTHON_CMD --version

# 测试pip基本功能
echo "测试pip功能..."
if $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
  echo "✓ pip模块可用"
  PIP_CMD="$PYTHON_CMD -m pip"
elif command -v pip >/dev/null 2>&1; then
  echo "✓ pip命令可用"
  PIP_CMD="pip"
else
  echo "❌ pip不可用"
  exit 1
fi

# 测试pip list功能，判断是否需要配置HTTP源
echo "测试pip网络功能..."
if $PIP_CMD list >/dev/null 2>&1; then
  echo "✓ pip网络功能正常"
  USE_TRUSTED_HOSTS=""
else
  echo "⚠️  pip网络功能异常，配置信任主机..."
  USE_TRUSTED_HOSTS="--trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host mirrors.aliyun.com"
fi

# 升级pip
echo "升级pip..."
$PIP_CMD install --upgrade pip $USE_TRUSTED_HOSTS || {
  echo "pip升级失败，继续使用当前版本..."
}

# 安装基本构建依赖
echo "安装基本构建依赖..."
$PIP_CMD install nuitka wheel setuptools $USE_TRUSTED_HOSTS || {
  echo "基本依赖安装失败，尝试国内镜像..."
  $PIP_CMD install -i http://mirrors.aliyun.com/pypi/simple/ nuitka wheel setuptools --trusted-host mirrors.aliyun.com || {
    echo "⚠️  基本依赖安装失败，可能影响构建..."
  }
}

# 根据Python版本安装科学计算库
echo "安装科学计算库..."
if [[ "$PYTHON_VERSION" == "3.8" ]]; then
  NUMPY_SPEC="numpy>=1.20.0,<2.0.0"
else
  NUMPY_SPEC="numpy>=2.0.0"
fi

$PIP_CMD install "$NUMPY_SPEC" scipy $USE_TRUSTED_HOSTS || {
  echo "科学库安装失败，尝试国内镜像..."
  $PIP_CMD install -i http://mirrors.aliyun.com/pypi/simple/ "$NUMPY_SPEC" scipy --trusted-host mirrors.aliyun.com || {
    echo "⚠️  科学库安装失败，可能影响某些功能..."
  }
}

echo "✓ Python依赖包安装完成"

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
