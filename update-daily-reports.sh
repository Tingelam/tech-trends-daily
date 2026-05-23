#!/bin/bash
# 每日日报站点更新脚本
# 用法: ./update-daily-reports.sh [日期]
# 示例: ./update-daily-reports.sh 2026-05-23

set -e

# 配置路径
REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
DOCS_DIR="$REPORTS_DIR/daily-reports/docs/daily"
SITE_DIR="$REPORTS_DIR/daily-reports/site"

# 获取日期参数，默认为今天
DATE=${1:-$(date +%Y-%m-%d)}
YEAR=$(echo $DATE | cut -d'-' -f1)
MONTH=$(echo $DATE | cut -d'-' -f2)

echo "📅 更新日报站点: $DATE"

# 1. 创建目录结构
echo "📁 创建目录结构..."
mkdir -p "$DOCS_DIR/$YEAR/$MONTH"

# 2. 复制日报文件
echo "📄 复制日报文件..."
SOURCE_FILE="$REPORTS_DIR/daily/$YEAR/$MONTH/$DATE.md"
if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$DOCS_DIR/$YEAR/$MONTH/"
    echo "✅ 已复制: $SOURCE_FILE"
else
    echo "⚠️  未找到日报文件: $SOURCE_FILE"
    exit 1
fi

# 3. 更新导航配置
echo "📝 更新导航配置..."
cd "$REPORTS_DIR/daily-reports"

# 获取当前月份的所有日报文件
MONTH_FILES=$(ls -1 "$DOCS_DIR/$YEAR/$MONTH/"*.md 2>/dev/null | sort -r)

# 生成导航配置
NAV_CONFIG="  - 日报:\n    - $YEAR 年:\n      - $((10#$MONTH)) 月:"
for file in $MONTH_FILES; do
    filename=$(basename "$file" .md)
    NAV_CONFIG="$NAV_CONFIG\n        - $filename: daily/$YEAR/$MONTH/$filename.md"
done

# 更新 mkdocs.yml 中的导航配置
sed -i "/^nav:/,/^  - 关于:/{/^  - 日报:/,/^  - 关于:/c\\
$NAV_CONFIG
  - 关于: about.md
}" mkdocs.yml

# 4. 构建站点
echo "🔨 构建站点..."
mkdocs build --clean

# 5. 显示统计信息
echo ""
echo "📊 统计信息:"
echo "   - 日报文件: $(ls -1 "$DOCS_DIR"/*/*/*.md 2>/dev/null | wc -l) 个"
echo "   - 站点大小: $(du -sh "$SITE_DIR" 2>/dev/null | cut -f1)"
echo "   - 构建时间: $(date)"

echo ""
echo "✅ 站点更新完成！"
echo "🌐 本地预览: cd $REPORTS_DIR/daily-reports && mkdocs serve"
echo "🚀 部署到 GitHub Pages: mkdocs gh-deploy"
