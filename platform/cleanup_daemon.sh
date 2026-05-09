#!/bin/bash

LOGFILE="logs/cleanup.log"
mkdir -p logs

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleanup daemon started" >> "$LOGFILE"

while true; do
  NOW=$(date +%s)

  for STATE_FILE in envs/*.json; do
    [ -f "$STATE_FILE" ] || continue

    ENV_ID=$(basename "$STATE_FILE" .json)
    CREATED_AT=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['created_at'])")
    TTL=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['ttl'])")
    EXPIRES_AT=$((CREATED_AT + TTL))

    if [ "$NOW" -gt "$EXPIRES_AT" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] TTL expired for $ENV_ID — destroying" >> "$LOGFILE"
      bash platform/destroy_env.sh "$ENV_ID" >> "$LOGFILE" 2>&1
    fi
  done

  sleep 60
done