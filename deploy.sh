#!/bin/bash
# 部署日报站点到 GitHub Pages
# 用法: ./deploy.sh

set -e

# 配置路径
REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
cd "$REPORTS_DIR/daily-reports"

echo "🚀 部署日报站点到 GitHub Pages..."

# 1. 检查 Git 状态
echo "📋 检查 Git 状态..."
if [ ! -d ".git" ]; then
    echo "⚠️  未初始化 Git 仓库，正在初始化..."
    git init
    git remote add origin https://github.com/your-username/tech-trends-daily.git
fi

# 2. 构建站点
echo "🔨 构建站点..."
mkdocs build --clean

# 3. 部署到 GitHub Pages
echo "📤 部署到 GitHub Pages..."
mkdocs gh-deploy --force

echo ""
echo "✅ 部署完成！"
echo "🌐 站点地址: https://your-username.github.io/tech-trends-daily/"
echo ""
echo "📝 后续步骤:"
echo "   1. 在 GitHub 仓库设置中启用 GitHub Pages"
echo "   2. 选择 'gh-pages' 分支作为源"
echo "   3. 等待几分钟让站点生效"
