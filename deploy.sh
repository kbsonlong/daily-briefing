#!/bin/bash
# deploy.sh — Full deployment pipeline for daily-briefing GitHub Pages site
set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
SOURCE="${2:-/tmp/daily-report.md}"
ROOT="/data/daily-briefing"

REPORT_DIR="${ROOT}/daily/${DATE}"
INDEX_TPL="${ROOT}/template.html"
DATES_JSON="${ROOT}/dates.json"

# ── 1. Create daily directory ──
mkdir -p "$REPORT_DIR"

# ── 2. Copy report ──
cp "$SOURCE" "${REPORT_DIR}/report.md"
# Also save to reports/ for convenience
mkdir -p "${ROOT}/reports"
cp "$SOURCE" "${ROOT}/reports/latest.md"
cp "$SOURCE" "${ROOT}/reports/daily-briefing-${DATE}.md"
echo "✅ Report saved: ${REPORT_DIR}/report.md ($(wc -c < "$SOURCE") bytes)"

# ── 3. Generate index.html from template ──
cp "$INDEX_TPL" "${REPORT_DIR}/index.html"
echo "✅ HTML generated: ${REPORT_DIR}/index.html"

# ── 4. Update dates.json ──
# Add new date at beginning, keep most recent first, remove duplicates
if [ -f "$DATES_JSON" ]; then
  python3 -c "
import json, sys
dates_file = '$DATES_JSON'
new_date = '$DATE'

with open(dates_file) as f:
    dates = json.load(f)

# Remove if already exists
dates = [d for d in dates if d != new_date]
# Insert at front
dates.insert(0, new_date)

with open(dates_file, 'w') as f:
    json.dump(dates, f, indent=2)
    f.write('\n')
"
fi
echo "✅ dates.json updated"

# ── 5. Git commit & push ──
cd "$ROOT"
/usr/bin/git add "daily/${DATE}/" dates.json
/usr/bin/git add reports/ 2>/dev/null || true

# Only commit if there are changes
if /usr/bin/git diff --cached --quiet 2>/dev/null; then
  echo "ℹ️  No new changes to commit"
else
  /usr/bin/git commit -m "📰 daily brief: add ${DATE} report"
  /usr/bin/git push origin main
  echo "✅ Pushed to GitHub Pages"
fi

echo "🎉 Deployment complete: ${DATE}"
