#!/usr/bin/env bash
set -euo pipefail

VAULT="/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing"
FC_DIR="$VAULT/52 Fishing Locations/fishing-conditions"
TMP_DIR="$VAULT/52 Fishing Locations/fishing-conditions-tmp"
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
MODEL="gemma4:latest"
PROMPT_FILE="$TMP_DIR/weather-prompt.txt"

mkdir -p "$TMP_DIR"

TODAY=$(date +%Y-%m-%d)
REQUEST=$(cat "$FC_DIR/fishing-request.md")

echo "Fetching weather data..."
WEATHER_JSON=$(curl -s \
  "https://api.open-meteo.com/v1/forecast?latitude=43.7&longitude=-79.5&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode&timezone=America%2FToronto&forecast_days=14")

cat > "$PROMPT_FILE" <<EOF
Today is ${TODAY}.

Fishing request:
${REQUEST}

Raw 14-day weather JSON for Toronto/Etobicoke:
${WEATHER_JSON}

Weather code key: 0=clear, 1-3=mostly clear, 45/48=fog, 51-55=drizzle, 61-67=rain, 71-77=snow, 80-82=showers, 95=thunderstorm.

Format this data into EXACTLY this markdown structure (no extra commentary):

# Weather Output

**Fetched:** ${TODAY}

## 14-Day Forecast (Toronto / Etobicoke)

| Date | Day | High | Low | Precip | Conditions |
|------|-----|------|-----|--------|------------|
[one row per day from the JSON]

## Key Events

- [List any days with >5mm precip as "RAIN EVENT - rivers may blow out"]
- [Note any multi-day rain sequences]
- [Note any good windows: dry + mild + rivers likely falling]

## Requested Dates Summary

[For each date in the fishing request above, give a one-line weather summary]
EOF

echo "Asking Ollama to format weather data..."
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
with urllib.request.urlopen(req, timeout=600) as resp:
    data = json.load(resp)
    print(data['choices'][0]['message']['content'])
" > "$TMP_DIR/weather-output.md"

rm -f "$PROMPT_FILE"
echo "WEATHER AGENT DONE"
