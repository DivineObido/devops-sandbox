#!/bin/bash

ENV_ID=""
MODE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --env) ENV_ID="$2"; shift ;;
    --mode) MODE="$2"; shift ;;
  esac
  shift
done

if [ -z "$ENV_ID" ] || [ -z "$MODE" ]; then
  echo "Usage: simulate_outage.sh --env <env-id> --mode <crash|pause|network|recover>"
  exit 1
fi

# Guard: never run against platform containers
if [[ "$ENV_ID" == "sandbox-nginx" || "$ENV_ID" == "sandbox-daemon" || "$ENV_ID" == "sandbox-api" ]]; then
  echo "Cannot simulate outage against platform containers."
  exit 1
fi

echo "[+] Simulating '$MODE' on $ENV_ID"

case $MODE in
  crash)
    docker kill "$ENV_ID"
    echo "Container killed. Health monitor should catch this within 90s."
    ;;
  pause)
    docker pause "$ENV_ID"
    echo "Container paused. Use --mode recover to unpause."
    ;;
  network)
    docker network disconnect sandbox-nginx "$ENV_ID"
    echo " Network disconnected from nginx."
    ;;
  recover)
    docker unpause "$ENV_ID" 2>/dev/null || true
    docker network connect sandbox-nginx "$ENV_ID" 2>/dev/null || true
    docker start "$ENV_ID" 2>/dev/null || true
    echo "Recovery attempted."
    ;;
  stress)
    docker exec "$ENV_ID" sh -c "apk add --no-cache stress-ng 2>/dev/null && stress-ng --cpu 2 --timeout 30s &"
    echo "CPU stress started for 30s."
    ;;
  *)
    echo "Unknown mode: $MODE"
    exit 1
    ;;
esac