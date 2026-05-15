"""
Cookie Sync Server for ANR Saver + Cobalt
Deploy alongside Cobalt on VPS. Receives cookies from the app and writes to cookies.json.

Usage:
  pip install fastapi uvicorn
  COOKIE_PATH=/path/to/cookies.json API_KEY=your-secret-key COBALT_CONTAINER=cobalt uvicorn cookie_sync:app --host 0.0.0.0 --port 9001

Environment:
  COOKIE_PATH        - Path to Cobalt's cookies.json (default: ./cookies.json)
  API_KEY            - Secret key for authenticating requests from the app
  COBALT_CONTAINER   - Docker container name for Cobalt (for auto-restart)
"""

import json
import os
import subprocess
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Cookie Sync", docs_url=None, redoc_url=None)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

COOKIE_PATH = Path(os.getenv("COOKIE_PATH", "./cookies.json"))
API_KEY = os.getenv("API_KEY", "change-me-to-a-secret-key")
COBALT_CONTAINER = os.getenv("COBALT_CONTAINER", "cobalt")

VALID_PLATFORMS = {
    "youtube", "instagram", "twitter", "reddit",
    "facebook", "bilibili", "tiktok", "snapchat",
}


class CookiePayload(BaseModel):
    platform: str
    cookies: str  # "key1=val1; key2=val2; ..."


def _check_key(x_api_key: str = Header()):
    if x_api_key != API_KEY:
        raise HTTPException(401, "Invalid API key")


def _read_cookies() -> dict:
    if COOKIE_PATH.exists():
        return json.loads(COOKIE_PATH.read_text())
    return {}


def _write_cookies(data: dict):
    COOKIE_PATH.parent.mkdir(parents=True, exist_ok=True)
    COOKIE_PATH.write_text(json.dumps(data, indent=2))


def _restart_cobalt() -> bool:
    try:
        subprocess.run(
            ["docker", "restart", COBALT_CONTAINER],
            capture_output=True, timeout=30,
        )
        return True
    except Exception:
        return False


@app.post("/cookies")
def set_cookies(payload: CookiePayload, x_api_key: str = Header()):
    _check_key(x_api_key)
    if payload.platform not in VALID_PLATFORMS:
        raise HTTPException(400, f"Unknown platform: {payload.platform}")
    if not payload.cookies.strip():
        raise HTTPException(400, "Cookies cannot be empty")

    data = _read_cookies()
    data[payload.platform] = [payload.cookies]
    _write_cookies(data)

    # Auto-restart Cobalt to pick up new cookies
    restarted = _restart_cobalt()

    return {
        "status": "ok",
        "platform": payload.platform,
        "synced_at": datetime.utcnow().isoformat(),
        "cobalt_restarted": restarted,
    }


@app.get("/cookies")
def list_cookies(x_api_key: str = Header()):
    _check_key(x_api_key)
    data = _read_cookies()
    result = {}
    for p, v in data.items():
        cookie_str = v[0] if v else ""
        keys = [c.split("=")[0].strip() for c in cookie_str.split(";") if "=" in c]
        result[p] = {
            "has_cookies": bool(v),
            "cookie_count": len(keys),
            "cookie_keys": keys,
        }
    return {"platforms": result}


@app.delete("/cookies/{platform}")
def delete_cookies(platform: str, x_api_key: str = Header()):
    _check_key(x_api_key)
    data = _read_cookies()
    if platform in data:
        del data[platform]
        _write_cookies(data)
        _restart_cobalt()
    return {"status": "ok", "platform": platform, "deleted": True}


@app.post("/restart-cobalt")
def restart_cobalt(x_api_key: str = Header()):
    _check_key(x_api_key)
    restarted = _restart_cobalt()
    return {"status": "ok", "restarted": restarted}


@app.get("/health")
def health():
    return {"status": "ok", "cookie_path": str(COOKIE_PATH), "exists": COOKIE_PATH.exists()}
