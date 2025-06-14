# Bellhop声传播模型 - Nuitka版本

高性能的Bellhop声传播建模解决方案，提供C++动态库和可执行文件接口。使用Nuitka将Python源文件编译为高性能动态库，满足工程化模型的版本要求。

## ⚠️ 重要提醒
**本项目使用Nuitka --module模式编译，运行时仍需要Python环境！**  
目标系统必须预装Python 3.9+，详见 `DEPENDENCIES.txt`

## 版本支持

根据声传播模型接口规范，本项目提供以下4个版本：

- ✅ **国产化Linux可执行文件版本** (`BellhopPropagationModel`)
- ✅ **国产化Linux动态链接库版本** (`libBellhopPropagationModel.so`)  
- ✅ **Windows可执行文件版本** (`BellhopPropagationModel.exe`)
- ✅ **Windows动态链接库版本** (`BellhopPropagationModel.dll`)

## 主要功能

- 传输损失计算
- 射线追踪
- 压力场分析
- 海洋声学传播建模
- Python核心模块Nuitka编译优化 (性能提升20-50%)

## 技术架构

- **核心计算模块**: Python (Nuitka编译为动态库)
- **接口层**: C++ (符合标准接口规范)
- **构建系统**: CMake + Nuitka
- **接口规范**: 完全符合声传播模型接口规范
- **依赖关系**: 需要Python 3.9+运行时环境

## 系统要求

### Linux系统
- **操作系统**: Linux x86_64 (支持国产化Linux)
- **Python**: 3.9或更高版本 (**必须**)
- **编译器**: GCC 7.0+
- **构建工具**: CMake 3.10+, Make
- **依赖库**: numpy, scipy
- **外部程序**: bellhop (项目自动收集)
- **内存**: 最小512MB
- **存储**: 200MB

### Windows系统  
- **操作系统**: Windows 10/11 x64
- **Python**: 3.9或更高版本 (**必须**)
- **编译器**: Visual Studio 2019+ 或 MinGW
- **构建工具**: CMake 3.10+
- **依赖库**: numpy, scipy
- **外部程序**: bellhop.exe (项目自动收集)
- **内存**: 最小512MB  
- **存储**: 200MB

## 快速构建

### 第一步：检查运行时依赖
```bash
# 检查Python版本 (必须3.9+)
python3 --version

# 运行依赖检查脚本
python3 scripts/check_dependencies.py
```

### Linux系统构建

```bash
# 安装Python依赖
pip install numpy scipy nuitka

# 自动收集bellhop等二进制文件
./scripts/manage.sh binaries

# 使用Nuitka构建
./scripts/build_nuitka.sh
```

### Windows系统构建

```cmd
# 安装Python依赖
pip install numpy scipy nuitka

# 自动收集bellhop等二进制文件
python scripts\collect_binaries.py

# 使用Nuitka构建
scripts\build_nuitka.bat
```

## 构建选项

项目支持多种构建模式：

1. **Nuitka模块模式** (默认): `USE_NUITKA=ON`
   - 高性能Python模块编译
   - 源代码保护
   - **需要Python运行时环境**

2. **Nuitka独立模式**: 使用 `scripts/build_standalone.py`
   - 完全独立运行，无需Python
   - 文件体积较大 (50-100MB+)

3. **Cython模式** (传统): `USE_CYTHON=ON`
   - Cython扩展模块
   - 向后兼容

## 安装依赖

### Linux
```bash
# 安装Python依赖
pip install numpy scipy nuitka

# 安装系统依赖（Ubuntu/Debian）
sudo apt update
sudo apt install cmake build-essential

# 安装系统依赖（CentOS/RHEL）
sudo yum install cmake gcc-c++ make

# 确保bellhop在PATH中
which bellhop  # 应该能找到bellhop可执行文件
```

### Windows
```cmd
# 安装Python依赖
pip install numpy scipy nuitka

# 确保bellhop.exe在PATH中
where bellhop  

# 需要安装以下之一：
# - Visual Studio 2019+ (推荐)
# - MinGW-w64
# - CMake for Windows
```

## 交付文件结构

### Linux版本
```
BellhopPropagationModel_Linux_Delivery/
├── README.md                           # 使用说明
├── test.sh                             # 快速测试脚本
├── bin/
│   └── BellhopPropagationModel         # Linux可执行文件
├── lib/
│   ├── libBellhopPropagationModel.so   # Linux动态链接库
│   └── *.so                           # Nuitka编译的Python动态库
├── include/
│   └── BellhopPropagationModelInterface.h # C++接口头文件
└── examples/
    ├── input*.json                     # 输入示例文件
    └── output.json                     # 输出示例文件
```

### Windows版本
```
BellhopPropagationModel_Windows_Delivery/
├── README.md                           # 使用说明
├── test.bat                           # 快速测试脚本
├── bin/
│   └── BellhopPropagationModel.exe     # Windows可执行文件
├── lib/
│   ├── BellhopPropagationModel.dll     # Windows动态链接库
│   └── *.pyd                          # Nuitka编译的Python动态库
├── include/
│   └── BellhopPropagationModelInterface.h # C++接口头文件
└── examples/
    ├── input*.json                     # 输入示例文件
    └── output.json                     # 输出示例文件
```

## 接口规范

### 可执行文件接口

**Linux**: `BellhopPropagationModel`  
**Windows**: `BellhopPropagationModel.exe`

```bash
# 方式1: 默认参数 (input.json -> output.json)
./BellhopPropagationModel

# 方式2: 自定义文件
./BellhopPropagationModel input_custom.json output_custom.json
```

### 动态链接库接口

**Linux**: `libBellhopPropagationModel.so`  
**Windows**: `BellhopPropagationModel.dll`

**计算函数**:
```cpp
int SolveBellhopPropagationModel(const std::string& json, std::string& outJson);
```

**头文件**: `BellhopPropagationModelInterface.h`

### 参数单位规范

- **距离**: m (米)
- **深度**: m (米)  
- **频率**: Hz (赫兹)

## 快速开始

### 🚀 一键编译（推荐）

```bash
# 完整编译流程（Nuitka + C++）
./manager.sh build

# 检查系统依赖
./manager.sh deps

# 测试运行
./manager.sh test

# 清理编译产物
./manager.sh clean

# 查看帮助
./manager.sh help
```

# 创建交付包
./scripts/manage.sh package
```

### 方法二：手动构建

```bash
# 1. 收集二进制文件
python3 scripts/collect_binaries.py

# 2. 构建项目
# Linux系统
./scripts/build_nuitka.sh

# Windows系统  
scripts\build_nuitka.bat

# 3. 运行测试
./scripts/test_nuitka.sh
```

### 使用示例

```bash
# 默认参数调用
./examples/BellhopPropagationModel

# 自定义参数调用
./examples/BellhopPropagationModel input.json output.json
```

## 二进制文件管理

本项目会自动收集并内置必要的声学计算程序：

### 自动收集的程序
- `bellhop` - 主要的声传播计算程序
- `kraken` - 模式声传播计算程序  
- `ram` - RAM声传播模型
- `scooter` - 频域声传播模型
- `sparc` - 宽带声传播模型
- `bounce` - 射线声传播模型

### 优势
- ✅ **免配置**: 用户无需手动设置PATH或安装声学工具
- ✅ **自包含**: 交付包包含所有必要的二进制文件
- ✅ **版本一致**: 确保使用经过测试的特定版本程序
- ✅ **跨环境**: 支持不同的Linux发行版和Windows系统

### 1. 运行快速测试
```bash
cd BellhopPropagationModel_Delivery
./test.sh
```

### 2. 命令行使用
```bash
# 使用默认输入输出文件
./bin/BellhopPropagationModel

# 指定输入输出文件
./bin/BellhopPropagationModel examples/input.json output.json
```

### 3. 环境配置
如果遇到模块加载问题，设置环境变量：
```bash
export PYTHONPATH=$PWD/lib:$PYTHONPATH
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
```

## C++接口使用

### 动态库接口
```cpp
#include "BellhopPropagationModelInterface.h"

std::string input_json = "{...}";  // JSON输入
std::string output_json;
int result = SolveBellhopPropagationModel(input_json, output_json);

if (result == 0) {
    // 成功，output_json包含结果
} else {
    // 失败，检查错误信息
}
```

### 编译链接
```bash
g++ -o myapp myapp.cpp -L./lib -lBellhopPropagationModel
```

## 输入输出格式

### 输入JSON格式
```json
{
  "freq": 100,
  "source_depth": 20,
  "receiver_depth": [10, 30],
  "receiver_range": [1000, 2000],
  "bathy": {
    "range": [0, 2000],
    "depth": [100, 110]
  },
  "sound_speed_profile": [
    {
      "range": 0,
      "depth": [0, 50, 100],
      "speed": [1520, 1510, 1500]
    }
  ],
  "sediment_info": [
    {
      "range": 0,
      "sediment": {
        "p_speed": 1600,
        "s_speed": 200,
        "density": 1.8,
        "p_atten": 0.2,
        "s_atten": 1.0
      }
    }
  ],
  "conherent_para": "C",
  "is_propagation_pressure_output": true,
  "ray_model_para": {
    "grazing_low": -20.0,
    "grazing_high": 20.0,
    "beam_number": 20,
    "is_ray_output": false
  }
}
```

### 输出JSON格式
```json
{
  "error_code": 200,
  "error_message": "",
  "receiver_depth": [10.00, 30.00],
  "receiver_range": [1000.00, 2000.00],
  "transmission_loss": [[52.60, 59.19], [47.76, 50.84]],
  "frequencies": [100.00],
  "is_multi_frequency": false,
  "propagation_pressure": [
    [
      {"real": -0.001977, "imag": -0.001258},
      {"real": -0.000745, "imag": 0.000806}
    ],
    [
      {"real": -0.003880, "imag": -0.001301},
      {"real": -0.001475, "imag": -0.002464}
    ]
  ],
  "ray_trace": [],
  "time_wave": {}
}
```

## 示例文件

项目提供多种示例输入文件：

- `input_minimal_test.json` - 最小测试用例
- `input_fast_test.json` - 快速测试
- `input_small.json` - 小规模计算
- `input_medium.json` - 中等规模计算
- `input_large.json` - 大规模计算
- `input_multi_frequency.json` - 多频率计算
- `input_ray_test.json` - 射线追踪测试

## 故障排查

### 常见问题及解决方案

1. **"bellhop not found"错误**
   ```bash
   # 确保bellhop在PATH中
   which bellhop
   # 如果没找到，请安装或添加到PATH
   ```

2. **Python模块加载错误**
   ```bash
   # 设置Python路径
   export PYTHONPATH=$PWD/lib:$PYTHONPATH
   ```

3. **权限错误**
   ```bash
   # 设置执行权限
   chmod +x bin/BellhopPropagationModel
   chmod +x lib/*.so
   ```

4. **numpy相关错误**
   ```bash
   # 确认numpy版本
   python3 -c "import numpy; print(numpy.__version__)"
   # 如果版本过低，升级
   pip install --upgrade numpy
   ```

5. **动态库加载错误**
   ```bash
   # 设置库路径
   export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
   # 检查依赖
   ldd bin/BellhopPropagationModel
   ```

### 调试模式

如果需要详细调试信息，可以：

1. 检查日志文件：`data/error_log.txt`
2. 运行时添加详细输出：
   ```bash
   BELLHOP_DEBUG=1 ./bin/BellhopPropagationModel input.json output.json
   ```

## 性能优化

- 本版本使用Cython优化，比纯Python版本性能提升约3-5倍
- 支持多频率并行计算
- 内存使用经过优化，适合大规模计算

## 技术支持

使用过程中如遇问题，请：

1. 首先运行测试脚本确认基本功能
2. 检查系统要求和依赖安装
3. 查看错误日志获取详细信息
4. 参考故障排查部分解决常见问题

---
*Bellhop声传播模型 - 完整使用手册*
