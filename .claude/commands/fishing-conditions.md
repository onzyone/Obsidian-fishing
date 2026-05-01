Check live weather and river conditions, then recommend the best day and river for a fishing trip near Toronto.

@/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-location-standards.md

## Arguments

`$ARGUMENTS` can be:
- Empty — ask user which dates and area to compare
- Dates and/or area — e.g. `this Saturday West` or `Monday Thursday East`
- `new` — anywhere in args. Triggers "New Spots Explore" mode: the Lead adds a
  bonus chart showing 3–4 unfished/under-fished locations per area, clustered
  within ~30min drive of each other. Combine with dates/area, e.g.
  `Saturday East new` or `new May 1 2 3 All`.

## Steps

1. Parse `$ARGUMENTS` for dates, area (West · East · North · Southwest · All), and
   the optional `new` token. Update `fishing-request.md`:
   File: `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions/fishing-request.md`

   - If dates were provided, set the **Dates** field. Otherwise ask the user which dates to compare.
   - If an area was provided, set the **Area** field. Otherwise ask the user which area:
     - **West** — Credit River, Bronte Creek, 16 Mile Creek, Etobicoke Creek, Grand River (~1h)
     - **East** — Don River, Rouge River, Duffins Creek, Oshawa Creek, Wilmot Creek, Bowmanville Creek, Ganaraska River
     - **North** — Humber River, Nottawasaga River, Beaver River, Saugeen River, Mad River
     - **Southwest** — Twenty Mile Creek, Niagara River, Big Creek, Lynn River, Big Otter Creek
     - **All** — all year-round lower sections within ~1h
   - If `new` was in the args, set **Mode:** `new`. Otherwise leave it blank.

   Ask both questions together in one message if dates/area weren't provided. Do
   not ask about `new` — it is opt-in only when the user types it.

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

3. **Per-zone loop for Area=All.** If the request's Area is `All`, do not run a single
   combined cycle — instead loop the entire run-and-synthesize flow once per zone
   (East → West → North → Southwest). For each iteration:
   a. Set `fishing-request.md` `**Area:**` field to the current zone (Title-Case single word).
   b. Run the 4 agents in parallel splits as described below; wait for all 4 `AGENT DONE` lines.
   c. Have the Lead synthesise that zone's output files (`Go Fishing Here/<Zone>/<Zone>.md`
      and, when Mode=new, `Go Fishing Here/<Zone>/new.md`).
   d. Move to the next zone.

   After all 4 zones complete, also write `Go Fishing Here/Overall.md` — a summary
   comparing the 4 zones (best day per zone, top river per zone, conditions snapshot)
   so the user can pick which zone to actually drive to. See the "Overall summary"
   section in `conditions-lead.md` for the format.

   For single-zone requests (`East` / `West` / `North` / `Southwest`), skip the loop
   and just run the cycle once for that zone.

3a. Run a single agent cycle (used both for single-zone runs and inside the per-zone
   loop) — launch all 4 agents in parallel splits via cmux:
   ```bash
   SKILL_DIR="$HOME/projects/onzyone/claude/fishing"
   WEATHER=$(cmux new-split right | cut -d' ' -f2)
   WATER=$(cmux new-split down --surface "$WEATHER" | cut -d' ' -f2)
   FISH=$(cmux new-split down --surface "$WATER" | cut -d' ' -f2)
   NEW=$(cmux new-split down --surface "$FISH" | cut -d' ' -f2)
   cmux rename-tab --surface "$WEATHER" "Weather Agent"
   cmux rename-tab --surface "$WATER" "Water Agent"
   cmux rename-tab --surface "$FISH" "Fish Agent"
   cmux rename-tab --surface "$NEW" "New Locations Agent"
   cmux send --surface "$WEATHER" "bash '$SKILL_DIR/run-weather-agent.sh'"
   cmux send-key --surface "$WEATHER" Enter
   cmux send --surface "$WATER" "bash '$SKILL_DIR/run-water-agent.sh'"
   cmux send-key --surface "$WATER" Enter
   cmux send --surface "$FISH" "bash '$SKILL_DIR/run-fish-agent.sh'"
   cmux send-key --surface "$FISH" Enter
   cmux send --surface "$NEW" "bash '$SKILL_DIR/run-new-locations-agent.sh'"
   cmux send-key --surface "$NEW" Enter
   echo "WEATHER=$WEATHER WATER=$WATER FISH=$FISH NEW=$NEW"
   ```
   The New Locations agent only does real work when **Mode: new** is set in
   `fishing-request.md` — otherwise it writes a stub output file and exits fast.

4. Tell the user: "All 4 agents are running. Wait for **WEATHER AGENT DONE**, **WATER AGENT DONE**,
   **FISH AGENT DONE**, and **NEW LOCATIONS AGENT DONE** to appear, then say **done** and I'll give your recommendation."

5. When the user says "done", read:
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/weather-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/water-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/fish-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/new-locations-output.md`

   Then follow the instructions in:
   `$HOME/projects/onzyone/claude/fishing/conditions-lead.md`

   The Lead will archive the previous run to `go fishing here history/` and write
   the new recommendation to `Go Fishing Here.md` automatically.

6. After delivering the recommendation, close the splits:
   ```bash
   cmux close-surface --surface $WEATHER
   cmux close-surface --surface $WATER
   cmux close-surface --surface $FISH
   cmux close-surface --surface $NEW
   ```

## Fallback (no cmux)

If `CMUX_WORKSPACE_ID` is not set, skip the cmux steps and instead run both agents
in parallel using the Agent tool, then synthesize using the Conditions Lead instructions.
