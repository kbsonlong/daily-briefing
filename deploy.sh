#!/bin/bash
# deploy.sh - Deploy daily tech report to GitHub Pages
set -e

DATE="$1"
REPORT_PATH="$2"
REPO_DIR="${3:-$HOME/daily-briefing}"

if [ -z "$DATE" ] || [ -z "$REPORT_PATH" ]; then
    echo "Usage: $0 <YYYY-MM-DD> <report-path>"
    exit 1
fi

# Create daily directory
mkdir -p "$REPO_DIR/daily/$DATE"

# Copy report
cp "$REPORT_PATH" "$REPO_DIR/daily/$DATE/report.md"

# Generate index.html
cat > "$REPO_DIR/daily/$DATE/index.html" << 'HTML'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>每日科技多源日报</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #0d1117; color: #c9d1d9; }
        a { color: #58a6ff; }
        h1 { border-bottom: 1px solid #30363d; padding-bottom: 10px; }
        h2 { color: #f0f6fc; margin-top: 30px; }
        pre { background: #161b22; padding: 16px; border-radius: 8px; overflow-x: auto; }
        code { background: #161b22; padding: 2px 6px; border-radius: 4px; }
        .meta { color: #8b949e; font-size: 0.9em; }
        hr { border: none; border-top: 1px solid #30363d; }
    </style>
</head>
<body>
    <h1>📡 每日科技多源日报</h1>
    <p class="meta">自动生成 • 数据来源: AI/GitHub/HN/Quora/科技媒体</p>
    <div id="content">
HTML

# Convert markdown to HTML (simple version)
echo "<pre>" >> "$REPO_DIR/daily/$DATE/index.html"
cat "$REPORT_PATH" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' >> "$REPO_DIR/daily/$DATE/index.html"
echo "</pre>" >> "$REPO_DIR/daily/$DATE/index.html"

cat >> "$REPO_DIR/daily/$DATE/index.html" << 'HTMLEOF'
    </div>
    <p class="meta"><a href="https://github.com/kbsonlong/daily-briefing">查看源码</a></p>
</body>
</html>
HTMLEOF

# Update dates.json
DATES_JSON="$REPO_DIR/dates.json"
if [ ! -f "$DATES_JSON" ]; then
    echo '{"dates":[]}' > "$DATES_JSON"
fi
python3 -c "
import json
with open('$DATES_JSON', 'r') as f:
    data = json.load(f)
if '$DATE' not in data['dates']:
    data['dates'].insert(0, '$DATE')
with open('$DATES_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"

# Update archive.md
ARCHIVE="$REPO_DIR/archive.md"
if [ ! -f "$ARCHIVE" ]; then
    echo "# 📚 日报归档" > "$ARCHIVE"
    echo "" >> "$ARCHIVE"
    echo "| 日期 | 链接 |" >> "$ARCHIVE"
    echo "|------|------|" >> "$ARCHIVE"
fi
if ! grep -q "$DATE" "$ARCHIVE" 2>/dev/null; then
    # Insert after header
    # Insert entry after table header (macOS/BSD sed compatible)
    { echo "| $DATE | [📄 日报](./daily/$DATE/) |"; tail -n +4 "$ARCHIVE"; } > "$ARCHIVE.tmp" && mv "$ARCHIVE.tmp" "$ARCHIVE"
fi

# Initialize git repo if needed
cd "$REPO_DIR"
if [ ! -d .git ]; then
    git init
    git checkout -b main
    git add .
    git commit -m "Initial commit: daily briefing infrastructure"
    git remote add origin https://github.com/kbsonlong/daily-briefing.git 2>/dev/null || true
    echo "Git repo initialized. Remote 'origin' set (update URL if needed)."
fi

# Commit and push
git add -A
git commit -m "📡 Daily tech report - $DATE" 2>/dev/null || echo "Nothing new to commit"
echo "Deploy complete: daily/$DATE/report.md"
echo "Try: git push origin main (if remote is configured)"
