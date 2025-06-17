# 🔀 从Gitea推送到GitHub指南

你当前使用Gitea作为主要远程仓库，现在要将代码同步到GitHub以使用GitHub Actions。

## 🎯 目标
- 保持Gitea作为主要开发仓库
- 添加GitHub作为CI/CD仓库
- 实现双仓库同步

## 📋 详细步骤

### 1. 在GitHub创建仓库
1. 访问 https://github.com
2. 点击右上角 "+" → "New repository"
3. 仓库名称: `BellhopPropagationModel`
4. 设置为 Public 或 Private
5. ⚠️ **重要**: 不要勾选 "Initialize with README"
6. 点击 "Create repository"

### 2. 使用自动化脚本设置（推荐）

我们已经创建了一个管理脚本，运行：

```bash
./git_manager.sh setup-github
```

这个脚本会：
- 引导你完成GitHub仓库设置
- 自动添加GitHub远程仓库
- 询问是否立即推送代码

### 3. 手动设置方法

如果你更喜欢手动操作：

```bash
# 添加GitHub远程仓库（替换YOUR_USERNAME为你的GitHub用户名）
git remote add github https://github.com/YOUR_USERNAME/BellhopPropagationModel.git

# 推送到GitHub
git push github main

# 推送标签（如果有的话）
git push github --tags
```

### 4. 验证设置

```bash
# 查看远程仓库配置
./git_manager.sh status

# 或者使用Git命令
git remote -v
```

应该看到类似这样的输出：
```
origin    https://git.100118.xyz/wangsli/BellhopPropagationModel.git (fetch)
origin    https://git.100118.xyz/wangsli/BellhopPropagationModel.git (push)
github    https://github.com/YOUR_USERNAME/BellhopPropagationModel.git (fetch)
github    https://github.com/YOUR_USERNAME/BellhopPropagationModel.git (push)
```

## 🔄 日常使用工作流程

### 开发和提交代码
```bash
# 正常开发
git add .
git commit -m "你的提交信息"

# 同时推送到两个仓库
./git_manager.sh push-all

# 或者分别推送
./git_manager.sh push-gitea    # 推送到Gitea
./git_manager.sh push-github   # 推送到GitHub
```

### 创建发布版本
```bash
# 创建标签
git tag v1.0.0
git commit -m "Release v1.0.0"

# 同步所有仓库（包括标签）
./git_manager.sh sync
```

### 定期同步
```bash
# 同步两个远程仓库
./git_manager.sh sync
```

## 🚀 GitHub Actions触发

代码推送到GitHub后，GitHub Actions会自动：

1. **自动构建** (推送到main分支时)
   - 多平台测试
   - 自动编译
   - 运行测试
   - 上传构建产物

2. **自动发布** (推送版本标签时)
   - 创建GitHub Release
   - 上传发布包

## 🛠️ 管理脚本功能

我们创建的 `git_manager.sh` 脚本提供以下功能：

```bash
./git_manager.sh help          # 显示帮助
./git_manager.sh status        # 查看仓库状态
./git_manager.sh setup-github  # 交互式GitHub设置
./git_manager.sh push-all      # 推送到所有仓库
./git_manager.sh sync          # 同步所有仓库
```

## ⚠️ 注意事项

1. **GitHub仓库URL格式**:
   - HTTPS: `https://github.com/username/BellhopPropagationModel.git`
   - SSH: `git@github.com:username/BellhopPropagationModel.git`

2. **权限设置**:
   - 确保你有GitHub仓库的写入权限
   - 可能需要配置GitHub token用于推送

3. **分支同步**:
   - 默认同步main分支
   - 如需同步其他分支，手动指定

## 🎉 完成后

推送完成后，你可以：
1. 在GitHub仓库页面查看代码
2. 在Actions标签页查看自动构建状态
3. 创建第一个发布版本测试发布流程

---

现在运行 `./git_manager.sh setup-github` 开始设置吧！
