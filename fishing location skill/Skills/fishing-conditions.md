# fishing-conditions

**Slash command:** `/fishing-conditions [dates] [area]`

A 3-agent team that fetches live weather forecasts, river gauge data, and fish stocking/run-timing
data, then recommends the best day and river for an upcoming fishing trip.

## What it does

- **Weather Agent** — fetches 14-day forecast from open-meteo.com (Toronto/Etobicoke)
- **Water Agent** — fetches current gauge levels for 30+ rivers from Water Survey of Canada
- **Fish Agent** — fetches Ontario stocking data, run timing, and fish counter data
- **Conditions Lead** — synthesizes all three outputs, cross-references FMZ open seasons,
  and delivers a clear recommendation: best day, best river, why

## Arguments

- `$ARGUMENTS` can be:
  - Empty — asks for dates and area interactively
  - Dates and/or area — e.g. `this Saturday West` or `Monday Thursday East`
  - Areas: `West` · `East` · `North` · `Southwest` · `All`

## Agent Team

See: `[[../fishing-conditions/agent-team|Fishing Conditions Agent Team]]`

## Command file

`.claude/commands/fishing-conditions.md` (this vault)

## Notes

- If cmux is not running, fall back to running all 3 agents via the Agent tool in parallel
- Weather Agent uses open-meteo.com — free, no API key needed
- WSC gauge data is provisional real-time (updated ~2h lag); values are datum-relative, only trends matter
- Fish Agent uses Ollama qwen3:14b; Weather + Water use gemma4
- Most FMZ 16/17 rivers open on the 4th Saturday of April — lower river sections near
  Lake Ontario are open year-round
