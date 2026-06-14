#!/bin/bash
set -e
DATE="$1"
REPORT_FILE="$2"
if [ -z "$DATE" ] || [ -z "$REPORT_FILE" ]; then echo "Usage: $0 <date> <report-file>"; exit 1; fi
if [ ! -f "$REPORT_FILE" ]; then echo "Report file not found: $REPORT_FILE"; exit 1; fi
cd "$(dirname "$0")"
if [ ! -d .git ]; then git init && git checkout -b main; fi
mkdir -p "daily/$DATE"
cp "$REPORT_FILE" "daily/$DATE/report.md"
cat > "daily/$DATE/index.html" << HTMLEND
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><title>每日科技日报 - $DATE</title>
<style>body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;max-width:800px;margin:0 auto;padding:20px;line-height:1.6}
h1{color:#1a1a2e;border-bottom:3px solid #e94560;padding-bottom:10px}a{color:#0f3460}
pre{background:white;padding:20px;border:1px solid #ddd;border-radius:8px;white-space:pre-wrap;word-wrap:break-word;font-family:inherit;line-height:1.6}
.meta{color:#666;font-size:0.9em}</style></head><body><pre>
HTMLEND
cat "$REPORT_FILE" >> "daily/$DATE/index.html"
echo -e '</pre><hr><p class="meta">Daily Tech Briefing - $DATE</p></body></html>' >> "daily/$DATE/index.html"
echo "Created daily/$DATE/index.html"
if [ ! -f dates.json ]; then echo '{"dates":[]}' > dates.json; fi
python3 -c "import json; d=json.load(open('dates.json')); v='$DATE'; [d['dates'].insert(0,v) if v not in d['dates'] else None]; d['dates']=d['dates'][:365]; json.dump(d,open('dates.json','w'),indent=2); print('Updated dates.json')"
grep -q "^| $DATE |" archive.md 2>/dev/null || echo "| $DATE | [report](./daily/$DATE/report.md) / [HTML](./daily/$DATE/index.html) |" >> archive.md
F=$(python3 -c "import json; d=json.load(open('dates.json')); print(d['dates'][0] if d['dates'] else '')" 2>/dev/null)
cat > index.html << HEND
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><title>Daily Tech Briefing</title>
<style>body{font-family:-apple-system,sans-serif;max-width:800px;margin:0 auto;padding:20px;line-height:1.6}
h1{color:#1a1a2e;border-bottom:3px solid #e94560;padding-bottom:10px}
.card{background:white;border-radius:8px;padding:20px;margin:15px 0;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.latest{border-left:4px solid #e94560}a{color:#0f3460}.stats{color:#666;font-size:0.9em}</style></head><body>
<h1>Daily Tech Multi-Source Briefing</h1>
<div class="card"><p>6 sources: AI News, GitHub Trending, Hacker News, Quora, Tech Media, Medium</p></div>
HEND
if [ -n "$F" ]; then echo '<div class="card latest"><h3><a href="./daily/'"$F"'/index.html">'"$F"' report</a></h3></div>' >> index.html; fi
echo '<h2>Archive</h2><p><a href="./archive.md">View all</a></p><hr><p class="stats">Auto-generated</p></body></html>' >> index.html
git add -A && git commit -m "daily: $DATE" 2>/dev/null || true
git push origin main 2>/dev/null && echo "Pushed" || echo "Push skipped"
echo "=== Deploy complete for $DATE ==="
