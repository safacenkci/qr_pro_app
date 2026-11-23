"""Basit kötüye kullanım koruması: gövde boyutu sınırı ve IP başına dakikalık istek sınırı (bellek içi).

İkisi de saf ASGI ara katmanıdır. İstemci IP'si uvicorn'un `--proxy-headers` ayarıyla nginx'in gönderdiği
X-Forwarded-For'dan gelir (konteyner yalnızca 127.0.0.1'e bağlıdır, başka kimse başlık uyduramaz).
"""

import json
import threading
import time
from collections import deque


async def _send_json(send, status: int, payload: dict, headers: list | None = None) -> None:
    body = json.dumps(payload).encode()
    await send(
        {
            "type": "http.response.start",
            "status": status,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(body)).encode()),
                *(headers or []),
            ],
        }
    )
    await send({"type": "http.response.body", "body": body})


class BodySizeLimit:
    """Gövdeyi en çok `max_bytes` bayta kadar belleğe alır; aşılırsa 413 döner."""

    def __init__(self, app, max_bytes: int) -> None:
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)

        for name, value in scope.get("headers", []):
            if name == b"content-length":
                try:
                    if int(value) > self.max_bytes:
                        return await _send_json(send, 413, {"error": "payload_too_large"})
                except ValueError:
                    return await _send_json(send, 400, {"error": "bad_content_length"})

        chunks: list[bytes] = []
        size = 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            chunk = message.get("body", b"")
            size += len(chunk)
            if size > self.max_bytes:
                return await _send_json(send, 413, {"error": "payload_too_large"})
            chunks.append(chunk)
            if not message.get("more_body", False):
                break

        body = b"".join(chunks)
        sent = False

        async def replay():
            nonlocal sent
            if not sent:
                sent = True
                return {"type": "http.request", "body": body, "more_body": False}
            return await receive()

        return await self.app(scope, replay, send)


class RateLimit:
    """`path_prefix` ile başlayan yollarda IP başına kayan 60 saniyelik pencerede en çok `per_minute` istek."""

    WINDOW = 60.0

    def __init__(self, app, per_minute: int, path_prefix: str = "/v1/") -> None:
        self.app = app
        self.per_minute = per_minute
        self.path_prefix = path_prefix
        self._hits: dict[str, deque] = {}
        self._lock = threading.Lock()
        self._last_sweep = time.monotonic()

    def _allow(self, ip: str) -> tuple[bool, int]:
        now = time.monotonic()
        with self._lock:
            if now - self._last_sweep > self.WINDOW:
                self._sweep(now)
            hits = self._hits.setdefault(ip, deque())
            while hits and now - hits[0] >= self.WINDOW:
                hits.popleft()
            if len(hits) >= self.per_minute:
                return False, max(1, int(self.WINDOW - (now - hits[0])) + 1)
            hits.append(now)
            return True, 0

    def _sweep(self, now: float) -> None:
        stale = [ip for ip, hits in self._hits.items() if not hits or now - hits[-1] >= self.WINDOW]
        for ip in stale:
            del self._hits[ip]
        self._last_sweep = now

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http" and scope.get("path", "").startswith(self.path_prefix):
            client = scope.get("client")
            ip = client[0] if client else "unknown"
            allowed, retry_after = self._allow(ip)
            if not allowed:
                return await _send_json(
                    send,
                    429,
                    {"error": "rate_limited"},
                    [(b"retry-after", str(retry_after).encode())],
                )
        return await self.app(scope, receive, send)
