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
        km = re.match(r'\d+\.\s*\*\*\[(.+?)\]\((.+?)\)\*\*\s*[—–-]\s*(.+)$', line.strip())
        if km:
            title, url, rest = km.group(1), km.group(2), km.group(3)
            heat_m = re.search(r'HN\s*(\d+)分', rest)
            heat = f"HN {heat_m.group(1)}分" if heat_m else ""
            desc = re.sub(r'HN\s*\d+分\s*/\s*\d+评论[，,]?\s*', '', rest).strip()
            if len(desc) > 50:
                desc = desc[:50] + "..."
            overview_items.append({"title": title, "url": url, "heat": heat, "desc": desc})

# --- 提取 AI/LLM 前5条 ---
ai_items = []
m = re.search(r"## 🧠 AI / LLM\n\n(.*?)(?=\n---)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        # 匹配新格式: **N. [标题](url)** `来源` `热度`
        am = re.match(r'\*\*\d+\.\s*\[(.+?)\]\((.+?)\)\*\*\s*`(\w+)`\s*`(.+?)`', line.strip())
        if am:
            ai_items.append({
                "title": am.group(1),
                "url": am.group(2),
                "source": am.group(3),
                "heat": am.group(4)
            })

# --- 提取开发者工具前5条 ---
dev_items = []
m = re.search(r"## 🛠 开发者工具\n\n(.*?)(?=\n---)", report, re.DOTALL)
if m:
    for line in m.group(1).strip().split("\n"):
        dm = re.match(r'\*\*\d+\.\s*\[(.+?)\]\((.+?)\)\*\*\s*`(\w+)`\s*`(.+?)`', line.strip())
        if dm:
            dev_items.append({
                "title": dm.group(1),
                "url": dm.group(2),
                "source": dm.group(3),
                "heat": dm.group(4)
            })

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

if date not in existing_history:
    hl = [item["title"][:12] for item in overview_items[:3]]
    new_row = f"| [{date}](daily/{year}/{month}/{date}.md) | {' · '.join(hl)} |"
    if "|------|------|" in existing_history:
        existing_history = existing_history.replace(
            "|------|------|",
            f"|------|------|\n{new_row}"
        )

# --- 组装首页 ---
# 核心资讯卡片
cards = ""
for item in overview_items[:3]:
    cards += f'''
-   **[{item["title"]}]({item["url"]})** `{item["heat"]}`

    ---

    {item["desc"]}

'''

# AI/LLM 表格
ai_table = "| 技术 | 创新点 | 来源 |\n|------|--------|------|\n"
for item in ai_items[:5]:
    ai_table += f"| [{item['title']}]({item['url']}) | - | `{item['source']}` `{item['heat']}` |\n"

# 开发者工具表格
dev_table = "| 工具 | 核心功能 | 来源 |\n|------|----------|------|\n"
for item in dev_items[:5]:
    dev_table += f"| [{item['title']}]({item['url']}) | - | `{item['source']}` `{item['heat']}` |\n"

# 数据看板
icons = ["material-fire", "material-comment-text", "material-arrow-up-bold", "material-star"]
dash = ""
for i, item in enumerate(dashboard_items[:4]):
    icon = icons[i] if i < len(icons) else "material-chart-line"
    dash += f'''
-   :{icon}:{{ .lg .middle }} **{item["value"]}**

    ---

    [{item["title"]}]({item["url"]})
'''

# 趋势洞察
ins = ""
for i, item in enumerate(insights[:3], 1):
    ins += f"{i}. **{item['bold']}** — {item['rest']}\n"

# 值得关注
nt = ""
for item in notable[:4]:
    nt += f"- **[{item['title']}]({item['url']})** — {item['desc']}\n"

index = f"""# 前沿技术日报

<div class="admonition quote" style="border-left-color: var(--md-accent-fg-color); padding: 8px 16px; margin-bottom: 0;">
<p style="margin: 0; font-size: 0.85em; color: var(--md-default-fg-color--light);">
📡 {date} · {src_count} · <strong>{data_stats}</strong> · {collect_time} ✅
</p>
</div>

---

## 📌 核心资讯

<div class="grid cards" markdown>
{cards}
</div>

---

## 🧠 AI / LLM · 技术要点

{ai_table}

---

## 🛠 开发者工具 · 实用价值

{dev_table}

---

## 📊 数据看板

<div class="grid cards" markdown>
{dash}
</div>

---

## 💡 趋势洞察

{ins}
[:octicons-arrow-right-24: 完整日报](daily/{year}/{month}/{date}.md){{ .md-button .md-button--primary }}

---

## ⚡ 值得关注

{nt}
---

## 📅 历史日报

{existing_history}

---

<div style="text-align: center; font-size: 0.75em; color: var(--md-default-fg-color--lightest);">
数据来源：<a href="https://news.ycombinator.com">Hacker News</a> · <a href="https://huggingface.co/papers">HuggingFace Papers</a> · <a href="https://github.com/trending">GitHub</a> · 由 Hermes Agent 自动生成
</div>
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
