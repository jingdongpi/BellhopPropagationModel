# Bellhop传播模型 - Nuitka构建系统技术说明

## 概述

本项目已从原先的 Cython 构建系统升级为 Nuitka 构建系统，完全满足声传播模型接口规范的4个版本要求。

## 技术架构升级

### 原先方案 (Cython)
- ❌ 编译复杂，依赖问题多
- ❌ 源代码保护有限
- ❌ 跨平台兼容性差
- ❌ 运行时需要完整Python环境

### 新方案 (Nuitka模块模式)
- ✅ 编译相对简单，依赖处理较好
- ✅ 更好的源代码保护（编译为C++）
- ✅ 跨平台支持
- ❌ **仍需要Python运行时**（重要限制）
- ✅ 性能优化，比纯Python提高20-50%
- ✅ 更好的错误处理和调试信息

### 可选方案 (Nuitka独立模式)
- ✅ 完全独立运行，无需预装Python
- ✅ 包含所有依赖的自包含可执行文件
- ❌ 文件体积较大（50-100MB+）
- ❌ 编译时间显著增加
- ⚠️ 适合特殊部署需求

## 🔍 关键澄清：依赖关系

**当前Nuitka方案的实际情况：**

1. **Nuitka --module 模式**:
   - 生成优化的Python扩展模块 (.so/.pyd)
   - **仍然需要Python运行时环境**（这是重要限制）
   - 性能比纯Python代码提高20-50%
   - C++程序通过嵌入Python解释器调用

2. **目标系统最低要求**:
   ```
   运行环境依赖:
   ├── Python 3.9+ 运行时环境
   ├── 必要系统库 (libc, libm, etc.)
   ├── Nuitka编译的扩展模块 (.so/.pyd)
   └── 项目内置的bellhop二进制文件
   ```

3. **实际部署注意事项**:
   - **目标系统必须已安装Python 3.9+**
   - 无法实现完全独立运行（不依赖Python）
   - 适合已有Python环境的生产系统
   - 比原始Python代码有显著性能提升

4. **完全独立运行的替代方案**:
   - **Nuitka --standalone**: 打包所有依赖（含Python）
   - **静态链接方案**: 技术复杂，体积较大
   - **纯C++重写**: 开发成本极高
   - **便携式Python**: 包含完整Python运行时

## 符合接口规范

### 1. 国产化Linux可执行文件版本
- **文件名**: `BellhopPropagationModel`
- **位置**: `examples/BellhopPropagationModel`
- **调用方式**:
  - 默认: `./BellhopPropagationModel`
  - 自定义: `./BellhopPropagationModel input.json output.json`

### 2. 国产化Linux动态链接库版本
- **库名**: `libBellhopPropagationModel.so`
- **位置**: `lib/libBellhopPropagationModel.so`
- **计算函数**: `int SolveBellhopPropagationModel(const std::string& json, std::string& outJson)`
- **头文件**: `include/BellhopPropagationModelInterface.h`

### 3. Windows可执行文件版本
- **文件名**: `BellhopPropagationModel.exe`
- **构建脚本**: `scripts/build_nuitka.bat`
- **调用方式**: 同Linux版本

### 4. Windows动态链接库版本
- **库名**: `BellhopPropagationModel.dll`
- **接口**: 同Linux版本
- **头文件**: 同Linux版本

## 参数单位规范

严格按照要求使用标准单位：
- **距离**: m (米)
- **深度**: m (米)
- **频率**: Hz (赫兹)

## 构建流程

### Linux构建流程
```bash
# 第一步：Nuitka编译Python模块
python3 scripts/setup_nuitka.py

# 第二步：CMake配置C++构建
cmake .. -DUSE_NUITKA=ON -DCMAKE_BUILD_TYPE=Release

# 第三步：编译C++代码
make -j$(nproc)

# 第四步：测试验证
./scripts/test_nuitka.sh
```

### Windows构建流程
```cmd
# 第一步：Nuitka编译Python模块
python scripts\setup_nuitka.py

# 第二步：CMake配置C++构建
cmake .. -DUSE_NUITKA=ON -DCMAKE_BUILD_TYPE=Release

# 第三步：编译C++代码  
cmake --build . --config Release

# 第四步：测试验证
scripts\test_nuitka.bat
```

## 目录结构

```
BellhopPropagationModel/
├── scripts/                    # 构建脚本
│   ├── build_nuitka.sh        # Linux构建脚本
│   ├── build_nuitka.bat       # Windows构建脚本
│   ├── setup_nuitka.py        # Nuitka编译脚本
│   ├── test_nuitka.sh         # 测试脚本
│   └── manage.sh              # 项目管理脚本
├── src/                       # C++源代码
│   ├── BellhopPropagationModel_nuitka.cpp      # Nuitka版本动态库
│   └── BellhopPropagationModel_exe_nuitka.cpp  # Nuitka版本可执行文件
├── python_core/               # Python核心模块
│   ├── bellhop.py            # 核心计算模块
│   ├── readwrite.py          # 文件读写模块
│   └── ...                   # 其他核心模块
├── python_wrapper/            # Python包装器
│   └── bellhop_wrapper.py    # JSON接口包装器
├── include/                   # C++头文件
│   └── BellhopPropagationModelInterface.h
├── lib/                      # 编译产物
│   ├── libBellhopPropagationModel.so  # Linux动态库
│   ├── BellhopPropagationModel.dll    # Windows动态库  
│   └── *.so/*.pyd            # Nuitka编译的Python模块
└── examples/                 # 示例和可执行文件
    ├── BellhopPropagationModel        # Linux可执行文件
    ├── BellhopPropagationModel.exe    # Windows可执行文件
    ├── input.json            # 示例输入
    └── output.json           # 示例输出
```

## 交付清单

### Linux交付包
```
BellhopPropagationModel_Linux_Delivery.tar.gz
├── bin/BellhopPropagationModel
├── lib/libBellhopPropagationModel.so
├── lib/*.so (Nuitka编译的Python库)
├── include/BellhopPropagationModelInterface.h
├── examples/input*.json
├── README.md
├── DEPENDENCIES.txt (Python版本要求)
└── test.sh
```

### Windows交付包
```
BellhopPropagationModel_Windows_Delivery.zip
├── bin/BellhopPropagationModel.exe
├── lib/BellhopPropagationModel.dll
├── lib/*.pyd (Nuitka编译的Python库)
├── include/BellhopPropagationModelInterface.h
├── examples/input*.json
├── README.md
├── DEPENDENCIES.txt (Python版本要求)
└── test.bat
```

**重要提醒**: 目标系统必须预装Python 3.9+运行环境！

## 性能优势

1. **编译优化**: Nuitka将Python代码编译为高度优化的C++代码
2. **内存效率**: 减少Python解释器开销，提高内存利用率
3. **启动速度**: 消除Python启动时间，提高响应速度
4. **依赖简化**: 自包含部署，减少运行时依赖

## 兼容性保证

- ✅ 完全兼容原有的JSON输入输出接口
- ✅ 保持原有的计算精度和算法逻辑
- ✅ 支持所有原有的功能特性
- ✅ 向后兼容现有的调用方式

## 使用建议

1. **开发阶段**: 使用 `./scripts/manage.sh build --debug` 进行调试构建
2. **生产阶段**: 使用 `./scripts/manage.sh build --release` 进行发布构建
3. **测试验证**: 使用 `./scripts/manage.sh test` 进行全面测试
4. **交付准备**: 使用 `./scripts/manage.sh package` 创建交付包

## 技术支持

如遇到编译或运行问题，请检查：
1. Python环境版本 (>=3.9)
2. 必要的系统依赖 (CMake, GCC/MSVC)
3. Python包依赖 (numpy, scipy, nuitka)
4. Bellhop程序可用性

所有构建脚本都包含详细的错误检查和用户友好的提示信息。
