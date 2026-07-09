# ANR Saver — Backend (Cobalt + yt-dlp + Cookie Sync)

Three services the Flutter app talks to:

| Service      | Port | Role                                             |
|--------------|------|--------------------------------------------------|
| Cobalt       | 9000 | Primary fetch for all platforms (Docker)         |
| yt-dlp API   | 9002 | YouTube fallback (`POST /download`)              |
| Cookie Sync  | 9005 | Receives cookies from app → feeds Cobalt + yt-dlp|

Cobalt runs in Docker; the two Python services run via systemd.

## Clean deploy on a fresh VPS

Ubuntu/Debian, run as root:

```bash
git clone <this-repo> anrsaver && cd anrsaver/server
VPS_IP=<your.vps.ip> sudo -E bash install-vps.sh
```

The script installs Docker + Python + ffmpeg, starts Cobalt via compose,
sets up the venv + two systemd units, opens the firewall, and prints health
checks. Config lives in `/opt/anrsaver/.env` (copied from `.env.example`).

**Also open ports 9000/9002/9005 in your cloud provider's firewall**
(GCP VPC / AWS security group) — the OS `ufw` rule alone is not enough.

## Point the app at this VPS

Edit `lib/src/core/utils/api_config.dart` and replace the old IP in three places:
- `cobaltInstances` (the self-host entry)
- `cookieSyncUrl`
- `ytdlpApiUrl`

Keep `API_KEY` in `.env` equal to `ytdlpApiKey` / `cookieSyncApiKey` in the app.

## Why YouTube previously failed

`ytdlp_api.py` never passed cookies to yt-dlp, so login-gated videos returned
`youtube.login`. Now `cookie_sync.py` writes a Netscape `COOKIE_DIR/<platform>.txt`
on every `/cookies` sync, and `ytdlp_api.py` injects it via `--cookies`. Cobalt
still reads the JSON form from `cookies.json`.

## Manage

```bash
systemctl status ytdlp-api cookie-sync
journalctl -u ytdlp-api -f
cd /opt/anrsaver/server && docker compose logs -f cobalt
```

## Health

```bash
curl http://127.0.0.1:9000/            # cobalt info JSON
curl http://127.0.0.1:9002/health      # {"status":"ok","ytdlp_version":...}
curl http://127.0.0.1:9005/health      # {"status":"ok",...}
```
