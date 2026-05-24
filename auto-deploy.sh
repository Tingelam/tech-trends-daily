#!/bin/bash
# 每日自动同步日报到 MkDocs 仓库并触发 GitHub Pages 更新
# 用于 Cron Job 调用

set -euo pipefail

REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
REPO_DIR="$REPORTS_DIR/daily-reports"
LOG_FILE="/tmp/daily-reports-deploy.log"
DATE=${1:-$(date +%Y-%m-%d)}

echo "[$(date)] 开始更新日报站点: $DATE" >> "$LOG_FILE"

cd "$REPO_DIR"
git pull --rebase origin main >> "$LOG_FILE" 2>&1

# 统一同步源日报 -> docs/daily + docs/index，并执行 mkdocs build
./update-daily-reports.sh "$DATE" >> "$LOG_FILE" 2>&1

# 推送 main，GitHub Actions deploy.yml 会自动发布到 GitHub Pages
git add docs/index.md docs/daily mkdocs.yml README.md update-daily-reports.sh auto-deploy.sh .github/workflows/deploy.yml
if git diff --cached --quiet; then
    echo "[$(date)] 没有变更需要提交" >> "$LOG_FILE"
else
    git commit -m "Update daily report: $DATE" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
    echo "[$(date)] 已推送更新到 GitHub（等待 GitHub Actions 发布 Pages）" >> "$LOG_FILE"
fi

echo "[$(date)] 日报站点更新完成" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

# no_agent cron 使用：正常完成时保持静默
exit 0
