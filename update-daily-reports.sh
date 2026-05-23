#!/bin/bash
# 每日日报站点更新脚本
# 用法: ./update-daily-reports.sh [日期]

set -e

REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
DOCS_DIR="$REPORTS_DIR/daily-reports/docs/daily"
REPO_DIR="$REPORTS_DIR/daily-reports"

DATE=${1:-$(date +%Y-%m-%d)}
YEAR=$(echo $DATE | cut -d'-' -f1)
MONTH=$(echo $DATE | cut -d'-' -f2)

echo "📅 更新日报站点: $DATE"

mkdir -p "$DOCS_DIR/$YEAR/$MONTH"

SOURCE_FILE="$REPORTS_DIR/daily/$YEAR/$MONTH/$DATE.md"
if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$DOCS_DIR/$YEAR/$MONTH/"
    echo "✅ 已复制: $SOURCE_FILE"
else
    echo "⚠️  未找到日报文件: $SOURCE_FILE"
    exit 1
fi

echo "📝 更新首页..."
python3 << 'PYEOF'
import re
import os

reports_dir = os.environ.get("REPORTS_DIR", "")
date = os.environ.get("DATE", "")
year = os.environ.get("YEAR", "")
month = os.environ.get("MONTH", "")

report_file = os.path.join(reports_dir, "daily", year, month, f"{date}.md")
index_file = os.path.join(reports_dir, "daily-reports", "docs", "index.md")

with open(report_file, "r", encoding="utf-8") as f:
    report = f.read()

# --- 提取今日概览 ---
overview_items = []
m = re.search(r"## 🧭 今日概览.*?\n\n(.*?)(?=\n---)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        # 格式: 1. **[标题](链接)** — 描述，HN 351分/218评论，更多描述。
        km = re.match(r'\d+\.\s*\*\*\[(.+?)\]\((.+?)\)\*\*\s*[—–-]\s*(.+)$', line.strip())
        if km:
            title, url, rest = km.group(1), km.group(2), km.group(3)
            # 提取热度
            heat_m = re.search(r'HN\s*(\d+)分', rest)
            heat = f"HN {heat_m.group(1)}分" if heat_m else ""
            # 提取一句话描述（去掉热度信息）
            desc = re.sub(r'HN\s*\d+分\s*/\s*\d+评论[，,]?\s*', '', rest).strip()
            if len(desc) > 60:
                desc = desc[:60] + "..."
            overview_items.append({"title": title, "url": url, "heat": heat, "desc": desc})

# --- 提取数据看板 ---
dashboard_items = []
m = re.search(r"## 📊 数据看板\n\n\|.*?\n\|[-| ]+\n((?:\|.*?\n)+)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        dm = re.match(r'\|\s*(.+?)\s*\|\s*([\d,]+)\S*\s*—\s*\[(.+?)\]\((.+?)\)', line)
        if dm:
            dashboard_items.append({
                "metric": dm.group(1).strip(),
                "value": dm.group(2).strip(),
                "title": dm.group(3),
                "url": dm.group(4)
            })

# --- 提取趋势洞察 ---
insights = []
m = re.search(r"## 💡 趋势洞察\n\n(.*?)(?=\n---)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        im = re.match(r'\d+\.\s*\*\*(.+?)\*\*\s*[—–-]\s*(.+)$', line.strip())
        if im:
            insights.append({"bold": im.group(1), "rest": im.group(2).strip()})

# --- 提取值得关注 ---
notable = []
m = re.search(r"## ⚡ 值得关注\n\n(.*?)(?=\n---|\Z)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        nm = re.match(r'\d+\.\s*\*\*\[(.+?)\]\((.+?)\)\*\*\s*[—–-]\s*(.+)$', line.strip())
        if nm:
            notable.append({"title": nm.group(1), "url": nm.group(2), "desc": nm.group(3).strip()})

# --- 提取数据来源 ---
meta_m = re.search(r"> 数据来源：(.+?)$", report, re.MULTILINE)
src_count = meta_m.group(1).strip() if meta_m else ""
time_m = re.search(r"> 采集时间：(.+?) \| (.+?)$", report, re.MULTILINE)
collect_time = time_m.group(1).strip() if time_m else ""
data_stats = time_m.group(2).strip() if time_m else ""

# --- 读取现有历史日报 ---
existing_history = "| 日期 | 亮点 |\n|------|------|\n"
if os.path.exists(index_file):
    with open(index_file, "r", encoding="utf-8") as f:
        old = f.read()
    hm = re.search(r"## 📅 历史日报\n\n(.*?)(?=\n---|\Z)", old, re.DOTALL)
    if hm:
        existing_history = hm.group(1).strip()
        if not existing_history.startswith("|"):
            existing_history = "| 日期 | 亮点 |\n|------|------|\n" + existing_history

# 更新历史列表
if date not in existing_history:
    hl = [item["title"][:15] for item in overview_items[:3]]
    new_row = f"| [{date}](daily/{year}/{month}/{date}.md) | {' · '.join(hl)} |"
    if "|------|------|" in existing_history:
        existing_history = existing_history.replace(
            "|------|------|",
            f"|------|------|\n{new_row}"
        )

# --- 组装首页 ---
cards = ""
for item in overview_items[:3]:
    cards += f'''
-   **{item["title"]}** `{item["heat"]}`

    ---

    {item["desc"]}

    [:octicons-link-external-24: 原文]({item["url"]}){{ .md-button }}
'''

icons = ["material-fire", "material-comment-text", "material-arrow-up-bold", "material-star"]
dash = ""
for i, item in enumerate(dashboard_items[:4]):
    icon = icons[i] if i < len(icons) else "material-chart-line"
    dash += f'''
-   :{icon}:{{ .lg .middle }} **{item["value"]}**

    ---

    {item["metric"]}

    [{item["title"]}]({item["url"]})
'''

ins = ""
for i, item in enumerate(insights[:4], 1):
    ins += f"{i}. **{item['bold']}** — {item['rest']}\n"

nt = "| 项目 | 说明 |\n|------|------|\n"
for item in notable[:4]:
    nt += f"| [{item['title']}]({item['url']}) | {item['desc']} |\n"

index = f"""# 前沿技术日报

<div class="admonition info" style="border-left-color: var(--md-accent-fg-color);">
<p class="admonition-title" style="background: var(--md-accent-fg-color--transparent);">📡 {date} · 数据采集状态</p>
<p><strong>{src_count}</strong> · {collect_time} · <strong>{data_stats}</strong></p>
</div>

---

## 📌 今日三句话

<div class="grid cards" markdown>
{cards}
</div>

---

## 📊 数据看板

<div class="grid cards" markdown>
{dash}
</div>

---

## 💡 趋势洞察

{ins}
[:octicons-arrow-right-24: 查看完整日报](daily/{year}/{month}/{date}.md){{ .md-button .md-button--primary }}

---

## ⚡ 值得关注

{nt}
---

## 📅 历史日报

{existing_history}
"""

with open(index_file, "w", encoding="utf-8") as f:
    f.write(index)

print(f"✅ 首页已更新")
PYEOF

echo "🔨 构建站点..."
cd "$REPO_DIR"
mkdocs build --clean

echo ""
echo "✅ 站点更新完成！"
