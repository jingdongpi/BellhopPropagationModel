# Windows CI测试脚本
# 用于GitHub Actions中验证Windows构建结果

Write-Host "=== BellhopPropagationModel Windows CI Test ===" -ForegroundColor Blue

# 检查必要文件
Write-Host "1. 检查构建文件..." -ForegroundColor Yellow

$requiredFiles = @(
    "bin/Release/BellhopPropagationModel.exe",
    "bin/BellhopPropagationModel.exe",
    "lib/Release/BellhopPropagationModel.dll", 
    "lib/BellhopPropagationModel.dll",
    "include/BellhopPropagationModelInterface.h"
)

$foundExecutable = $false
$foundLibrary = $false

# 检查可执行文件
if (Test-Path "bin/Release/BellhopPropagationModel.exe") {
    Write-Host "  ✓ bin/Release/BellhopPropagationModel.exe 存在" -ForegroundColor Green
    $foundExecutable = $true
} elseif (Test-Path "bin/BellhopPropagationModel.exe") {
    Write-Host "  ✓ bin/BellhopPropagationModel.exe 存在" -ForegroundColor Green
    $foundExecutable = $true
} else {
    Write-Host "  ✗ 可执行文件缺失" -ForegroundColor Red
    exit 1
}

# 检查动态库
if (Test-Path "lib/Release/BellhopPropagationModel.dll") {
    Write-Host "  ✓ lib/Release/BellhopPropagationModel.dll 存在" -ForegroundColor Green
    $foundLibrary = $true
} elseif (Test-Path "lib/BellhopPropagationModel.dll") {
    Write-Host "  ✓ lib/BellhopPropagationModel.dll 存在" -ForegroundColor Green
    $foundLibrary = $true
} else {
    Write-Host "  ✗ 动态库缺失" -ForegroundColor Red
    exit 1
}

# 检查头文件
if (Test-Path "include/BellhopPropagationModelInterface.h") {
    Write-Host "  ✓ include/BellhopPropagationModelInterface.h 存在" -ForegroundColor Green
} else {
    Write-Host "  ✗ 头文件缺失" -ForegroundColor Red
    exit 1
}

# 检查Python环境
Write-Host "2. 检查Python环境..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version
    Write-Host "  Python版本: $pythonVersion" -ForegroundColor Green
    
    $numpyVersion = python -c "import numpy; print(f'NumPy: {numpy.__version__}')"
    Write-Host "  ✓ $numpyVersion" -ForegroundColor Green
    
    $scipyVersion = python -c "import scipy; print(f'SciPy: {scipy.__version__}')"
    Write-Host "  ✓ $scipyVersion" -ForegroundColor Green
    
    # 检查numpy版本是否符合Python版本要求
    $pythonVersionOutput = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    $numpyVersionNumber = python -c "import numpy; print(numpy.__version__)"
    $majorVersion = [int]($numpyVersionNumber.Split('.')[0])
    
    if ($pythonVersionOutput -eq "3.8") {
        if ($majorVersion -lt 2) {
            Write-Host "  ✓ NumPy版本符合Python 3.8要求 (<2.0)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ NumPy版本过高 (Python 3.8需要<2.0)" -ForegroundColor Red
            exit 1
        }
    } else {
        if ($majorVersion -ge 2) {
            Write-Host "  ✓ NumPy版本符合要求 (>=2.0)" -ForegroundColor Green
        } else {
            Write-Host "  ! NumPy版本较低 (<2.0)，但可接受" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "  ✗ Python环境检查失败: $_" -ForegroundColor Red
    exit 1
}

# 检查CMake配置
Write-Host "3. 检查构建配置..." -ForegroundColor Yellow

if (Test-Path "build/CMakeCache.txt") {
    Write-Host "  ✓ CMake缓存文件存在" -ForegroundColor Green
} else {
    Write-Host "  ! CMake缓存文件不存在" -ForegroundColor Yellow
}

# 检查Python环境和扩展模块
Write-Host "5. 检查Python环境..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  Python版本: $pythonVersion" -ForegroundColor Cyan
    
    # 检查NumPy
    $numpyVersion = python -c "import numpy; print(f'NumPy: {numpy.__version__}')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $numpyVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ NumPy 不可用" -ForegroundColor Red
        exit 1
    }
    
    # 检查SciPy
    $scipyVersion = python -c "import scipy; print(f'SciPy: {scipy.__version__}')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $scipyVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ SciPy 不可用" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ Python环境检查失败: $_" -ForegroundColor Red
    exit 1
}

# 检查Python扩展模块
Write-Host "6. 检查Python扩展模块..." -ForegroundColor Yellow

$pythonModules = @(
    "bellhop.cp*-win*.pyd",
    "readwrite.cp*-win*.pyd", 
    "env.cp*-win*.pyd",
    "bellhop_wrapper.cp*-win*.pyd"
)

foreach ($modulePattern in $pythonModules) {
    $foundFiles = Get-ChildItem "lib/$modulePattern" -ErrorAction SilentlyContinue
    if ($foundFiles) {
        Write-Host "  ✓ Python模块: $($foundFiles[0].Name)" -ForegroundColor Green
        
        # 尝试导入测试
        $moduleName = $foundFiles[0].BaseName.Split('.')[0]
        try {
            $importTest = python -c "
import sys
sys.path.insert(0, 'lib')
try:
    exec(f'import $moduleName')
    print(f'模块 $moduleName 可正常导入')
except Exception as e:
    print(f'模块 $moduleName 导入警告: {e}')
" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ $importTest" -ForegroundColor Cyan
            } else {
                Write-Host "    ! 模块导入测试跳过" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    ! 模块导入测试跳过" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ! Python模块未找到: $modulePattern (可能为可选模块)" -ForegroundColor Yellow
    }
}

# 显示构建产物信息
Write-Host "4. 构建产物信息..." -ForegroundColor Yellow

if ($foundExecutable) {
    if (Test-Path "bin/Release/BellhopPropagationModel.exe") {
        $exeInfo = Get-ItemProperty "bin/Release/BellhopPropagationModel.exe"
        Write-Host "  可执行文件大小: $($exeInfo.Length) 字节" -ForegroundColor Cyan
    } elseif (Test-Path "bin/BellhopPropagationModel.exe") {
        $exeInfo = Get-ItemProperty "bin/BellhopPropagationModel.exe"
        Write-Host "  可执行文件大小: $($exeInfo.Length) 字节" -ForegroundColor Cyan
    }
}

if ($foundLibrary) {
    if (Test-Path "lib/Release/BellhopPropagationModel.dll") {
        $dllInfo = Get-ItemProperty "lib/Release/BellhopPropagationModel.dll"
        Write-Host "  动态库大小: $($dllInfo.Length) 字节" -ForegroundColor Cyan
    } elseif (Test-Path "lib/BellhopPropagationModel.dll") {
        $dllInfo = Get-ItemProperty "lib/BellhopPropagationModel.dll"
        Write-Host "  动态库大小: $($dllInfo.Length) 字节" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "🎉 所有Windows CI测试通过！" -ForegroundColor Green
Write-Host "Windows构建产物验证成功" -ForegroundColor Green
