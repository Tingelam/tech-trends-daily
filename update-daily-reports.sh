#!/bin/bash
# 每日日报站点更新脚本
# 用法: ./update-daily-reports.sh [日期]

set -euo pipefail

REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
DOCS_DIR="$REPORTS_DIR/daily-reports/docs/daily"
REPO_DIR="$REPORTS_DIR/daily-reports"

DATE=${1:-$(date +%Y-%m-%d)}
YEAR=$(echo "$DATE" | cut -d'-' -f1)
MONTH=$(echo "$DATE" | cut -d'-' -f2)

SOURCE_FILE="$REPORTS_DIR/daily/$YEAR/$MONTH/$DATE.md"
TARGET_DIR="$DOCS_DIR/$YEAR/$MONTH"
TARGET_FILE="$TARGET_DIR/$DATE.md"

echo "📅 更新日报站点: $DATE"
mkdir -p "$TARGET_DIR"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "⚠️ 未找到日报文件: $SOURCE_FILE"
  exit 1
fi

cp "$SOURCE_FILE" "$TARGET_FILE"
echo "✅ 已复制日报: $SOURCE_FILE -> $TARGET_FILE"

echo "📝 同步首页（与日报保持同风格/同内容基调）..."
DATE="$DATE" YEAR="$YEAR" MONTH="$MONTH" python3 <<'PYEOF'
from pathlib import Path
import os

reports_dir = Path.home() / 'Documents' / 'HermesReports' / 'tech-trends'
date = os.environ['DATE']
year = os.environ['YEAR']
month = os.environ['MONTH']
source_file = reports_dir / 'daily' / year / month / f'{date}.md'
target_file = reports_dir / 'daily-reports' / 'docs' / 'daily' / year / month / f'{date}.md'
index_file = reports_dir / 'daily-reports' / 'docs' / 'index.md'

content = source_file.read_text(encoding='utf-8').strip() + '\n'
target_file.write_text(content, encoding='utf-8')
index_file.write_text('---\ntitle: 前沿技术日报\n---\n\n' + content, encoding='utf-8')
print(f'✅ 日报页已同步: {target_file}')
print(f'✅ 首页已同步: {index_file}')
PYEOF

echo "🔨 构建站点..."
cd "$REPO_DIR"
mkdocs build --clean

echo "✅ 站点更新完成！"
