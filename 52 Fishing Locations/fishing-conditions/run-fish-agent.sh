#!/usr/bin/env bash
set -euo pipefail

VAULT="/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing"
FC_DIR="$VAULT/52 Fishing Locations/fishing-conditions"
TMP_DIR="$VAULT/52 Fishing Locations/fishing-conditions-tmp"
OLLAMA_URL="http://localhost:11434/v1/chat/completions"
MODEL="qwen3:14b"
PROMPT_FILE="$TMP_DIR/fish-prompt.txt"

mkdir -p "$TMP_DIR"

TODAY=$(date +%Y-%m-%d)
REQUEST=$(cat "$FC_DIR/fishing-request.md")

# Fetch and strip HTML to readable text
fetch_text() {
    local url="$1"
    local label="$2"
    echo "Fetching ${label}..." >&2
    curl -sL --max-time 20 "$url" 2>/dev/null | python3 -c "
import sys
from html.parser import HTMLParser

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []
        self.skip = False
        self.skip_tags = {'script', 'style', 'nav', 'header', 'footer', 'noscript'}
    def handle_starttag(self, tag, attrs):
        if tag in self.skip_tags:
            self.skip = True
    def handle_endtag(self, tag):
        if tag in self.skip_tags:
            self.skip = False
    def handle_data(self, data):
        if not self.skip:
            stripped = data.strip()
            if stripped:
                self.text.append(stripped)
    def get_text(self):
        return '\n'.join(self.text)[:6000]

parser = TextExtractor()
parser.feed(sys.stdin.read())
print(parser.get_text())
" 2>/dev/null || echo "[${label}: fetch failed or timed out]"
}

STOCKING=$(fetch_text "https://data.ontario.ca/dataset/fish-stocking" "Ontario fish stocking page")
RUN_TIMING=$(fetch_text "https://ontariotroutandsteelhead.com" "ontariotroutandsteelhead.com")
GANARASKA=$(fetch_text "https://grca.on.ca/fisheries/corbetts-dam-fishway/" "Ganaraska Corbett's Dam")
CREDIT_FISH=$(fetch_text "https://www.craa.on.ca/live-camera-river-watcher/" "Credit CRAA watcher")
BEAVER=$(fetch_text "https://www.biotactic.com/BRAVO-Node-10/" "Biotactic BRAVO")

cat > "$PROMPT_FILE" <<EOF
Today is ${TODAY}.

Fishing request:
${REQUEST}

--- Ontario Fish Stocking Page ---
${STOCKING}

--- Run Timing (ontariotroutandsteelhead.com) ---
${RUN_TIMING}

--- Ganaraska River / Corbett's Dam Fishway ---
${GANARASKA}

--- Credit River / CRAA Watcher ---
${CREDIT_FISH}

--- Beaver River (Thornbury) / Biotactic BRAVO ---
${BEAVER}

Format this into EXACTLY this markdown structure (no extra commentary):

# Fish Data Output

**Fetched:** ${TODAY}

## Stocking Data (most recent available)

| River | Species | # Stocked | Year | Source |
|-------|---------|-----------|------|--------|
[rows for Credit, Humber, Ganaraska, Nottawasaga, Beaver, Saugeen, Duffins, Rouge, Don]

> Note: Stocked fish supplement wild runs.

## Run Timing - Current Status

**Season status:** [Early / On time / Late / Peak / Winding down]
**Date context:** [Today relative to typical peak weeks]

| River | Run Status | Notes |
|-------|-----------|-------|
[Credit, Humber, Ganaraska, Nottawasaga, Beaver]

## Fish Counter Data

| River | Counter | Count / Status |
|-------|---------|---------------|
| Ganaraska | Riverwatcher / GRCA Corbett's Dam | [from data above] |
| Credit | CRAA River Watcher | [from data above] |
| Beaver (Thornbury) | Biotactic BRAVO | [from data above] |

## Summary

[2-3 sentences on which rivers have the strongest runs right now]

> Small creek caution: Wilmot Creek, Oshawa Creek, Don River, Bowmanville Creek, Etobicoke Creek, Lynn River, and Twenty Mile Creek - treat third-party run estimates as anecdotal only. Confirmed counters: Ganaraska (Riverwatcher), Credit (CRAA), Beaver/Thornbury (Biotactic).

If any data source returned no useful data, note it as: Data unavailable - [reason]
EOF

echo "Asking Ollama to analyse fish data..."
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
" > "$TMP_DIR/fish-output.md"

rm -f "$PROMPT_FILE"
echo "FISH AGENT DONE"
