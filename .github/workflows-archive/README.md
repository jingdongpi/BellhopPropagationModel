# GitHub Actions 工作流存档

本目录包含已废弃的 GitHub Actions 工作流配置文件。

## 存档原因

项目已改为**本地 Docker 构建**方案，不再依赖 GitHub Actions 云端 CI/CD。

## 存档文件

- `build.yml` - 原始的多平台构建工作流
- `multi-platform-docker.yml` - Docker 多平台构建工作流  
- `release.yml` - 发布工作流

## 新的构建方案

请使用以下本地构建脚本：

- **Linux/macOS**: `build_local.sh`
- **Windows**: `build_windows.ps1`

详细说明请参考：`LOCAL_BUILD_GUIDE.md`

## 历史记录

这些工作流曾用于：
- 多平台自动构建（CentOS 7, Debian 11, Windows 11）
- 处理 GLIBC 兼容性问题
- Python/C++ 依赖管理
- Nuitka 编译自动化

现在所有功能都已迁移到本地 Docker 构建脚本中。

---

如需恢复云端构建，可以将相关文件移回 `.github/workflows/` 目录。
