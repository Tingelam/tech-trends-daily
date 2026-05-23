#!/bin/bash
# 每日自动更新并部署日报站点
# 用于 Cron Job 调用

set -e

# 配置路径
REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
DOCS_DIR="$REPORTS_DIR/daily-reports/docs/daily"
REPO_DIR="$REPORTS_DIR/daily-reports"
LOG_FILE="/tmp/daily-reports-deploy.log"

# 获取今天的日期
DATE=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%m)

echo "[$(date)] 开始更新日报站点: $DATE" >> "$LOG_FILE"

# 1. 进入仓库目录
cd "$REPO_DIR"

# 2. 拉取最新代码
git pull origin main --quiet >> "$LOG_FILE" 2>&1

# 3. 创建目录结构
mkdir -p "$DOCS_DIR/$YEAR/$MONTH"

# 4. 复制日报文件
SOURCE_FILE="$REPORTS_DIR/daily/$YEAR/$MONTH/$DATE.md"
if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$DOCS_DIR/$YEAR/$MONTH/"
    echo "[$(date)] 已复制日报文件: $SOURCE_FILE" >> "$LOG_FILE"
else
    echo "[$(date)] 未找到日报文件: $SOURCE_FILE" >> "$LOG_FILE"
    exit 1
fi

# 5. 更新导航配置（如果需要）
# 这里可以添加自动更新 mkdocs.yml 导航的逻辑

# 6. 提交并推送
git add .
if git diff --cached --quiet; then
    echo "[$(date)] 没有变更需要提交" >> "$LOG_FILE"
else
    git commit -m "Update daily report: $DATE" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
    echo "[$(date)] 已推送更新到 GitHub" >> "$LOG_FILE"
fi

echo "[$(date)] 日报站点更新完成" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
