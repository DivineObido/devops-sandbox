#!/bin/bash
set -e

ENV_ID=$1

if [ -z "$ENV_ID" ]; then
  echo "Usage: destroy_env.sh <env-id>"
  exit 1
fi

STATE_FILE="envs/${ENV_ID}.json"
LOG_DIR="logs/${ENV_ID}"
NGINX_CONF="nginx/conf.d/${ENV_ID}.conf"
ARCHIVE_DIR="logs/archived/${ENV_ID}"

echo "[+] Destroying environment: $ENV_ID"

# Kill log shipper
if [ -f "$LOG_DIR/log_shipper.pid" ]; then
  PID=$(cat "$LOG_DIR/log_shipper.pid")
  kill "$PID" 2>/dev/null || true
  echo "Log shipper stopped (PID $PID)"
fi

# Stop and remove container
docker stop "$ENV_ID" 2>/dev/null || true
docker rm "$ENV_ID" 2>/dev/null || true

# Remove Docker network
docker network rm "$ENV_ID" 2>/dev/null || true

# Remove nginx config and reload
if [ -f "$NGINX_CONF" ]; then
  rm "$NGINX_CONF"
  docker exec sandbox-nginx nginx -s reload 2>/dev/null || true
  echo "Nginx config removed and reloaded"
fi

# Archive logs
if [ -d "$LOG_DIR" ]; then
  mkdir -p "$ARCHIVE_DIR"
  cp -r "$LOG_DIR/." "$ARCHIVE_DIR/"
  rm -rf "$LOG_DIR"
  echo "Logs archived to $ARCHIVE_DIR"
fi

# Delete state file
rm -f "$STATE_FILE"

echo "Environment $ENV_ID destroyed."