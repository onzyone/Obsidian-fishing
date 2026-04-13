#!/usr/bin/env bash
set -euo pipefail

VAULT="/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing"
FC_DIR="$VAULT/52 Fishing Locations/fishing-conditions"
TMP_DIR="$VAULT/52 Fishing Locations/fishing-conditions-tmp"
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
MODEL="gemma4:latest"
PROMPT_FILE="$TMP_DIR/water-prompt.txt"

mkdir -p "$TMP_DIR"

TODAY=$(date +%Y-%m-%d)
SIX_DAYS_AGO=$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d "6 days ago" +%Y-%m-%d)
REQUEST=$(cat "$FC_DIR/fishing-request.md")

echo "Fetching Credit River gauge data (02HB029)..."
CREDIT_CSV=$(curl -s \
  "https://wateroffice.ec.gc.ca/services/real_time_data/csv/inline?stations[]=02HB029&parameters[]=47&start_date=${SIX_DAYS_AGO}+00:00:00&end_date=${TODAY}+23:59:59")

echo "Fetching Humber River gauge data (02HC003)..."
HUMBER_CSV=$(curl -s \
  "https://wateroffice.ec.gc.ca/services/real_time_data/csv/inline?stations[]=02HC003&parameters[]=47&start_date=${SIX_DAYS_AGO}+00:00:00&end_date=${TODAY}+23:59:59")

echo "Fetching Credit River turbidity (02HB029, param 99)..."
CREDIT_TURB=$(curl -s \
  "https://wateroffice.ec.gc.ca/services/real_time_data/csv/inline?stations[]=02HB029&parameters[]=99&start_date=${SIX_DAYS_AGO}+00:00:00&end_date=${TODAY}+23:59:59")

echo "Fetching Humber River turbidity (02HC003, param 99)..."
HUMBER_TURB=$(curl -s \
  "https://wateroffice.ec.gc.ca/services/real_time_data/csv/inline?stations[]=02HC003&parameters[]=99&start_date=${SIX_DAYS_AGO}+00:00:00&end_date=${TODAY}+23:59:59")

# Pre-process CSV: extract trend and daily change (values are datum-relative, so only deltas matter)
summarize_csv() {
    local label="$1"
    local csv="$2"
    python3 -c "
import csv, io, sys
from datetime import datetime, timedelta
from collections import defaultdict

raw = '''${csv}'''
data = []
reader = csv.DictReader(io.StringIO(raw))
for row in reader:
    try:
        val = float(list(row.values())[3])  # Value/Valeur column
        ts_str = list(row.values())[1]       # Date column
        ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        data.append((ts, val))
    except (ValueError, IndexError):
        continue

if not data:
    print('No data parsed')
    sys.exit()

data.sort()
recent = data[-1][1]
cutoff_24h = data[-1][0] - timedelta(hours=24)
cutoff_48h = data[-1][0] - timedelta(hours=48)
last24 = [v for ts, v in data if ts >= cutoff_24h]
prev24 = [v for ts, v in data if cutoff_48h <= ts < cutoff_24h]

avg_recent = sum(last24)/len(last24) if last24 else recent
avg_prev = sum(prev24)/len(prev24) if prev24 else avg_recent
delta = avg_recent - avg_prev

if delta > 0.05:
    trend = 'Rising'
elif delta < -0.05:
    trend = 'Falling'
else:
    trend = 'Stable'

# Daily relative change from first reading of each day
daily = defaultdict(list)
for ts, v in data:
    daily[ts.date()].append(v)

baseline = list(daily.values())[0][0]
print(f'Trend (24h avg vs prev 24h): {trend} ({delta:+.2f}m change)')
print(f'Most recent reading: {recent:.2f}m above datum')
print()
print('Daily avg level (relative to first reading = 0.00m):')
for d in sorted(daily.keys()):
    avg = sum(daily[d])/len(daily[d])
    rel = avg - baseline
    print(f'  {d}: {rel:+.2f}m  (avg {avg:.2f}m datum)')
"
}

# Parse turbidity CSV (WSC parameter 99 = Turbidity in FNU/NTU).
# Falls back to level-change inference if no sensor data is available.
summarize_turbidity() {
    local label="$1"
    local turb_csv="$2"
    local level_summary="$3"
    python3 -c "
import csv, io, sys

raw_turb = '''${turb_csv}'''
data = []
reader = csv.DictReader(io.StringIO(raw_turb))
for row in reader:
    try:
        vals = list(row.values())
        val = float(vals[3])
        ts_str = vals[1]
        data.append((ts_str, val))
    except (ValueError, IndexError):
        continue

if data:
    data.sort()
    recent = data[-1][1]
    ts_latest = data[-1][0]
    if recent < 5:
        label = 'Clear (<5 NTU)'
    elif recent < 20:
        label = 'Slightly coloured (5-20 NTU)'
    elif recent < 50:
        label = 'Murky (20-50 NTU)'
    else:
        label = 'Very murky / blown out (>50 NTU)'
    print(f'Turbidity (sensor): {recent:.1f} NTU — {label}  [as of {ts_latest}]')
else:
    # No sensor: infer from level summary text
    summary = '''${level_summary}'''
    delta = None
    for line in summary.splitlines():
        if 'change' in line.lower() and 'm change' in line.lower():
            try:
                part = [t for t in line.split() if t.startswith('+') or (t.startswith('-') and 'm' in t)]
                if part:
                    delta = float(part[0].replace('m',''))
            except ValueError:
                pass
    if delta is not None:
        if delta > 0.20:
            clarity = 'Likely murky (fast rise >+0.20m/24h)'
        elif delta > 0.05:
            clarity = 'Possibly coloured (moderate rise)'
        elif delta < -0.05:
            clarity = 'Clearing (falling trend — check days since peak)'
        else:
            clarity = 'Likely clear (stable level)'
    else:
        if 'Rising' in summary:
            clarity = 'Possibly coloured (rising)'
        elif 'Falling' in summary:
            clarity = 'Clearing (falling trend)'
        else:
            clarity = 'Likely clear (stable)'
    print(f'Turbidity (inferred — no sensor): {clarity}')
"
}

echo "Summarising gauge data..."
CREDIT_SUMMARY=$(summarize_csv "Credit" "$CREDIT_CSV")
HUMBER_SUMMARY=$(summarize_csv "Humber" "$HUMBER_CSV")

echo "Summarising turbidity..."
CREDIT_CLARITY=$(summarize_turbidity "Credit" "$CREDIT_TURB" "$CREDIT_SUMMARY")
HUMBER_CLARITY=$(summarize_turbidity "Humber" "$HUMBER_TURB" "$HUMBER_SUMMARY")

cat > "$PROMPT_FILE" <<EOF
Today is ${TODAY}. Data covers ${SIX_DAYS_AGO} to ${TODAY}.

Fishing request:
${REQUEST}

Credit River at Streetsville (02HB029) — water level summary:
${CREDIT_SUMMARY}

Credit River — water clarity:
${CREDIT_CLARITY}

Humber River at Weston (02HC003) — water level summary:
${HUMBER_SUMMARY}

Humber River — water clarity:
${HUMBER_CLARITY}

Fishability guide (trend-based — absolute levels are datum-relative, only changes matter):
- Falling trend, especially after a recent peak = Fishable or improving
- Rising trend = High/murky, wait for drop
- Stable at low relative level = Fishable (fish holding)
- Stable at high relative level = May be murky but fishable edges
- Large positive delta (>+0.3m in 24h) = Blown out, unfishable

Clarity guide:
- Clear (<5 NTU) or inferred clear = Ideal — fish can see flies/jigs easily
- Slightly coloured (5-20 NTU) = Good — slight tea colour, still very fishable
- Murky (20-50 NTU) = Poor — fish react less, switch to bright/scented baits
- Very murky (>50 NTU) or blown out = Skip this river today
- If turbidity is inferred (no sensor), note this caveat in the Clarity line

Format this into EXACTLY this markdown structure (no extra commentary):

# Water Levels Output

**Fetched:** ${TODAY}

## Gauge Readings (last 6 days)

### Credit River at Streetsville (02HB029)
- Recent level: X.Xm
- Trend: Rising / Falling / Stable
- Min (6d): X.Xm | Max (6d): X.Xm
- Clarity: [Clear / Slightly coloured / Murky / Very murky — include NTU if sensor available, or note "inferred"]
- Condition: [Fishable / High/murky - wait for drop / Very low / Skip — poor clarity]

### Humber River at Weston (02HC003)
- Recent level: X.Xm
- Trend: Rising / Falling / Stable
- Min (6d): X.Xm | Max (6d): X.Xm
- Clarity: [Clear / Slightly coloured / Murky / Very murky — include NTU if sensor available, or note "inferred"]
- Condition: [Fishable / High/murky - wait for drop / Very low / Skip — poor clarity]

## Overall Assessment

[1-2 sentences: are rivers currently in good shape, blown out, or recovering? Note clarity conditions.]
EOF

echo "Asking Ollama to format water levels..."
python3 -c "
import json, urllib.request

with open('$PROMPT_FILE') as f:
    prompt = f.read()

payload = json.dumps({
    'model': '$MODEL',
    'stream': False,
    'options': {'think': False},
    'messages': [{'role': 'user', 'content': prompt}]
}).encode()

req = urllib.request.Request(
    '$OLLAMA_URL',
    data=payload,
    headers={'Content-Type': 'application/json'}
)
with urllib.request.urlopen(req, timeout=300) as resp:
    data = json.load(resp)
    print(data['choices'][0]['message']['content'])
" > "$TMP_DIR/water-output.md"

rm -f "$PROMPT_FILE"
echo "WATER AGENT DONE"
