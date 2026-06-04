#!/bin/bash
set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_FILE="${2:-/tmp/daily-report.md}"
REPO_DIR="/data/daily-briefing"

if [ ! -f "$REPORT_FILE" ]; then
  echo "ERROR: Report file $REPORT_FILE not found"
  exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Initializing git repo for GitHub Pages..."
  cd "$REPO_DIR"
  git init
  git checkout -b main
  git config user.email "daily-bot@hermes-agent.local"
  git config user.name "Daily Report Bot"
  cat > index.md << 'INDEXEOF'
---
layout: default
title: 每日科技多源日报
---

# 📡 每日科技多源日报

欢迎访问每日科技多源日报归档页面。

[查看最新日报](./daily/latest.md) | [归档](./archive.md)

Powered by Hermes Agent
INDEXEOF
  git add -A
  git commit -m "Initial setup"
fi

mkdir -p "$REPO_DIR/daily"
cp "$REPORT_FILE" "$REPO_DIR/daily/${DATE}.md"
cp "$REPORT_FILE" "$REPO_DIR/daily/latest.md"

cd "$REPO_DIR"
{
  echo "# 📚 日报归档"
  echo ""
  echo "| 日期 | 链接 |"
  echo "|------|------|"
  for f in $(ls -1 daily/*.md 2>/dev/null | sort -r | head -30); do
    name=$(basename "$f" .md)
    if [ "$name" != "latest" ]; then
      echo "| $name | [查看](./$f) |"
    fi
  done
} > archive.md

git add -A
git commit -m "Daily report for $DATE" || echo "No changes to commit"

if git remote get-url origin &>/dev/null && [ -n "$(git remote get-url origin)" ]; then
  git push origin main 2>/dev/null || echo "Push skipped (no remote or auth configured)"
fi

echo "Deploy complete: daily/${DATE}.md"
