
   if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
       echo "Ollama not running — starting it..."
       ollama serve >>/tmp/ollama.log 2>&1 &
       sleep 4
       if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
           echo "ERROR: Ollama failed to start. Check /tmp/ollama.log"
           exit 1
       fi
       echo "Ollama started."
   else
       echo "Ollama already running."
   fi
   curl -s http://localhost:11434/api/generate \
     -d '{"model":"phi4-mini:latest","prompt":"ok","stream":false,"keep_alive":"15m"}' \
     > /dev/null &
   echo "Pre-warm dispatched."
   Ollama check + pre-warm

 Unhandled node type: &

 Do you want to proceed?
 ❯ 1. Yes
   2. No
      
      


   SKILL_DIR="$HOME/projects/onzyone/claude/fishing"                                                                                                                                                                                               TMP_DIR="/Users/onzyone/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/fishing location skill/fishing-conditions-tmp"                                                                                                            rm -f "$TMP_DIR/weather-output.md" "$TMP_DIR/water-output.md" "$TMP_DIR/fish-output.md" "$TMP_DIR/new-locations-output.md"
   WEATHER=$(cmux new-split right | cut -d' ' -f2)                                                                                                                                                                                                 WATER=$(cmux new-split down --surface "$WEATHER" | cut -d' ' -f2)
   FISH=$(cmux new-split down --surface "$WATER" | cut -d' ' -f2)                                                                                                                                                                                  NEW=$(cmux new-split down --surface "$FISH" | cut -d' ' -f2)
   cmux rename-tab --surface "$WEATHER" "Weather Agent"                                                                                                                                                                                            cmux rename-tab --surface "$WATER" "Water Agent"
   cmux rename-tab --surface "$FISH" "Fish Agent"                                                                                                                                                                                                  cmux rename-tab --surface "$NEW" "New Locations Agent"
   cmux send --surface "$WEATHER" "bash '$SKILL_DIR/run-weather-agent.sh'"                                                                                                                                                                         cmux send-key --surface "$WEATHER" Enter
   cmux send --surface "$WATER" "bash '$SKILL_DIR/run-water-agent.sh'"                                                                                                                                                                             cmux send-key --surface "$WATER" Enter
   cmux send --surface "$FISH" "bash '$SKILL_DIR/run-fish-agent.sh'"                                                                                                                                                                               cmux send-key --surface "$FISH" Enter
   cmux send --surface "$NEW" "bash '$SKILL_DIR/run-new-locations-agent.sh'"                                                                                                                                                                       cmux send-key --surface "$NEW" Enter
   echo "WEATHER=$WEATHER WATER=$WATER FISH=$FISH NEW=$NEW"                                                                                                                                                                                        Launch 4 agents in cmux splits

 Tilde in assignment value — bash may expand at assignment time

 Do you want to proceed?
 ❯ 1. Yes
   2. No

   skill/fishing-conditions-tmp"
   FILES=(weather-output.md water-output.md fish-output.md new-locations-output.md)
   START=$(date +%s)
   TIMEOUT=600
   while :; do
       READY=1
       NOW=$(date +%s)
       for f in "${FILES[@]}"; do
           p="$TMP_DIR/$f"
           if [ ! -s "$p" ]; then READY=0; MISSING="$f not yet"; break; fi
           AGE=$(( NOW - $(stat -f %m "$p") ))
           if [ "$AGE" -lt 3 ]; then READY=0; MISSING="$f still writing (age ${AGE}s)"; break; fi
       done
       [ "$READY" = "1" ] && { echo "All 4 outputs settled at $(date +%H:%M:%S)."; break; }
       if [ $((NOW - START)) -gt $TIMEOUT ]; then
           echo "TIMEOUT after ${TIMEOUT}s — proceeding with whatever exists."
           break
       fi
       ELAPSED=$((NOW - START))
       echo "[${ELAPSED}s] waiting: $MISSING"
       sleep 15
   done
   Autopilot poll for 4 outputs

 Contains brace with quote character (expansion obfuscation)

 Do you want to proceed?
 ❯ 1. Yes
   2. No