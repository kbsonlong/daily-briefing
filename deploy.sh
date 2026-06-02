#!/usr/bin/env bash
# ═══════════════════════════════════════════════
# deploy.sh — Deploy a daily report to GitHub Pages
# Usage: ./deploy.sh YYYY-MM-DD [path/to/report.md]
#   or:  cat report.md | ./deploy.sh YYYY-MM-DD -
# ═══════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE="${1:?Usage: deploy.sh YYYY-MM-DD [report.md]}"
SRC="${2:--}"

# Validate date format
if ! [[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid date format: $DATE (expected YYYY-MM-DD)" >&2
  exit 1
fi

DAILY_DIR="$REPO_DIR/daily/$DATE"

# ── 1. Create date directory & copy template ──
mkdir -p "$DAILY_DIR"
cp "$REPO_DIR/template.html" "$DAILY_DIR/index.html"

# ── 2. Copy or pipe report markdown ──
if [ "$SRC" = "-" ]; then
  cat > "$DAILY_DIR/report.md"
else
  cp "$SRC" "$DAILY_DIR/report.md"
fi

# ── 3. Update dates.json (newest first) ──
cd "$REPO_DIR"
DATES_JSON="$REPO_DIR/dates.json"

if [ -f "$DATES_JSON" ] && python3 -c "import json; json.load(open('$DATES_JSON'))" 2>/dev/null; then
  # Insert date, dedupe, sort desc, keep newest first
  python3 -c "
import json
with open('$DATES_JSON') as f:
    dates = json.load(f)
if '$DATE' not in dates:
    dates.insert(0, '$DATE')
else:
    # move to front
    dates.remove('$DATE')
    dates.insert(0, '$DATE')
dates.sort(reverse=True)
with open('$DATES_JSON', 'w') as f:
    json.dump(dates, f, indent=2)
"
else
  echo '["'"$DATE"'"]' > "$DATES_JSON"
fi

# ── 4. Git commit & push ──
git add -A
git diff --cached --quiet && {
  echo "No changes to commit for $DATE"
  exit 0
}
git commit -m "📝 daily briefing: $DATE"
git push

echo "✅ Deployed: $DATE"
