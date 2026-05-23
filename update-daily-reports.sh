#!/bin/bash
# 每日日报站点更新脚本
# 用法: ./update-daily-reports.sh [日期]
# 示例: ./update-daily-reports.sh 2026-05-23

set -e

# 配置路径
REPORTS_DIR="$HOME/Documents/HermesReports/tech-trends"
DOCS_DIR="$REPORTS_DIR/daily-reports/docs/daily"
REPO_DIR="$REPORTS_DIR/daily-reports"

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

# 3. 从日报中提取今日概览，更新首页
echo "📝 更新首页今日概览..."
python3 << 'PYEOF'
import re
import os

reports_dir = os.environ.get("REPORTS_DIR", "")
date = os.environ.get("DATE", "")
year = os.environ.get("YEAR", "")
month = os.environ.get("MONTH", "")

# 读取今日日报
report_file = os.path.join(reports_dir, "daily", year, month, f"{date}.md")
index_file = os.path.join(reports_dir, "daily-reports", "docs", "index.md")

if not os.path.exists(report_file):
    print(f"⚠️  日报文件不存在: {report_file}")
    exit(1)

with open(report_file, "r", encoding="utf-8") as f:
    report_content = f.read()

# 提取数据来源信息
meta_match = re.search(r"> 数据来源：(.+?)\n> 采集时间：(.+?) \| (.+?)$", report_content, re.MULTILINE)
data_source = meta_match.group(1) if meta_match else "多源数据"
collect_time = meta_match.group(2) if meta_match else date
data_stats = meta_match.group(3) if meta_match else ""

# 提取今日概览（3条重点）
overview_match = re.search(r"## 🧭 今日概览.*?\n\n(.*?)(?=\n---)", report_content, re.DOTALL)
overview_content = overview_match.group(1).strip() if overview_match else "暂无数据"

# 提取 AI/LLM 前3条
ai_section = re.search(r"## 🧠 AI / LLM\n\n(.*?)(?=\n---)", report_content, re.DOTALL)
ai_items = []
if ai_section:
    lines = ai_section.group(1).strip().split("\n")
    count = 0
    for line in lines:
        if line.startswith("**") and count < 3:
            # 提取标题和链接
            match = re.match(r'\*\*(\d+)\. \[(.+?)\]\((.+?)\)\*\*.*?—\s*(.+?)$', line)
            if match:
                ai_items.append({
                    "num": match.group(1),
                    "title": match.group(2),
                    "url": match.group(3),
                    "heat": match.group(4).strip()
                })
                count += 1

# 提取开发者工具前3条
dev_section = re.search(r"## 🛠 开发者工具\n\n(.*?)(?=\n---)", report_content, re.DOTALL)
dev_items = []
if dev_section:
    lines = dev_section.group(1).strip().split("\n")
    count = 0
    for line in lines:
        if line.startswith("**") and count < 3:
            match = re.match(r'\*\*(\d+)\. \[(.+?)\]\((.+?)\)\*\*.*?—\s*(.+?)$', line)
            if match:
                dev_items.append({
                    "num": match.group(1),
                    "title": match.group(2),
                    "url": match.group(3),
                    "heat": match.group(4).strip()
                })
                count += 1

# 生成首页内容
def gen_overview_block():
    lines = overview_content.split("\n")
    result = []
    for line in lines:
        line = line.strip()
        if line.startswith("**") or line.startswith("1.") or line.startswith("2.") or line.startswith("3."):
            result.append(line)
    return "\n\n".join(result)

def gen_table(items):
    if not items:
        return "| - | 暂无数据 | - |"
    rows = []
    for item in items:
        rows.append(f"| {item['num']} | [{item['title']}]({item['url']}) | {item['heat']} |")
    return "| # | 标题 | 热度 |\n|---|------|------|\n" + "\n".join(rows)

# 提取亮点关键词
def extract_highlights():
    highlights = []
    for item in (ai_items + dev_items)[:3]:
        # 提取标题前几个字作为关键词
        title = item['title']
        if len(title) > 15:
            title = title[:15] + "..."
        highlights.append(title)
    return "、".join(highlights)

highlights = extract_highlights()

index_content = f"""# 前沿技术日报

欢迎来到**前沿技术日报**站点！这里汇集了每日最新的技术趋势报告，涵盖 AI/LLM、开发者工具、开源项目等前沿技术动态。

---

## 🧭 今日概览 | {date}

> 数据来源：{data_source} | {collect_time} | {data_stats}

<div class="admonition abstract">
<p class="admonition-title">📌 3 条最重要的技术动态</p>

{gen_overview_block()}

</div>

[:octicons-arrow-right-24: 查看完整日报](daily/{year}/{month}/{date}.md){{ .md-button .md-button--primary }}

---

## 📊 各分类速览

### 🧠 AI / LLM

{gen_table(ai_items)}

### 🛠 开发者工具

{gen_table(dev_items)}

[:octicons-arrow-right-24: 查看完整日报](daily/{year}/{month}/{date}.md){{ .md-button }}

---

## 📅 历史日报

| 日期 | 亮点 |
|------|------|
| [{date}](daily/{year}/{month}/{date}.md) | {highlights} |

---

## 📈 数据来源

<div class="grid cards" markdown>

-   :fontawesome-brands-hacker-news:{{ .lg .middle }} **Hacker News**

    ---

    技术社区讨论热度

-   :fontawesome-brands-github:{{ .lg .middle }} **GitHub**

    ---

    开源项目 Stars 趋势

-   :fontawesome-brands-python:{{ .lg .middle }} **HuggingFace**

    ---

    AI 模型和论文动态

-   :fontawesome-brands-reddit:{{ .lg .middle }} **Reddit**

    ---

    技术社区讨论

</div>

---

<div class="admonition tip">
<p class="admonition-title">💡 使用提示</p>
<p>使用顶部的<strong>搜索框</strong>可以快速搜索任意关键词，支持中英文搜索。</p>
<p>点击左侧导航栏可以按月份浏览历史日报。</p>
</div>
"""

with open(index_file, "w", encoding="utf-8") as f:
    f.write(index_content)

print(f"✅ 首页已更新: {index_file}")
PYEOF

# 4. 构建站点
echo "🔨 构建站点..."
cd "$REPO_DIR"
mkdocs build --clean

# 5. 显示统计信息
echo ""
echo "📊 统计信息:"
echo "   - 日报文件: $(ls -1 "$DOCS_DIR"/*/*/*.md 2>/dev/null | wc -l) 个"
echo "   - 站点大小: $(du -sh "$REPO_DIR/site" 2>/dev/null | cut -f1)"
echo "   - 构建时间: $(date)"

echo ""
echo "✅ 站点更新完成！"
