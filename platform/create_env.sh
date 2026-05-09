#!/bin/bash
set -e

NAME=${1:-"unnamed"}
TTL=${2:-1800}

ENV_ID="env-$(date +%s)-$(shasha256sum /dev/urandom | head -c 6 || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 6)"
ENV_ID="env-$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | head -c 12 || date +%s%N | sha256sum | head -c 12)"

PORT=$(shuf -i 4000-9000 -n 1)
CREATED_AT=$(date +%s)
STATE_FILE="envs/${ENV_ID}.json"
LOG_DIR="logs/${ENV_ID}"
NGINX_CONF="nginx/conf.d/${ENV_ID}.conf"

echo "[+] Creating environment: $NAME (ID: $ENV_ID, TTL: ${TTL}s, Port: $PORT)"

mkdir -p "$LOG_DIR"

# Build demo app image if not exists
docker build -t sandbox-demo-app ./demo-app 2>/dev/null

# Create dedicated Docker network
docker network create "$ENV_ID" 2>/dev/null || true

# Start demo app container
docker run -d \
  --name "$ENV_ID" \
  --network "$ENV_ID" \
  --label "sandbox.env=$ENV_ID" \
  --label "sandbox.name=$NAME" \
  -p "${PORT}:80" \
  sandbox-demo-app

# Connect to nginx network so nginx can reach it
docker network connect sandbox-nginx "$ENV_ID" 2>/dev/null || true

# Write nginx config
cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name ${ENV_ID}.localhost;

    location / {
        proxy_pass http://${ENV_ID}:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /health {
        proxy_pass http://${ENV_ID}:80/health;
    }
}
EOF

# Reload nginx
docker exec sandbox-nginx nginx -s reload 2>/dev/null || true

# Write state file atomically
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
{
  "id": "$ENV_ID",
  "name": "$NAME",
  "port": $PORT,
  "created_at": $CREATED_AT,
  "ttl": $TTL,
  "status": "running"
}
EOF
mv "$TEMP_FILE" "$STATE_FILE"

# Start log shipping (Approach A)
docker logs -f "$ENV_ID" >> "$LOG_DIR/app.log" 2>&1 &
echo $! > "$LOG_DIR/log_shipper.pid"

echo ""
echo " Environment ready"
echo "ID:   $ENV_ID"
echo "URL:  http://localhost:$PORT"
echo "Host: http://${ENV_ID}.localhost (via nginx)"
echo "TTL:  ${TTL} seconds from now"