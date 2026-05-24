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
./deploy.sh
```

## 自动化

### Cron Job 设置

每天上午 9:30 自动更新站点：

```bash
# 编辑 crontab
crontab -e

# 添加以下行
30 9 * * * cd ~/Documents/HermesReports/tech-trends/daily-reports && ./update-daily-reports.sh >> /tmp/daily-reports-update.log 2>&1
```

**同步规则：** `update-daily-reports.sh` 会把 `~/Documents/HermesReports/tech-trends/daily/YYYY/MM/YYYY-MM-DD.md` 同步到：
- `docs/daily/YYYY/MM/YYYY-MM-DD.md`
- `docs/index.md`（首页直接复用同一主体内容，仅补最小 front matter）

这样首页和日报详情页会保持同一风格与同一内容基调，不会再出现首页/详情页分裂。

### Hermes Agent 集成

在 Hermes Agent 中设置定时任务：

```yaml
# 每天 9:30 更新日报站点
schedule: "30 9 * * *"
prompt: "运行日报站点更新脚本"
```

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
