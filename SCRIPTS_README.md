# BellhopPropagationModel 脚本体系说明

## 📋 脚本概览

本项目包含一套完整的脚本体系，用于开发、测试、部署和维护 BellhopPropagationModel 项目。所有脚本都针对 v2.0 版本进行了优化，支持多频率批处理和射线筛选优化功能。

## 🗂️ 脚本结构

### 核心脚本 (scripts/)

| 脚本文件 | 功能描述 | 主要用途 |
|---------|----------|----------|
| **00_environment_setup.sh** | 环境配置 | 检查依赖、安装组件、配置环境 |
| **01_development_validation.sh** | 开发验证 | 验证环境、代码质量、基础功能 |
| **02_performance_testing.sh** | 性能测试 | 测试计算性能、优化效果 |
| **03_integration_testing.sh** | 集成测试 | 端到端测试、功能集成验证 |
| **04_deployment.sh** | 部署脚本 | 构建、打包、发布项目 |
| **05_monitoring.sh** | 监控管理 | 系统监控、日志管理 |
| **06_maintenance.sh** | 清理维护 | 清理文件、系统维护、数据备份 |
| **99_test_orchestrator.sh** | 测试编排器 | 协调所有测试、生成报告 |

### 管理工具

| 工具文件 | 功能描述 |
|---------|----------|
| **scripts_manager.sh** | 脚本管理器 | 交互式菜单、统一管理入口 |

## 🚀 快速开始

### 方法一：使用脚本管理器（推荐）
```bash
# 运行交互式脚本管理器
./scripts_manager.sh
```

### 方法二：直接执行脚本
```bash
# 1. 环境配置
./scripts/00_environment_setup.sh --install

# 2. 开发验证
./scripts/01_development_validation.sh

# 3. 性能测试
./scripts/02_performance_testing.sh

# 4. 集成测试
./scripts/03_integration_testing.sh

# 5. 测试编排器
./scripts/99_test_orchestrator.sh --full
```

## 📖 详细使用说明

### 1. 环境配置脚本 (00_environment_setup.sh)

**功能**: 自动配置开发环境、检查依赖、安装缺失组件

```bash
# 检查环境状态
./scripts/00_environment_setup.sh --check

# 自动安装依赖
./scripts/00_environment_setup.sh --install

# 清理环境
./scripts/00_environment_setup.sh --clean
```

**检查内容**:
- Python 3 环境和必需库 (numpy, scipy, matplotlib, psutil)
- CMake 和编译工具
- Bellhop 二进制文件
- 项目目录结构
- 文件权限设置

### 2. 开发验证脚本 (01_development_validation.sh)

**功能**: 验证开发环境、代码质量、基础功能、射线筛选优化

```bash
./scripts/01_development_validation.sh
```

**验证内容**:
- ✅ 环境依赖检查
- ✅ 项目结构验证
- ✅ 代码质量检查
- ✅ 模块导入测试
- ✅ 射线筛选优化验证 (NEW)
- ✅ 多频率功能验证 (NEW)
- ✅ 接口规范验证
- ✅ 基础功能测试
- ✅ 构建系统检查

### 3. 性能测试脚本 (02_performance_testing.sh)

**功能**: 测试计算性能、多频率优化、射线筛选效果

```bash
./scripts/02_performance_testing.sh
```

**测试内容**:
- ⚡ 系统资源检查
- ⚡ 轻量级性能测试
- ⚡ 多频率批处理性能测试 (NEW)
- ⚡ 射线筛选优化性能测试 (NEW)
- ⚡ 内存使用分析
- ⚡ 并发性能测试
- ⚡ 优化效果对比

### 4. 集成测试脚本 (03_integration_testing.sh)

**功能**: 测试完整功能集成、端到端测试、数据流验证

```bash
./scripts/03_integration_testing.sh
```

**测试内容**:
- 🔗 模块集成测试
- 🔗 数据流集成测试
- 🔗 多频率功能集成测试 (NEW)
- 🔗 射线筛选集成测试 (NEW)
- 🔗 端到端功能测试
- 🔗 接口兼容性测试
- 🔗 异常处理测试

### 5. 部署脚本 (04_deployment.sh)

**功能**: 构建项目、打包部署、生成发布版本

```bash
# 构建项目
./scripts/04_deployment.sh --build

# 打包部署
./scripts/04_deployment.sh --package

# 系统安装
./scripts/04_deployment.sh --install

# 发布版本
./scripts/04_deployment.sh --release
```

**编排流程**:
1. 📋 预编排检查
**编排流程**:
1. 📋 预编排检查
2. 🔧 开发验证测试  
3. ⚡ 性能测试
4. 🔗 集成测试
5. 📊 综合报告生成

### 6. 监控管理脚本 (05_monitoring.sh)

**功能**: 监控系统状态、管理日志文件、生成监控报告

```bash
# 检查系统状态
./scripts/05_monitoring.sh --status

# 管理日志文件
./scripts/05_monitoring.sh --logs

# 清理旧日志
./scripts/05_monitoring.sh --clean

# 生成监控报告
./scripts/05_monitoring.sh --report

# 实时监控
./scripts/05_monitoring.sh --watch
```

### 7. 清理维护脚本 (06_maintenance.sh)

**功能**: 清理临时文件、维护项目、重置环境、备份重要数据

```bash
# 清理临时文件
./scripts/06_maintenance.sh --clean

# 重置环境
./scripts/06_maintenance.sh --reset

# 数据备份
./scripts/06_maintenance.sh --backup

# 性能优化
./scripts/06_maintenance.sh --optimize

# 全面维护
./scripts/06_maintenance.sh --all
```

### 8. 测试编排器脚本 (99_test_orchestrator.sh)

**功能**: 协调执行所有测试脚本，管理测试流程，生成综合报告

```bash
# 快速测试
./scripts/99_test_orchestrator.sh --quick

# 完整测试
./scripts/99_test_orchestrator.sh --full

# 性能专项测试
./scripts/99_test_orchestrator.sh --performance

# 集成专项测试
./scripts/99_test_orchestrator.sh --integration
```

## 🎯 推荐工作流程

### 首次使用
```bash
1. ./scripts/00_environment_setup.sh --install  # 配置环境
2. ./scripts/01_development_validation.sh       # 验证环境
3. ./scripts/02_performance_testing.sh          # 性能基准
```

### 日常开发
```bash
1. ./scripts/01_development_validation.sh       # 开发验证
2. ./scripts/run_comprehensive_test.sh --quick  # 快速测试
```

### 发布前检查
```bash
1. ./scripts/run_comprehensive_test.sh --full   # 完整测试
2. ./scripts/04_deployment.sh --package         # 打包部署
```

### 定期维护
```bash
# 每日
./scripts/06_maintenance.sh --clean             # 清理临时文件

# 每周
./scripts/06_maintenance.sh --backup            # 数据备份
./scripts/05_monitoring.sh --report             # 监控报告

# 每月
./scripts/06_maintenance.sh --all               # 全面维护
```

## 📊 输出和日志

### 结果目录结构
```
project_root/
├── validation_results/          # 开发验证结果
├── performance_results/         # 性能测试结果
├── integration_results/         # 集成测试结果
├── comprehensive_test_results/  # 综合测试结果
├── monitoring/                  # 监控报告
├── backups/                     # 数据备份
└── deployment/                  # 部署产物
```

### 日志文件
- **开发验证**: `validation_results/*.log`
- **性能测试**: `performance_results/performance_log.csv`
- **监控数据**: `monitoring/monitoring_report_*.md`
- **维护记录**: `maintenance.log`

## 🎨 新增特性 (v2.0)

### 1. 多频率批处理优化测试
- 单频率 vs 多频率性能对比
- 批处理优化效果验证
- 频率并行处理测试

### 2. 射线筛选优化测试
- 动态深度阈值验证
- 射线筛选效果分析
- 筛选算法性能测试

### 3. 增强的监控和维护
- 实时系统监控
- 自动日志清理
- 性能趋势分析
- 数据备份管理

### 4. 交互式脚本管理器
- 统一的操作界面
- 脚本状态检查
- 快速操作支持
- 详细的帮助系统

## 🔧 故障排除

### 常见问题

1. **脚本无法执行**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Python 模块导入失败**
   ```bash
   ./scripts/00_environment_setup.sh --install
   ```

3. **Bellhop 二进制文件未找到**
   - 检查路径: `/home/shunli/pro/at/bin/bellhop`
   - 更新 `python_core/config.py` 中的路径配置

4. **权限不足**
   ```bash
   sudo chown -R $USER:$USER .
   chmod +x scripts/*.sh
   ```

### 获取帮助

- 运行脚本管理器: `./scripts_manager.sh`
- 查看脚本帮助: `./scripts/脚本名.sh --help`
- 检查系统状态: `./scripts/05_monitoring.sh --status`

## 📞 支持

如需支持或报告问题，请检查:
1. 脚本执行日志
2. 系统监控报告
3. 错误日志文件 (`data/error_log.txt`)

---

*BellhopPropagationModel v2.0 - 多频率批处理 + 射线筛选优化*
