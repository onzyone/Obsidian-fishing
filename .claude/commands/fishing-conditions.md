Check live weather and river conditions, then recommend the best day and river for a fishing trip near Toronto.

@/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-location-standards.md

## Arguments

`$ARGUMENTS` can be:
- Empty — ask user which dates and area to compare
- Dates and/or area — e.g. `this Saturday West` or `Monday Thursday East`

## Steps

1. Parse `$ARGUMENTS` for dates and/or area (West · East · North · Southwest · All).
   Update `fishing-request.md`:
   File: `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions/fishing-request.md`

   - If dates were provided, set the **Dates** field. Otherwise ask the user which dates to compare.
   - If an area was provided, set the **Area** field. Otherwise ask the user which area:
     - **West** — Credit River, Bronte Creek, 16 Mile Creek, Etobicoke Creek, Grand River (~1h)
     - **East** — Don River, Rouge River, Duffins Creek, Oshawa Creek, Wilmot Creek, Bowmanville Creek, Ganaraska River
     - **North** — Humber River, Nottawasaga River, Beaver River, Saugeen River, Mad River
     - **Southwest** — Twenty Mile Creek, Niagara River, Big Creek, Lynn River, Big Otter Creek
     - **All** — all year-round lower sections within ~1h

   Ask both questions together in one message if neither was provided.

2. **Check Ollama is running** before launching any agents:
   ```bash
   if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
       echo "Ollama not running — starting it..."
       ollama serve >>/tmp/ollama.log 2>&1 &
       sleep 4
       if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
           echo "ERROR: Ollama failed to start. Check /tmp/ollama.log"
           exit 1
       fi
       echo "Ollama started."
   fi
   ```
   If Ollama fails to start, tell the user and stop.

3. Run Phase 1 — launch all 3 agents in parallel splits via cmux:
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

4. Tell the user: "All 3 agents are running. Wait for **WEATHER AGENT DONE**, **WATER AGENT DONE**,
   and **FISH AGENT DONE** to appear, then say **done** and I'll give your recommendation."

5. When the user says "done", read:
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/weather-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/water-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/fish-output.md`

   Then follow the instructions in:
   `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions/conditions-lead.md`

   The Lead will archive the previous run to `go fishing here history/` and write
   the new recommendation to `Go Fishing Here.md` automatically.

6. After delivering the recommendation, close the splits:
   ```bash
   cmux close-surface --surface $WEATHER
   cmux close-surface --surface $WATER
   cmux close-surface --surface $FISH
   ```

## Fallback (no cmux)

If `CMUX_WORKSPACE_ID` is not set, skip the cmux steps and instead run both agents
in parallel using the Agent tool, then synthesize using the Conditions Lead instructions.
