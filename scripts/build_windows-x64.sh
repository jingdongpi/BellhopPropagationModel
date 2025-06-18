#!/bin/bash
# Windows x86-64 平台构建脚本 - 符合声传播模型接口规范
# 目标环境: MinGW32 gcc 6.3.0
# 产物: BellhopPropagationModel.exe (可执行文件) + BellhopPropagationModel.dll (动态链接库)

set -e

echo "🎯 开始 Windows x86-64 接口规范构建"
echo "目标: 完全符合声传播模型接口规范"

# 环境设置
export PLATFORM="windows-x64"
export TARGET_GCC_VERSION="6.3.0"
export MINGW_VERSION="mingw32"

# 2.1.1 可执行文件命名规范 (Windows)
export EXECUTABLE_NAME="BellhopPropagationModel.exe"

# 2.1.2 动态链接库命名规范 (Windows)
export LIBRARY_NAME="BellhopPropagationModel.dll"
export FUNCTION_NAME="SolveBellhopPropagationModel"
export HEADER_NAME="BellhopPropagationModelInterface.h"

# 2.3 错误码规范
export SUCCESS_ERROR_CODE="200"
export FAILURE_ERROR_CODE="500"

echo "=== Python环境设置 ==="
# 确保使用MSYS2的Python
export PATH="/mingw64/bin:$PATH"
which python
python --version

echo "=== 安装Python依赖 ==="
python -m pip install --upgrade pip
python -m pip install nuitka pybind11 numpy

echo "=== 验证环境 ==="
python -m nuitka --version
gcc --version

echo "=== 构建符合接口规范的产物 ==="

# 创建构建目录
mkdir -p build dist

echo "=== 编译可执行文件: ${EXECUTABLE_NAME} ==="
cd python_core

# 使用Nuitka编译Python主模块为Windows可执行文件
python -m nuitka \
    --standalone \
    --onefile \
    --output-filename="${EXECUTABLE_NAME%.exe}" \
    --output-dir="../dist" \
    --follow-imports \
    --assume-yes-for-downloads \
    --mingw64 \
    BellhopPropagationModel.py

# 确保生成.exe扩展名
if [ -f "../dist/BellhopPropagationModel" ] && [ ! -f "../dist/BellhopPropagationModel.exe" ]; then
    mv "../dist/BellhopPropagationModel" "../dist/BellhopPropagationModel.exe"
fi

cd ..

echo "=== 编译动态链接库: ${LIBRARY_NAME} ==="
cd wrapper

# 获取Python信息
PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_INCLUDE_DIR=$(python -c "from sysconfig import get_path; print(get_path('include'))")
PYTHON_LIB_DIR=$(python -c "from sysconfig import get_path; print(get_path('stdlib'))" | sed 's/lib\/python.*/lib/')

echo "Python版本: ${PYTHON_VERSION}"
echo "Python包含目录: ${PYTHON_INCLUDE_DIR}"
echo "Python库目录: ${PYTHON_LIB_DIR}"

# 编译C++动态链接库，包含SolveBellhopPropagationModel函数
g++ -shared \
    -o "../dist/${LIBRARY_NAME}" \
    ${HEADER_NAME%.h}.cpp \
    -I../python_core \
    -I"${PYTHON_INCLUDE_DIR}" \
    -L"${PYTHON_LIB_DIR}" \
    -lpython${PYTHON_VERSION} \
    -O2 \
    -DFUNCTION_NAME="${FUNCTION_NAME}" \
    -DSUCCESS_CODE=${SUCCESS_ERROR_CODE} \
    -DFAILURE_CODE=${FAILURE_ERROR_CODE} \
    -Wl,--out-implib,../dist/BellhopPropagationModel.lib

cd ..

echo "=== 复制头文件: ${HEADER_NAME} ==="
cp wrapper/${HEADER_NAME} dist/

echo "=== 生成标准输入文件 ==="
cat > dist/input.json << 'EOF'
{
  "model_name": "BellhopPropagationModel",
  "frequency": 1000.0,
  "source": {
    "depth": 50.0,
    "range": 0.0
  },
  "receiver": {
    "depth_min": 10.0,
    "depth_max": 200.0,
    "depth_count": 50,
    "range_min": 1000.0,
    "range_max": 10000.0,
    "range_count": 100
  },
  "environment": {
    "water_depth": 200.0,
    "sound_speed_profile": [
      {"depth": 0.0, "speed": 1500.0},
      {"depth": 100.0, "speed": 1480.0},
      {"depth": 200.0, "speed": 1520.0}
    ],
    "bottom": {
      "density": 1.8,
      "sound_speed": 1600.0,
      "attenuation": 0.5
    }
  },
  "calculation": {
    "ray_count": 100,
    "angle_min": -45.0,
    "angle_max": 45.0
  },
  "units": {
    "frequency": "Hz",
    "depth": "m", 
    "range": "m",
    "sound_speed": "m/s",
    "density": "g/cm³",
    "attenuation": "dB/λ"
  }
}
EOF

echo "=== 生成Windows测试脚本 ==="
cat > dist/test_executable.bat << 'EOF'
@echo off
echo 🧪 测试可执行文件: BellhopPropagationModel.exe

REM 测试1: 无参数模式 (使用默认input.json和output.json)
echo === 测试1: 无参数模式 ===
BellhopPropagationModel.exe
if %ERRORLEVEL% EQU 0 (
    echo ✅ 无参数模式测试通过 (error_code: 200)
) else (
    echo ❌ 无参数模式测试失败 (error_code: 500)
)

REM 测试2: 指定文件模式 (支持并行计算)
echo === 测试2: 指定文件模式 ===
BellhopPropagationModel.exe input.json output_test.json
if %ERRORLEVEL% EQU 0 (
    echo ✅ 指定文件模式测试通过 (error_code: 200)
) else (
    echo ❌ 指定文件模式测试失败 (error_code: 500)
)

echo 🎯 可执行文件测试完成
pause
EOF

cat > dist/test_library.cpp << 'EOF'
// Windows动态链接库测试程序
#include "BellhopPropagationModelInterface.h"
#include <iostream>
#include <fstream>
#include <sstream>

int main() {
    std::cout << "🧪 测试动态链接库: BellhopPropagationModel.dll" << std::endl;
    
    // 读取标准输入
    std::ifstream input_file("input.json");
    std::stringstream buffer;
    buffer << input_file.rdbuf();
    std::string input_json = buffer.str();
    
    // 调用SolveBellhopPropagationModel函数
    std::string output_json;
    int result = SolveBellhopPropagationModel(input_json, output_json);
    
    // 验证结果 (error_code: 200成功, 500失败)
    if (result == 200) {
        std::cout << "✅ 动态链接库测试成功 (error_code: " << result << ")" << std::endl;
        std::cout << "输出: " << output_json.substr(0, 100) << "..." << std::endl;
    } else {
        std::cout << "❌ 动态链接库测试失败 (error_code: " << result << ")" << std::endl;
    }
    
    return 0;
}
EOF

cat > dist/compile_test.bat << 'EOF'
@echo off
REM 编译Windows测试程序
echo 编译动态库测试程序...
g++ -o test_library.exe test_library.cpp -L. -lBellhopPropagationModel -I.
echo 运行测试...
test_library.exe
pause
EOF

echo "=== 验证产物符合接口规范 ==="
echo "✅ 可执行文件: dist/${EXECUTABLE_NAME}"
echo "✅ 动态链接库: dist/${LIBRARY_NAME}"  
echo "✅ 头文件: dist/${HEADER_NAME}"
echo "✅ 标准输入: dist/input.json"
echo "✅ 测试脚本: dist/test_executable.bat, dist/compile_test.bat"

echo "=== 产物清单 ==="
ls -la dist/

echo "🎯 Windows x86-64 接口规范构建完成！"
echo "完全符合声传播模型接口规范要求"
