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

# 自动更新 mkdocs.yml nav：将新日期插入到对应年/月下（按日期倒序）
echo "📝 更新 mkdocs.yml 导航..."
MKDOCS_YML="$REPO_DIR/mkdocs.yml"
NAV_ENTRY="        - $DATE: daily/$YEAR/$MONTH/$DATE.md"
MONTH_LABEL="      $MONTH月:"
YEAR_LABEL="    $YEAR年:"

# 检查该日期是否已在 nav 中
if ! grep -qF "$DATE: daily/$YEAR/$MONTH/$DATE.md" "$MKDOCS_YML"; then
  # 如果该月份 section 不存在，插入整段
  if ! grep -qF "$MONTH_LABEL" "$MKDOCS_YML"; then
    # 在 "关于:" 之前插入新的年/月/日期
    sed -i "/^  - 关于:/i\\  - 日报:\\n    - $YEAR_LABEL\\n$MONTH_LABEL\\n$NAV_ENTRY" "$MKDOCS_YML"
    echo "✅ 新增 $YEAR/$MONTH 导航段 + $DATE"
  else
    # 月份已存在，在该月 section 下第一条之前插入新日期（保持倒序）
    # 找到该月标签的行号，在其后第一个条目前插入
    sed -i "/$MONTH_LABEL/a\\$NAV_ENTRY" "$MKDOCS_YML"
    echo "✅ 新增 $DATE 到 $YEAR/$MONTH 导航"
  fi
else
  echo "ℹ️ $DATE 已在导航中，跳过"
fi

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
