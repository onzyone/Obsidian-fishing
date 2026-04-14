# Fishing Conditions — Agent Team

## Overview

A 4-agent team for assessing river fishing conditions and recommending the best day and river
for an upcoming trip. Runs in 2 phases:

```
Phase 1 (parallel):  Weather Agent  +  Water Agent  +  Fish Agent
                                       ↓
Phase 2:             Conditions Lead  (reads all three outputs, gives recommendation)
```

---

## The Team

### Agent 1 — Weather Agent (Phase 1)

**Role:** Fetches 14-day forecast from open-meteo.com for Toronto/Etobicoke.

**Responsibilities:**
- Fetch daily max/min temp, precipitation, and weather code
- Flag rain events >5mm (rivers blow out 1–3 days after)
- Identify clean fishing windows (dry + mild + rivers likely falling)
- Save to `fishing-conditions-tmp/weather-output.md`

**Prompt file:** `weather-agent.md`
**Launcher:** `run-weather-agent.sh`

---

### Agent 2 — Water Agent (Phase 1)

**Role:** Fetches current gauge data for key rivers from Water Survey of Canada.

**Responsibilities:**
- Fetch last 6 days of water level (stage) data for Credit River + Humber River
- Assess current level, trend (rising/falling/stable), and fishability
- Save to `fishing-conditions-tmp/water-output.md`

**Key stations:**
- `02HB029` — Credit River at Streetsville
- `02HC003` — Humber River at Weston

**Prompt file:** `water-agent.md`
**Launcher:** `run-water-agent.sh`

---

### Agent 3 — Fish Agent (Phase 1)

**Role:** Fetches fish stocking data and run timing for Ontario rivers.

**Responsibilities:**
- Fetch annual stocking numbers from Ontario Open Data (ontario.ca/dataset/fish-stocking)
- Fetch current run timing status from ontariotroutandsteelhead.com
- Check Ganaraska fish ladder counts if available (grca.on.ca)
- Save to `fishing-conditions-tmp/fish-output.md`

**Prompt file:** `fish-agent.md`
**Launcher:** `run-fish-agent.sh`

---

### Conditions Lead (Phase 2 — main session)

**Role:** Synthesizes weather + water data with season rules and delivers a recommendation.

**Responsibilities:**
- Read both tmp outputs + fishing-request.md
- Cross-reference which rivers are in season (FMZ open dates)
- Score each requested date: Good / Fair / Poor
- Recommend best day + river + access point
- Delete tmp files when done

**Prompt file:** `conditions-lead.md`

---

## How to Run the Team

### Step 0 — Fill in the request

Edit `fishing-request.md`:
- Set the dates you want to compare
- Set max drive time and any preferences

---

### Phase 1 — Weather Agent + Water Agent in parallel

Layout:
```
┌──────────────────┬────────────────────┐
│                  │   Weather Agent    │
│      Main        ├────────────────────┤
│  (Lead)          │   Water Agent      │
│                  ├────────────────────┤
│                  │   Fish Agent       │
└──────────────────┴────────────────────┘
```

```bash
FC_DIR="/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions"
WEATHER=$(cmux new-split right | awk '{print $2}')
WATER=$(cmux new-split down --surface "$WEATHER" | awk '{print $2}')
FISH=$(cmux new-split down --surface "$WATER" | awk '{print $2}')
cmux rename-tab --surface "$WEATHER" "Weather Agent"
cmux rename-tab --surface "$WATER" "Water Agent"
cmux rename-tab --surface "$FISH" "Fish Agent"
cmux send --surface "$WEATHER" "bash '$FC_DIR/run-weather-agent.sh'"
cmux send-key --surface "$WEATHER" Enter
cmux send --surface "$WATER" "bash '$FC_DIR/run-water-agent.sh'"
cmux send-key --surface "$WATER" Enter
cmux send --surface "$FISH" "bash '$FC_DIR/run-fish-agent.sh'"
cmux send-key --surface "$FISH" Enter
echo "WEATHER=$WEATHER WATER=$WATER FISH=$FISH"
```

Wait for all three splits to print `WEATHER AGENT DONE`, `WATER AGENT DONE`, and `FISH AGENT DONE`.

---

### Phase 2 — Run the Conditions Lead in the main session

When both agents are done, prompt Claude in the main session:

```
Run the Conditions Lead for the fishing conditions team.
Prompt file: Hobbies/20 Fishing/fishing location skill/fishing-conditions/conditions-lead.md
Both agents are done — read their outputs and give the recommendation.
```

---

### Cleanup — Close the splits

After the Lead delivers the recommendation:
```bash
cmux close-surface --surface $WEATHER
cmux close-surface --surface $WATER
```

---

## File Structure

```
fishing location skill/
  fishing-conditions/
    agent-team.md             -- This file
    fishing-request.md        -- Fill in before each run
    weather-agent.md          -- Agent 1 prompt (Phase 1)
    water-agent.md            -- Agent 2 prompt (Phase 1)
    fish-agent.md             -- Agent 3 prompt (Phase 1)
    conditions-lead.md        -- Lead prompt (Phase 2)
    run-weather-agent.sh      -- Phase 1 launcher
    run-water-agent.sh        -- Phase 1 launcher
    run-fish-agent.sh         -- Phase 1 launcher
  fishing-conditions-tmp/
    weather-output.md         -- Phase 1 output (deleted after Lead runs)
    water-output.md           -- Phase 1 output (deleted after Lead runs)
    fish-output.md            -- Phase 1 output (deleted after Lead runs)
```

---

## Expected Output

The Conditions Lead produces a recommendation covering:

1. Weather summary across the requested window
2. Per-date comparison table (temp, rain, river state, verdict)
3. Best day pick with top river, backup river, access point, drive time
4. What to expect (species, tactics, cautions)

---

## Key Data Sources

| Source | URL | Notes |
|--------|-----|-------|
| Weather forecast | `https://api.open-meteo.com/v1/forecast?latitude=43.7&longitude=-79.5&...` | 14-day daily forecast, free, no key |
| WSC gauge data | `https://wateroffice.ec.gc.ca/services/real_time_data/csv/inline?...` | Real-time CSV, parameter 47 = stage |
| FMZ 16 regs | `https://www.ontario.ca/document/ontario-fishing-regulations-summary` | 4th Saturday April season start |
| Fish stocking | `https://data.ontario.ca/dataset/fish-stocking` | Ontario Open Data — annual stocking by waterbody |
| Run timing | `https://ontariotroutandsteelhead.com` | Current season status by river |
| Ganaraska counts | `https://www.grca.on.ca` | Fish ladder counts when published |
