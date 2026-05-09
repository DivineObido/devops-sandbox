#!/bin/bash

INTERVAL=30
mkdir -p logs

while true; do
  for STATE_FILE in envs/*.json; do
    [ -f "$STATE_FILE" ] || continue

    ENV_ID=$(basename "$STATE_FILE" .json)
    PORT=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['port'])")
    LOG_FILE="logs/${ENV_ID}/health.log"
    FAIL_FILE="logs/${ENV_ID}/fail_count"

    mkdir -p "logs/${ENV_ID}"

    START=$(date +%s%N)
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${ENV_ID}:80/health" 2>/dev/null || echo "000")
    END=$(date +%s%N)
    LATENCY=$(( (END - START) / 1000000 ))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$TIMESTAMP | status=$HTTP_STATUS | latency=${LATENCY}ms" >> "$LOG_FILE"

    if [ "$HTTP_STATUS" != "200" ]; then
      FAILS=$(cat "$FAIL_FILE" 2>/dev/null || echo 0)
      FAILS=$((FAILS + 1))
      echo $FAILS > "$FAIL_FILE"

      if [ "$FAILS" -ge 3 ]; then
        echo "[$TIMESTAMP] $ENV_ID is DEGRADED after $FAILS consecutive failures"
        # Update status in state file
        python3 -c "import json,os; f='envs/${ENV_ID}.json'; d=json.load(open(f)); d['status']='degraded'; tmp=f+'.tmp'; json.dump(d,open(tmp,'w')); os.replace(tmp,f)"
      fi
    else
      echo 0 > "$FAIL_FILE"
    fi
  done

  sleep "$INTERVAL"
done