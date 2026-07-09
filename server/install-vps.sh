#!/usr/bin/env bash
# Clean, idempotent deploy for the ANR Saver backend on a fresh Ubuntu/Debian VPS.
# Layout:
#   /opt/anrsaver/server   <- this repo's server/ dir
#   /opt/anrsaver/venv     <- python venv for the two API services
#   /opt/anrsaver/.env     <- config (from .env.example)
#   Cobalt (9000) via docker compose; ytdlp-api (9002) + cookie-sync (9005) via systemd.
#
# Usage (from the server/ dir on the VPS, as root):
#   VPS_IP=1.2.3.4 sudo -E bash install-vps.sh
set -euo pipefail

APP_DIR=/opt/anrsaver
SRC_DIR="$APP_DIR/server"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }

echo ">> Installing OS deps (docker, python, ffmpeg)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3 python3-venv python3-pip ffmpeg curl ufw
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || apt-get install -y -qq docker-compose-plugin

echo ">> Syncing source to $SRC_DIR..."
mkdir -p "$SRC_DIR" "$APP_DIR/cookies" "$APP_DIR/downloads"
cp -f "$SELF_DIR"/*.py "$SELF_DIR/requirements.txt" "$SELF_DIR/docker-compose.yml" "$SRC_DIR/"

# cookies.json must exist as a FILE before docker mounts it (else docker makes a dir)
[[ -f "$APP_DIR/cookies.json" ]] || echo '{}' > "$APP_DIR/cookies.json"

echo ">> Config (.env)..."
if [[ ! -f "$APP_DIR/.env" ]]; then
  cp "$SELF_DIR/.env.example" "$APP_DIR/.env"
  [[ -n "${VPS_IP:-}" ]] && sed -i "s/^VPS_IP=.*/VPS_IP=${VPS_IP}/" "$APP_DIR/.env"
  echo "   -> created $APP_DIR/.env (edit API_KEY / VPS_IP if needed)"
fi

echo ">> Python venv + deps..."
[[ -d "$APP_DIR/venv" ]] || python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install -q --upgrade pip
"$APP_DIR/venv/bin/pip" install -q -r "$SRC_DIR/requirements.txt"

echo ">> Cobalt via docker compose..."
( set -a; . "$APP_DIR/.env"; set +a; cd "$SRC_DIR" && docker compose up -d )

echo ">> systemd services..."
cp -f "$SELF_DIR/ytdlp-api.service" "$SELF_DIR/cookie-sync.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now ytdlp-api.service cookie-sync.service
systemctl restart ytdlp-api.service cookie-sync.service

echo ">> Firewall (open API ports)..."
ufw allow 22/tcp   >/dev/null 2>&1 || true
ufw allow 9000/tcp >/dev/null 2>&1 || true
ufw allow 9002/tcp >/dev/null 2>&1 || true
ufw allow 9005/tcp >/dev/null 2>&1 || true
# NOTE: also open 9000/9002/9005 in your cloud provider's firewall (GCP/AWS SG).

echo ">> Health checks..."
sleep 3
# Cobalt serves info at /, the Python services expose /health
cobalt=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:9000/" || echo 000)
echo "   port 9000 (cobalt) -> HTTP $cobalt"
for p in 9002 9005; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$p/health" || echo 000)
  echo "   port $p -> HTTP $code"
done

echo
echo "Done. Update lib/src/core/utils/api_config.dart to point at this VPS IP:"
echo "  cobaltInstances[self-host], cookieSyncUrl, ytdlpApiUrl"
