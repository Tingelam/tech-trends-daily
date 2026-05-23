# GitHub Pages 部署指南

## 📋 前置条件

1. **GitHub 账号**：需要有 GitHub 账号
2. **Git 已安装**：本地需要安装 Git
3. **GitHub CLI（可选）**：`gh` 命令行工具

## 🚀 部署流程

### 方案一：手动部署（最简单）

#### 步骤 1：创建 GitHub 仓库

```bash
# 方法 A：使用 GitHub CLI
gh repo create tech-trends-daily --public --source=. --remote=origin --push

# 方法 B：手动创建
# 1. 访问 https://github.com/new
# 2. 仓库名：tech-trends-daily
# 3. 选择 Public
# 4. 不要初始化 README
# 5. 点击 Create repository
```

#### 步骤 2：初始化本地 Git 仓库

```bash
cd ~/Documents/HermesReports/tech-trends/daily-reports

# 初始化 Git
git init

# 添加远程仓库
git remote add origin https://github.com/YOUR-USERNAME/tech-trends-daily.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: 前沿技术日报站点"

# 推送到 main 分支
git push -u origin main
```

#### 步骤 3：部署到 GitHub Pages

```bash
# 使用 MkDocs 内置的部署命令
mkdocs gh-deploy --force
```

这个命令会：
1. 构建站点到 `site/` 目录
2. 创建 `gh-pages` 分支
3. 将构建结果推送到 `gh-pages` 分支

#### 步骤 4：配置 GitHub Pages

1. 访问仓库页面：`https://github.com/YOUR-USERNAME/tech-trends-daily`
2. 点击 **Settings** 选项卡
3. 左侧菜单找到 **Pages**
4. **Source** 选择 `gh-pages` 分支
5. 点击 **Save**

等待 1-2 分钟，站点就会在以下地址可用：
```
https://YOUR-USERNAME.github.io/tech-trends-daily/
```

---

### 方案二：自动化部署（推荐）

#### 使用 GitHub Actions 自动部署

创建 `.github/workflows/deploy.yml` 文件：

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install mkdocs-material

      - name: Build site
        run: mkdocs build

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site
```

**使用方法：**
1. 创建 `.github/workflows/` 目录
2. 将上面的内容保存为 `deploy.yml`
3. 推送到 GitHub
4. 每次推送代码到 `main` 分支，都会自动部署

---

### 方案三：结合 Cron Job 自动更新

#### 步骤 1：设置 Cron Job 更新日报

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天 9:30 更新）
30 9 * * * cd ~/Documents/HermesReports/tech-trends/daily-reports && ./update-daily-reports.sh && git add . && git commit -m "Update daily report $(date +\%Y-\%m-\%d)" && git push
```

#### 步骤 2：GitHub Actions 自动部署

配置好 GitHub Actions 后，每次推送都会自动部署。

---

## 📊 部署方式对比

| 方式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **手动部署** | 简单直接 | 需要手动操作 | 一次性部署 |
| **GitHub Actions** | 自动化 | 需要配置 | 持续更新 |
| **Cron + Actions** | 全自动 | 配置复杂 | 每日更新 |

---

## 🔧 常见问题

### Q1: 部署后无法访问？

**检查清单：**
1. 仓库是否为 Public？
2. GitHub Pages 是否启用？
3. 分支是否选择 `gh-pages`？
4. 是否等待 1-2 分钟？

### Q2: 如何更新站点？

```bash
# 更新日报
./update-daily-reports.sh

# 提交并推送
git add .
git commit -m "Update daily report"
git push

# 如果配置了 GitHub Actions，会自动部署
# 否则手动部署
mkdocs gh-deploy --force
```

### Q3: 如何使用自定义域名？

1. 在仓库根目录创建 `CNAME` 文件，内容为你的域名
2. 在域名服务商设置 CNAME 记录指向 `YOUR-USERNAME.github.io`
3. 在 GitHub Pages 设置中填写自定义域名

### Q4: 如何设置访问权限？

**公开仓库：** 任何人都可以访问
**私有仓库：** 需要 GitHub Pro 或 Team 才能使用 Pages

---

## 💡 推荐方案

**如果你的需求是：**

1. **只是自己看** → 本地预览就够了
2. **偶尔分享** → 手动部署
3. **每天更新** → GitHub Actions 自动化
4. **团队使用** → 考虑私有仓库 + 自定义域名

---

## 🎯 快速开始（最简单）

```bash
# 1. 创建仓库
gh repo create tech-trends-daily --public

# 2. 初始化并推送
cd ~/Documents/HermesReports/tech-trends/daily-reports
git init
git remote add origin https://github.com/YOUR-USERNAME/tech-trends-daily.git
git add .
git commit -m "Initial commit"
git push -u origin main

# 3. 部署
mkdocs gh-deploy --force

# 4. 等待 1-2 分钟后访问
echo "访问: https://YOUR-USERNAME.github.io/tech-trends-daily/"
```
