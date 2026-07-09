"""
yt-dlp API Server - YouTube fallback for ANR Saver
Lightweight REST API that uses yt-dlp to extract video info and serve direct download URLs.

Usage:
  pip install fastapi uvicorn yt-dlp
  API_KEY=your-secret-key uvicorn ytdlp_api:app --host 0.0.0.0 --port 9002

Endpoints:
  POST /info   - Get video info (title, formats, thumbnail)
  POST /download - Get direct download URL
  GET  /health - Health check
"""

import os
import subprocess
import sys
import json
import shutil
import uuid
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(title="yt-dlp API", docs_url=None, redoc_url=None)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

API_KEY = os.getenv("API_KEY", "change-me")
DOWNLOAD_DIR = Path(os.getenv("DOWNLOAD_DIR", "/tmp/ytdlp-downloads"))
DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Shared with cookie_sync.py: dir holding per-platform Netscape cookie files
# (e.g. youtube.txt). Injected via yt-dlp --cookies so login-gated videos work.
COOKIE_DIR = Path(os.getenv("COOKIE_DIR", "/opt/anrsaver/cookies"))

# Resolve yt-dlp binary: prefer the one in this interpreter's venv (systemd
# runs uvicorn from the venv but its PATH may not include venv/bin), else PATH.
def _resolve_ytdlp() -> str:
    env = os.getenv("YTDLP_BIN")
    if env:
        return env
    venv_bin = Path(sys.executable).parent / "yt-dlp"
    if venv_bin.exists():
        return str(venv_bin)
    return shutil.which("yt-dlp") or "yt-dlp"


YTDLP_BIN = _resolve_ytdlp()


def _cookie_args(url: str) -> list:
    """Return ['--cookies', path] if a cookie file exists for this platform."""
    platform = None
    if "youtube.com" in url or "youtu.be" in url:
        platform = "youtube"
    elif "instagram.com" in url:
        platform = "instagram"
    elif "twitter.com" in url or "x.com" in url:
        platform = "twitter"
    elif "facebook.com" in url or "fb.watch" in url:
        platform = "facebook"
    if not platform:
        return []
    cookie_file = COOKIE_DIR / f"{platform}.txt"
    return ["--cookies", str(cookie_file)] if cookie_file.exists() else []


class VideoRequest(BaseModel):
    url: str
    quality: str = "720"


def _check_key(x_api_key: str = Header()):
    if x_api_key != API_KEY:
        raise HTTPException(401, "Invalid API key")


def _run_ytdlp(args: list, timeout: int = 30) -> dict:
    cmd = [YTDLP_BIN, "--no-warnings", "--no-check-certificates"] + args
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout,
        )
        if result.returncode != 0:
            raise Exception(result.stderr.strip() or "yt-dlp failed")
        return {"stdout": result.stdout, "stderr": result.stderr}
    except subprocess.TimeoutExpired:
        raise Exception("Request timed out")


@app.post("/info")
def get_info(req: VideoRequest, x_api_key: str = Header()):
    _check_key(x_api_key)

    try:
        result = _run_ytdlp([
            "-j", "--no-playlist",
            *_cookie_args(req.url),
            req.url,
        ], timeout=60)

        data = json.loads(result["stdout"])

        formats = []
        for f in data.get("formats", []):
            if f.get("vcodec", "none") != "none" and f.get("acodec", "none") != "none":
                formats.append({
                    "format_id": f["format_id"],
                    "ext": f.get("ext", "mp4"),
                    "height": f.get("height"),
                    "filesize": f.get("filesize") or f.get("filesize_approx"),
                    "quality": f"{f.get('height', '?')}p",
                })

        # Sort by height descending
        formats.sort(key=lambda x: x.get("height") or 0, reverse=True)

        return {
            "status": "ok",
            "title": data.get("title", ""),
            "thumbnail": data.get("thumbnail", ""),
            "duration": data.get("duration"),
            "uploader": data.get("uploader", ""),
            "formats": formats[:8],
        }
    except Exception as e:
        raise HTTPException(500, str(e))


@app.post("/download")
def get_download(req: VideoRequest, x_api_key: str = Header()):
    """Extract direct download URL or download and serve file"""
    _check_key(x_api_key)

    try:
        height = req.quality.replace("p", "")

        # YouTube's googlevideo URLs are locked to the extractor's IP, so a
        # redirect would be unfetchable from the user's device. Download on the
        # server and serve the file instead.
        is_youtube = "youtube.com" in req.url or "youtu.be" in req.url
        if is_youtube:
            return _download_merged(req.url, height)

        # Other platforms: prefer a progressive (muxed) stream and hand back a
        # direct URL with no server-side merge. Fall back to merge if needed.
        muxed_spec = (
            f"best[height<={height}][ext=mp4]/best[height<={height}]/best"
        )

        # One extraction that yields BOTH url and title (avoids a 2nd ~20s call)
        result = _run_ytdlp([
            "-f", muxed_spec,
            "--no-playlist",
            "--print", "%(urls)s",
            "--print", "%(title)s",
            *_cookie_args(req.url),
            req.url,
        ], timeout=60)

        lines = [l for l in result["stdout"].strip().split("\n") if l]
        # First non-empty line = url(s), last = title
        url_line = lines[0] if lines else ""
        title = lines[-1] if len(lines) >= 2 else "video"
        urls = url_line.split("\n")

        if len(urls) == 1 and urls[0].startswith("http"):
            # Single progressive URL - direct download possible
            return {
                "status": "redirect",
                "url": urls[0],
                "title": title,
                "filename": f"{title}.mp4",
            }
        else:
            # No muxed stream - fall back to server-side merge
            return _download_merged(req.url, height)

    except Exception as e:
        raise HTTPException(500, str(e))


def _download_merged(url: str, height: str) -> dict:
    """Download (merging if needed) and serve the resulting file."""
    format_spec = f"bestvideo[height<={height}]+bestaudio/best[height<={height}]/best"

    # Unique basename WITHOUT pre-creating the file: yt-dlp treats an existing
    # empty target as "already downloaded" and skips it, leaving a 0-byte file.
    token = uuid.uuid4().hex
    out_tmpl = str(DOWNLOAD_DIR / f"{token}.%(ext)s")

    try:
        result = _run_ytdlp([
            "-f", format_spec,
            "--merge-output-format", "mp4",
            "-o", out_tmpl,
            "--no-playlist",
            "--print", "after_move:filepath",
            "--print", "title",
            *_cookie_args(url),
            url,
        ], timeout=180)

        lines = [l for l in result["stdout"].strip().split("\n") if l]
        # after_move:filepath prints the final path; title prints after it
        final_path = Path(lines[0]) if lines else None
        title = lines[1] if len(lines) >= 2 else "video"

        if not final_path or not final_path.exists() or final_path.stat().st_size == 0:
            # Fallback: locate any file we wrote for this token
            matches = list(DOWNLOAD_DIR.glob(f"{token}.*"))
            matches = [m for m in matches if m.stat().st_size > 0]
            if not matches:
                raise Exception("Download failed: empty or missing output")
            final_path = matches[0]

        return {
            "status": "tunnel",
            "url": f"/files/{final_path.name}",
            "title": title,
            "filename": f"{title}.mp4",
        }
    except Exception:
        for m in DOWNLOAD_DIR.glob(f"{token}.*"):
            m.unlink(missing_ok=True)
        raise


@app.get("/files/{filename}")
def serve_file(filename: str):
    filepath = DOWNLOAD_DIR / filename
    if not filepath.exists() or filepath.stat().st_size == 0:
        raise HTTPException(404, "File not found")
    return FileResponse(filepath, media_type="video/mp4", filename=filename)


@app.get("/health")
def health():
    try:
        result = subprocess.run(
            [YTDLP_BIN, "--version"], capture_output=True, text=True, timeout=5,
        )
        version = result.stdout.strip()
    except Exception:
        version = "not installed"

    return {"status": "ok", "ytdlp_version": version}
