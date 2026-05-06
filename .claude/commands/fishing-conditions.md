Check live weather and river conditions, then recommend the best day and river for a fishing trip near Toronto.

@/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-location-standards.md

## Arguments

`$ARGUMENTS` can be:
- Empty — ask user which dates and area to compare
- Dates and/or area — e.g. `this Saturday West` or `Monday Thursday East`
- `new` — anywhere in args. Triggers "New Spots Explore" mode: Lead spawns a
  Claude sub-agent (Agent tool, general-purpose) to generate 3–4 unfished /
  under-fished locations per area, clustered within ~30min drive of each other.
  Combine with dates/area, e.g. `Saturday East new` or `new May 1 2 3 All`.
- `wait` — anywhere in args. Disables autopilot. Lead pauses after launching
  agents and waits for the user to type "done" before synthesising. Default
  behaviour is **autopilot on**: Lead polls the tmp dir until all 3 outputs
  settle, then auto-advances to step 5 with no user prompt.

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

2. (Step removed — agents are now deterministic bash, no LLM dependency.
   `preflight-ollama.sh` is still allowlisted in case future steps need it.)

3. **Per-zone loop for Area=All.** If the request's Area is `All`, do not run a single
   combined cycle — instead loop the run-and-synthesise flow once per zone
   (East → West → North → Southwest). For each iteration:
   a. Set `fishing-request.md` `**Area:**` field to the current zone (Title-Case single word).
   b. Run the 3 agents in parallel splits as described below.
   c. Run the **autopilot wait** poll from step 4 (or, if `wait` token is set,
      pause for the user to type "done").
   d. If `Mode: new` is set, Lead spawns a Claude sub-agent (Agent tool,
      general-purpose) to generate the new-spots cluster — see step 5b.
   e. Have the Lead synthesise that zone's output files (`Go Fishing Here/<Zone>/<Zone>.md`
      and, when Mode=new, `Go Fishing Here/<Zone>/<Zone>_New.md`).
   f. Move to the next zone.

   After all 4 zones complete, also write `Go Fishing Here/Overall.md` — a summary
   comparing the 4 zones (best day per zone, top river per zone, conditions snapshot)
   so the user can pick which zone to actually drive to. See the "Overall summary"
   section in `conditions-lead.md` for the format.

   For single-zone requests (`East` / `West` / `North` / `Southwest`), skip the loop
   and just run the cycle once for that zone.

3a. Run a single agent cycle (used both for single-zone runs and inside the per-zone
   loop) — clear stale outputs, then launch the 3 deterministic agents in parallel
   splits via cmux:
   ```bash
   bash /Users/onzyone/projects/onzyone/claude/fishing/launch-fishing-agents.sh
   ```
   The launcher wipes the tmp dir, opens 3 cmux splits (Weather / Water / Fish),
   starts each agent, and writes the surface IDs to `/tmp/fishing-surfaces.env`
   for the cleanup step. Each agent finishes in seconds — no Ollama, no model
   pre-warm, no per-station latency stacking.

4. **Autopilot wait** (default — skipped only if `wait` token in args).
   Tell the user: "3 agents launched. Autopilot polling tmp dir; should settle
   in ~10–30s."

   Then poll until every output file exists, is non-empty, and has not been
   modified for ≥3 seconds. Cap at 90s.
   ```bash
   bash /Users/onzyone/projects/onzyone/claude/fishing/autopilot-poll.sh
   ```

   If `wait` token is present in args, skip the poll entirely and instead say:
   "3 agents are running. Wait for **WEATHER AGENT DONE**, **WATER AGENT DONE**,
   **FISH AGENT DONE** to appear, then say **done** and I'll give your
   recommendation."

5. Once autopilot poll returns (or user says "done" in `wait` mode), read:
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/weather-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/water-output.md`
   - `/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp/fish-output.md`

   Then follow the instructions in:
   `$HOME/projects/onzyone/claude/fishing/conditions-lead.md`

   The Lead will archive the previous run to `go fishing here history/` and write
   the new recommendation to `Go Fishing Here/<Zone>/<Zone>.md` automatically.

5b. **New Spots sub-agent (only when `Mode: new` is set).**
   Spawn a Claude sub-agent (Agent tool) to generate the per-zone new-spots
   cluster. This replaces the old phi4-mini new-locations script — Claude has
   the vault + memory + MNR atlas access and never times out.

   Use `subagent_type: "general-purpose"` with a self-contained prompt:
   - The Area + Dates from `fishing-request.md`.
   - Pointer to `Rivers/<Direction>/*.md` access-points + MNR brook trout
     subsections to draw from.
   - Pointer to `fishing location skill/Gauge Index.md` for sub-gauges that
     don't match the year-round roster.
   - Constraints: not on the year-round roster; clustered within ~30min;
     realistically fishable for the requested dates; FMZ-season aware.
   - Output: 3–4 rows in the table format from `conditions-lead.md` (Spot |
     Drive | Species | Why | Map). Plus the standard Notes block (FMZ regs,
     property lines, tackle swap).

   Run this sub-agent in parallel with the main synthesis if possible (foreground
   if you need its output before writing the file). Paste its tables into the
   "New Spots Explore" section of `<Zone>.md` and into `<Zone>_New.md`.

6. After delivering the recommendation, close the splits and wipe the tmp dir:
   ```bash
   bash /Users/onzyone/projects/onzyone/claude/fishing/cleanup-fishing-run.sh
   ```
   The cleanup script reads `/tmp/fishing-surfaces.env` (written by the launcher),
   closes the 3 splits, and removes the tmp output files.

## Fallback (no cmux)

If `CMUX_WORKSPACE_ID` is not set, skip the cmux steps and instead run all 3
agent scripts in parallel via background `&` then `wait`, e.g.:
```bash
bash run-weather-agent.sh & bash run-water-agent.sh & bash run-fish-agent.sh & wait
```
Then synthesise using the Conditions Lead instructions.
