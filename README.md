# 每日日报站点自动更新

## 项目结构

```
daily-reports/
├── mkdocs.yml              # MkDocs 配置文件
├── docs/                   # 文档源文件
│   ├── index.md            # 首页
│   ├── about.md            # 关于页面
│   ├── stylesheets/        # 自定义样式
│   │   └── extra.css
│   ├── overrides/          # 自定义模板
│   └── daily/              # 日报文件
│       └── 2026/
│           └── 05/
│               ├── 2026-05-22.md
│               └── 2026-05-23.md
├── site/                   # 生成的静态站点
├── update-daily-reports.sh # 更新脚本
├── deploy.sh               # 部署脚本
└── README.md               # 本文件
```

## 快速开始

### 1. 本地预览

```bash
cd ~/Documents/HermesReports/tech-trends/daily-reports
mkdocs serve
```

访问 http://localhost:8080

### 2. 更新日报

```bash
# 更新今天的日报
./update-daily-reports.sh

# 更新指定日期的日报
./update-daily-reports.sh 2026-05-23
```

### 3. 部署到 GitHub Pages

```bash
# 本地手动触发一次完整同步 + 推送
./auto-deploy.sh

# 仅本地构建检查
./update-daily-reports.sh 2026-05-23
```

## 自动化

### Cron Job 设置

当前推荐做法：**日报生成 Cron 保持 09:00 产出源报告，随后自动执行站点同步脚本，把最新报告推到 GitHub main，再由 GitHub Actions 自动发布 GitHub Pages。**

```bash
# 仅站点同步/推送（如果用系统 crontab）
30 9 * * * cd ~/Documents/HermesReports/tech-trends/daily-reports && ./auto-deploy.sh >> /tmp/daily-reports-update.log 2>&1
```

**同步规则：** `update-daily-reports.sh` 会把 `~/Documents/HermesReports/tech-trends/daily/YYYY/MM/YYYY-MM-DD.md` 同步到：
- `docs/daily/YYYY/MM/YYYY-MM-DD.md`
- `docs/index.md`（首页直接复用同一主体内容，仅补最小 front matter）

这样首页和日报详情页会保持同一风格与同一内容基调，不会再出现首页/详情页分裂。

**发布规则：** `auto-deploy.sh` 会依次执行：
1. `git pull --rebase origin main`
2. `./update-daily-reports.sh [日期]`
3. `git add + commit + push origin main`
4. 由 `.github/workflows/deploy.yml` 自动构建并发布到 GitHub Pages

### Hermes Agent 集成

当前 Hermes 已有日报 Cron：`8e435f20e77b`（每天 09:00）。若要做到“日报生成后自动更新 GitHub Pages”，建议把该 Cron 的提示词补充为：生成并写入源日报文件后，再执行 `~/Documents/HermesReports/tech-trends/daily-reports/auto-deploy.sh`，让 GitHub Pages 自动刷新。

## 自定义配置

### 修改站点信息

编辑 `mkdocs.yml`：

```yaml
site_name: 你的站点名称
site_description: 你的站点描述
repo_url: https://github.com/your-username/your-repo
```

### 修改主题颜色

编辑 `mkdocs.yml` 中的 `palette` 配置：

```yaml
palette:
  primary: blue  # 主题色
  accent: blue   # 强调色
```

### 添加自定义样式

编辑 `docs/stylesheets/extra.css`：

```css
/* 自定义样式 */
.md-typeset h1 {
  color: #your-color;
}
