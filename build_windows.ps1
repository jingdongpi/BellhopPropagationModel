# Windows 11 x86_64 本地构建脚本
# BellhopPropagationModel Windows 构建环境

param(
    [string]$PythonVersion = "3.8",
    [string]$OutputDir = ".\dist\win11-x86_64-python$PythonVersion",
    [switch]$Clean
)

# 颜色输出函数
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
BellhopPropagationModel Windows 11 x86_64 本地构建脚本

用法: .\build_windows.ps1 [参数]

参数:
  -PythonVersion <version>  Python 版本 (3.8, 3.9, 3.10, 3.11)，默认 3.8
  -OutputDir <dir>          输出目录，默认 .\dist\win11-x86_64-python<version>
  -Clean                    清理旧的构建产物
  -Help                     显示此帮助信息

要求:
  - Windows 10+ 64位系统
  - PowerShell 5.0+
  - 管理员权限（用于安装 Chocolatey 和工具）

示例:
  .\build_windows.ps1 -PythonVersion 3.9
  .\build_windows.ps1 -OutputDir "C:\Release" -Clean

"@
}

# 检查参数
if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "-h") {
    Show-Help
    exit 0
}

Write-Info "=== BellhopPropagationModel Windows 11 x86_64 本地构建 ==="
Write-Info "Python 版本: $PythonVersion"
Write-Info "输出目录: $OutputDir"

# 验证 Python 版本
if ($PythonVersion -notin @("3.8", "3.9", "3.10", "3.11")) {
    Write-Error-Custom "不支持的 Python 版本: $PythonVersion"
    Write-Info "支持的版本: 3.8, 3.9, 3.10, 3.11"
    exit 1
}

# 清理函数
function Clear-BuildArtifacts {
    Write-Info "清理旧的构建产物..."
    
    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
    }
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
    }
    
    Write-Success "清理完成"
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 安装 Chocolatey
function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Chocolatey 已安装"
        return
    }
    
    Write-Info "安装 Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # 刷新环境变量
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

# 安装构建工具
function Install-BuildTools {
    Write-Info "安装构建工具..."
    
    # 安装基础工具
    choco install -y cmake git mingw
    
    # 安装 Python
    $pythonPackage = "python"
    if ($PythonVersion -ne "latest") {
        $pythonPackage += " --version=$PythonVersion"
    }
    
    choco install -y $pythonPackage
    
    # 刷新环境变量
    refreshenv
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

# 安装 Python 依赖
function Install-PythonDependencies {
    Write-Info "安装 Python 依赖..."
    
    # 升级 pip
    python -m pip install --upgrade pip
    
    # 安装基础包
    python -m pip install nuitka wheel setuptools
    
    # 安装 NumPy 和 SciPy
    if ($PythonVersion -eq "3.8") {
        python -m pip install "numpy>=1.20.0,<2.0.0" scipy
    } else {
        python -m pip install "numpy>=2.0.0" scipy
    }
    
    Write-Success "Python 依赖安装完成"
}

# 显示系统信息
function Show-SystemInfo {
    Write-Info "=== 系统信息 ==="
    Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory
    
    Write-Info "=== Python 信息 ==="
    python --version
    python -c "import sys; print(f'Python executable: {sys.executable}')"
    python -c "import platform; print(f'Architecture: {platform.machine()}')"
}

# 构建项目
function Build-Project {
    Write-Info "构建项目..."
    
    # 创建构建目录
    if (!(Test-Path "build")) {
        New-Item -ItemType Directory -Path "build"
    }
    
    Set-Location "build"
    
    try {
        # 配置 CMake
        $pythonExe = (Get-Command python).Source
        Write-Info "使用 Python: $pythonExe"
        
        cmake .. `
            -G "MinGW Makefiles" `
            -DCMAKE_BUILD_TYPE=Release `
            -DBUILD_EXECUTABLE=ON `
            -DBUILD_SHARED_LIBS=ON `
            -DPython3_EXECUTABLE="$pythonExe"
        
        if ($LASTEXITCODE -ne 0) {
            throw "CMake 配置失败"
        }
        
        # 编译
        Write-Info "编译项目..."
        mingw32-make -j4
        
        if ($LASTEXITCODE -ne 0) {
            throw "编译失败"
        }
        
        Set-Location ".."
        
        # 编译 Python 模块
        if (Test-Path "scripts/compile_nuitka_cross_platform.py") {
            Write-Info "编译 Nuitka 模块..."
            python scripts/compile_nuitka_cross_platform.py
        } else {
            Write-Warning "未找到 Nuitka 编译脚本"
        }
        
        Write-Success "项目构建完成"
    }
    catch {
        Write-Error-Custom "构建失败: $_"
        Set-Location ".."
        exit 1
    }
}

# 复制构建产物
function Copy-BuildArtifacts {
    Write-Info "复制构建产物到: $OutputDir"
    
    # 创建输出目录
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force
    }
    
    # 复制 bin 目录
    if (Test-Path "bin") {
        Copy-Item -Recurse -Force "bin" "$OutputDir\"
        Write-Success "复制 bin/ 目录成功"
    } else {
        Write-Warning "bin/ 目录不存在"
    }
    
    # 复制 lib 目录
    if (Test-Path "lib") {
        Copy-Item -Recurse -Force "lib" "$OutputDir\"
        Write-Success "复制 lib/ 目录成功"
    } else {
        Write-Warning "lib/ 目录不存在"
    }
    
    # 复制 include 目录
    if (Test-Path "include") {
        Copy-Item -Recurse -Force "include" "$OutputDir\"
        Write-Success "复制 include/ 目录成功"
    } else {
        Write-Warning "include/ 目录不存在"
    }
}

# 生成构建信息
function Generate-BuildInfo {
    $buildInfo = @"
==========================================
BellhopPropagationModel 构建信息
==========================================
平台: Windows 11 x86_64
Python版本: $PythonVersion
构建时间: $(Get-Date)
主机系统: $(Get-ComputerInfo | Select-Object -ExpandProperty WindowsProductName)

兼容性说明:
- 支持 Windows 10+ 64位系统
- 包含所有必要的运行时库
- Python 模块已通过 Nuitka 编译为二进制文件

使用说明:
1. 将 bin/、lib/、include/ 目录复制到目标系统
2. 确保目标系统为 Windows 10+ 64位
3. 运行 bin/BellhopPropagationModel.exe

技术支持:
- 确保运行环境为 Windows 10+ 64位系统
- 如有问题请检查 Windows 事件日志
"@
    
    $buildInfo | Out-File -FilePath "$OutputDir\build-info.txt" -Encoding UTF8
    Write-Success "构建信息已保存到 build-info.txt"
}

# 主函数
function Main {
    $startTime = Get-Date
    
    try {
        # 检查管理员权限
        if (!(Test-Administrator)) {
            Write-Warning "建议以管理员权限运行以确保工具安装成功"
        }
        
        # 清理旧产物
        if ($Clean) {
            Clear-BuildArtifacts
        }
        
        # 安装环境
        Install-Chocolatey
        Install-BuildTools
        Install-PythonDependencies
        
        # 显示系统信息
        Show-SystemInfo
        
        # 构建项目
        Build-Project
        
        # 复制产物
        Copy-BuildArtifacts
        
        # 生成构建信息
        Generate-BuildInfo
        
        # 显示构建产物信息
        Write-Info "构建产物统计:"
        if (Test-Path "$OutputDir\bin") {
            $binCount = (Get-ChildItem -Recurse "$OutputDir\bin" -File).Count
            Write-Host "  bin/: $binCount 个文件"
        }
        if (Test-Path "$OutputDir\lib") {
            $libCount = (Get-ChildItem -Recurse "$OutputDir\lib" -File).Count
            Write-Host "  lib/: $libCount 个文件"
        }
        if (Test-Path "$OutputDir\include") {
            $includeCount = (Get-ChildItem -Recurse "$OutputDir\include" -File).Count
            Write-Host "  include/: $includeCount 个文件"
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        Write-Success "Windows 11 x86_64 构建完成！"
        Write-Info "总耗时: $([math]::Round($duration, 2))s"
        Write-Info "构建产物位置: $OutputDir"
    }
    catch {
        Write-Error-Custom "构建失败: $_"
        exit 1
    }
}

# 执行主函数
Main
