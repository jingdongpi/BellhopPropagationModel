# GitHub Actions 构建指南

本项目已配置GitHub Actions自动构建，支持在推送代码时自动编译和测试项目。

## 🚀 自动构建

### 触发条件
- 推送到 `main`, `master`, `develop` 分支
- 创建Pull Request到上述分支
- 手动触发（在GitHub网页上）

### 构建环境
- **操作系统**: Ubuntu 20.04, Ubuntu 22.04
- **Python版本**: 3.8, 3.9, 3.10
- **构建矩阵**: 所有组合都会被测试

### 构建步骤
1. ✅ 检出代码
2. ✅ 安装Python环境
3. ✅ 安装系统依赖（CMake, GCC, Python开发库等）
4. ✅ 安装Python依赖（NumPy, SciPy）
5. ✅ 配置CMake
6. ✅ 编译项目
7. ✅ 验证构建产物
8. ✅ 运行CI测试
9. ✅ 上传构建文件

## 📦 发布流程

### 创建发布
```bash
# 创建标签并推送
git tag v1.0.0
git push origin v1.0.0
```

### 自动发布内容
- 编译后的可执行文件
- 动态库文件
- 头文件和文档
- 使用示例

## 🔧 本地验证

在提交代码前，可以本地运行CI测试：

```bash
# 构建项目
./manager.sh build

# 运行CI测试
./ci_test.sh
```

## 📋 构建状态

可以在以下位置查看构建状态：
- GitHub仓库的Actions标签页
- README徽章（如果添加的话）

## 🐛 故障排除

### 构建失败常见原因
1. **依赖问题**: 检查requirements.txt是否包含所有Python依赖
2. **编译错误**: 检查CMakeLists.txt配置和C++代码
3. **路径问题**: 确保manager.sh脚本工作正常
4. **权限问题**: 确保脚本有执行权限

### 查看详细日志
1. 在GitHub Actions页面点击失败的构建
2. 展开失败的步骤查看详细输出
3. 下载构建日志文件（如果有的话）

## 🎯 构建优化

### 加速构建
- 使用缓存功能缓存依赖
- 优化CMake配置
- 减少构建矩阵组合

### 添加更多测试
- 单元测试
- 集成测试
- 性能测试
- 覆盖率报告

## 📚 相关文件

- `.github/workflows/build.yml` - 主要构建工作流程
- `.github/workflows/release.yml` - 发布工作流程  
- `ci_test.sh` - CI测试脚本
- `requirements.txt` - Python依赖
- `manager.sh` - 项目管理脚本
