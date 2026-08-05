#!/usr/bin/env python3
"""Allocate remote-browser slots to Shared Surf Feed clients.

This is a deliberately small prototype broker. It does not start browsers and it
never receives provider passwords or cookies. Operators supply a fixed list of
HTTPS remote-browser viewer URLs, with each browser already logged into the same
disposable provider account.
"""

from __future__ import annotations

import hashlib
import hmac
import html
import json
import os
import secrets
import signal
import threading
import time
from dataclasses import dataclass
from http import HTTPStatus
from http.cookies import SimpleCookie
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Final
from urllib.parse import urlsplit

COOKIE_NAME: Final = "surf_feed_session"


def env_int(name: str, default: int, minimum: int = 0) -> int:
    raw = os.environ.get(name, str(default)).strip()
    try:
        value = int(raw)
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer") from exc
    if value < minimum:
        raise RuntimeError(f"{name} must be at least {minimum}")
    return value


def env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def load_slot_urls() -> tuple[str, ...]:
    raw = os.environ.get("SURF_FEED_SLOT_URLS", "")
    slots = tuple(part.strip() for part in raw.split(",") if part.strip())
    if not slots:
        raise RuntimeError("SURF_FEED_SLOT_URLS must contain at least one URL")

    for slot in slots:
        parsed = urlsplit(slot)
        if parsed.scheme != "https" or not parsed.netloc:
            raise RuntimeError(
                "Every SURF_FEED_SLOT_URLS entry must be an absolute HTTPS URL"
            )
    return slots


@dataclass(slots=True)
class Allocation:
    session_id: str
    slot_index: int
    last_seen: float


class SlotBroker:
    def __init__(self, slot_urls: tuple[str, ...], ttl_seconds: int) -> None:
        self.slot_urls = slot_urls
        self.ttl_seconds = ttl_seconds
        self._allocations: dict[str, Allocation] = {}
        self._slot_owners: list[str | None] = [None] * len(slot_urls)
        self._lock = threading.Lock()

    def _cleanup_locked(self, now: float) -> None:
        expired = [
            session_id
            for session_id, allocation in self._allocations.items()
            if now - allocation.last_seen >= self.ttl_seconds
        ]
        for session_id in expired:
            allocation = self._allocations.pop(session_id)
            if self._slot_owners[allocation.slot_index] == session_id:
                self._slot_owners[allocation.slot_index] = None

    def allocate(self, existing_session_id: str | None) -> Allocation | None:
        now = time.monotonic()
        with self._lock:
            self._cleanup_locked(now)
            if existing_session_id:
                existing = self._allocations.get(existing_session_id)
                if existing:
                    existing.last_seen = now
                    return existing

            try:
                slot_index = self._slot_owners.index(None)
            except ValueError:
                return None

            session_id = secrets.token_urlsafe(24)
            allocation = Allocation(session_id, slot_index, now)
            self._allocations[session_id] = allocation
            self._slot_owners[slot_index] = session_id
            return allocation

    def touch(self, session_id: str) -> bool:
        now = time.monotonic()
        with self._lock:
            self._cleanup_locked(now)
            allocation = self._allocations.get(session_id)
            if not allocation:
                return False
            allocation.last_seen = now
            return True

    def release(self, session_id: str) -> None:
        with self._lock:
            allocation = self._allocations.pop(session_id, None)
            if allocation and self._slot_owners[allocation.slot_index] == session_id:
                self._slot_owners[allocation.slot_index] = None

    def status(self) -> dict[str, int]:
        now = time.monotonic()
        with self._lock:
            self._cleanup_locked(now)
            active = len(self._allocations)
            return {
                "slots_total": len(self.slot_urls),
                "slots_active": active,
                "slots_free": len(self.slot_urls) - active,
            }


class AppConfig:
    def __init__(self) -> None:
        self.slot_urls = load_slot_urls()
        self.secret = os.environ.get("SURF_FEED_COOKIE_SECRET", "").encode()
        if len(self.secret) < 32:
            raise RuntimeError("SURF_FEED_COOKIE_SECRET must be at least 32 characters")

        self.host = os.environ.get("HOST", "0.0.0.0")
        self.port = env_int("PORT", 8080, 1)
        self.ttl_seconds = env_int("SURF_FEED_SESSION_TTL_SECONDS", 900, 30)
        self.heartbeat_seconds = env_int("SURF_FEED_HEARTBEAT_SECONDS", 20, 5)
        self.crop_left = env_int("SURF_FEED_CROP_LEFT_PX", 0)
        self.crop_right = env_int("SURF_FEED_CROP_RIGHT_PX", 0)
        self.crop_top = env_int("SURF_FEED_CROP_TOP_PX", 0)
        self.crop_bottom = env_int("SURF_FEED_CROP_BOTTOM_PX", 0)
        self.cookie_secure = env_bool("SURF_FEED_COOKIE_SECURE", True)

        origins = {
            f"{urlsplit(url).scheme}://{urlsplit(url).netloc}" for url in self.slot_urls
        }
        self.frame_sources = " ".join(sorted(origins))


CONFIG = AppConfig()
BROKER = SlotBroker(CONFIG.slot_urls, CONFIG.ttl_seconds)


def sign_session(session_id: str) -> str:
    digest = hmac.new(CONFIG.secret, session_id.encode(), hashlib.sha256).hexdigest()
    return f"{session_id}.{digest}"


def verify_session(token: str | None) -> str | None:
    if not token or "." not in token:
        return None
    session_id, supplied_digest = token.rsplit(".", 1)
    expected_digest = hmac.new(
        CONFIG.secret, session_id.encode(), hashlib.sha256
    ).hexdigest()
    if not hmac.compare_digest(supplied_digest, expected_digest):
        return None
    return session_id


def render_feed(slot_url: str) -> bytes:
    escaped_url = html.escape(slot_url, quote=True)
    heartbeat_ms = CONFIG.heartbeat_seconds * 1000
    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Shared Surf Feed</title>
<style>
html,body{{width:100%;height:100%;margin:0;overflow:hidden;background:#000}}
#viewport{{position:fixed;inset:0;overflow:hidden;background:#000}}
#viewer{{position:absolute;left:-{CONFIG.crop_left}px;top:-{CONFIG.crop_top}px;
width:calc(100% + {CONFIG.crop_left + CONFIG.crop_right}px);
height:calc(100% + {CONFIG.crop_top + CONFIG.crop_bottom}px);border:0;background:#000}}
</style>
</head>
<body>
<div id="viewport"><iframe id="viewer" src="{escaped_url}" allow="autoplay; fullscreen; clipboard-read; clipboard-write"></iframe></div>
<script>
const heartbeat = () => fetch('/heartbeat', {{method:'POST',cache:'no-store',credentials:'same-origin'}}).catch(() => {{}});
setInterval(heartbeat, {heartbeat_ms});
addEventListener('pagehide', () => navigator.sendBeacon('/release', ''));
</script>
</body>
</html>"""
    return document.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    server_version = "SurfFeedBroker/0.1"

    def log_message(self, message: str, *args: object) -> None:
        # Do not log URLs or cookies. The standard request line contains only the
        # broker path, but this compact format keeps logs intentionally minimal.
        print(f"{self.address_string()} - {message % args}")

    def _session_from_cookie(self) -> str | None:
        cookie = SimpleCookie()
        cookie.load(self.headers.get("Cookie", ""))
        morsel = cookie.get(COOKIE_NAME)
        return verify_session(morsel.value if morsel else None)

    def _security_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'none'; "
            f"frame-src {CONFIG.frame_sources}; "
            "script-src 'unsafe-inline'; style-src 'unsafe-inline'; "
            "connect-src 'self'; frame-ancestors 'none'; base-uri 'none'",
        )

    def _send(self, status: HTTPStatus, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self._security_headers()
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _set_session_cookie(self, session_id: str) -> None:
        cookie = SimpleCookie()
        cookie[COOKIE_NAME] = sign_session(session_id)
        cookie[COOKIE_NAME]["path"] = "/"
        cookie[COOKIE_NAME]["httponly"] = True
        cookie[COOKIE_NAME]["samesite"] = "Lax"
        cookie[COOKIE_NAME]["max-age"] = str(CONFIG.ttl_seconds)
        if CONFIG.cookie_secure:
            cookie[COOKIE_NAME]["secure"] = True
        self.send_header("Set-Cookie", cookie.output(header="").strip())

    def _clear_session_cookie(self) -> None:
        cookie = SimpleCookie()
        cookie[COOKIE_NAME] = ""
        cookie[COOKIE_NAME]["path"] = "/"
        cookie[COOKIE_NAME]["max-age"] = "0"
        cookie[COOKIE_NAME]["httponly"] = True
        cookie[COOKIE_NAME]["samesite"] = "Lax"
        if CONFIG.cookie_secure:
            cookie[COOKIE_NAME]["secure"] = True
        self.send_header("Set-Cookie", cookie.output(header="").strip())

    def do_GET(self) -> None:  # noqa: N802 - stdlib handler API
        if self.path == "/healthz":
            body = json.dumps(BROKER.status(), separators=(",", ":")).encode()
            self._send(HTTPStatus.OK, body, "application/json; charset=utf-8")
            return

        if self.path != "/":
            self._send(HTTPStatus.NOT_FOUND, b"Not found\n", "text/plain; charset=utf-8")
            return

        allocation = BROKER.allocate(self._session_from_cookie())
        if not allocation:
            body = (
                b"<!doctype html><meta charset='utf-8'><title>Shared Surf Feed</title>"
                b"<body style='font-family:sans-serif;background:#111;color:#eee'>"
                b"<h1>All feed sessions are currently in use.</h1>"
                b"<p>Close an unused feed window or try again shortly.</p></body>"
            )
            self._send(HTTPStatus.SERVICE_UNAVAILABLE, body, "text/html; charset=utf-8")
            return

        body = render_feed(CONFIG.slot_urls[allocation.slot_index])
        self.send_response(HTTPStatus.OK)
        self._security_headers()
        self._set_session_cookie(allocation.session_id)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:  # noqa: N802 - stdlib handler API
        session_id = self._session_from_cookie()

        if self.path == "/heartbeat":
            status = HTTPStatus.NO_CONTENT if session_id and BROKER.touch(session_id) else HTTPStatus.GONE
            self.send_response(status)
            self._security_headers()
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        if self.path == "/release":
            if session_id:
                BROKER.release(session_id)
            self.send_response(HTTPStatus.NO_CONTENT)
            self._security_headers()
            self._clear_session_cookie()
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        self._send(HTTPStatus.NOT_FOUND, b"Not found\n", "text/plain; charset=utf-8")


def main() -> None:
    server = ThreadingHTTPServer((CONFIG.host, CONFIG.port), Handler)

    def stop_server(_signum: int, _frame: object) -> None:
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop_server)
    signal.signal(signal.SIGINT, stop_server)
    print(
        f"Shared Surf Feed broker listening on {CONFIG.host}:{CONFIG.port} "
        f"with {len(CONFIG.slot_urls)} slots"
    )
    server.serve_forever()
    server.server_close()


if __name__ == "__main__":
    main()
