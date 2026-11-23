"""SQLite kayıtları: her doğrulama isteği `purchases` tablosuna yazılır (token başına tek satır)."""

import json
import os
import sqlite3
import threading
from contextlib import closing
from datetime import datetime, timezone

from . import config

_lock = threading.Lock()

_SCHEMA = """
CREATE TABLE IF NOT EXISTS purchases (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    token         TEXT    NOT NULL UNIQUE,
    package_name  TEXT    NOT NULL,
    product_id    TEXT    NOT NULL,
    order_id      TEXT,
    status        TEXT    NOT NULL,
    reason        TEXT,
    raw_response  TEXT,
    request_count INTEGER NOT NULL DEFAULT 1,
    created_at    TEXT    NOT NULL,
    updated_at    TEXT    NOT NULL
);
"""

# Aynı token yeniden gelirse satır güncellenir. Google'ın yanıtına dayanan bir sonuç (raw_response dolu),
# Google'a hiç sorulmadan verilen bir sonuçla (paket uyuşmazlığı, anahtar yok, ağ hatası) ezilmez: başkası
# bildiği bir token'ı yanlış paket adıyla göndererek doğrulanmış kaydı bozamasın.
_UPSERT = """
INSERT INTO purchases (token, package_name, product_id, order_id, status, reason, raw_response,
                       created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(token) DO UPDATE SET
    package_name  = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                         THEN purchases.package_name ELSE excluded.package_name END,
    product_id    = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                         THEN purchases.product_id ELSE excluded.product_id END,
    order_id      = COALESCE(excluded.order_id, purchases.order_id),
    status        = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                         THEN purchases.status ELSE excluded.status END,
    reason        = CASE WHEN excluded.raw_response IS NULL AND purchases.raw_response IS NOT NULL
                         THEN purchases.reason ELSE excluded.reason END,
    raw_response  = COALESCE(excluded.raw_response, purchases.raw_response),
    request_count = purchases.request_count + 1,
    updated_at    = excluded.updated_at
"""


def _connect() -> sqlite3.Connection:
    conn = sqlite3.connect(config.DB_PATH, timeout=10)
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db() -> None:
    directory = os.path.dirname(config.DB_PATH)
    if directory:
        os.makedirs(directory, exist_ok=True)
    with _lock, closing(_connect()) as conn, conn:
        conn.executescript(_SCHEMA)


def record_purchase(
    *,
    token: str,
    package_name: str,
    product_id: str,
    order_id: str | None,
    status: str,
    reason: str | None,
    raw_response: dict | None,
) -> None:
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    raw = json.dumps(raw_response, ensure_ascii=False) if raw_response is not None else None
    with _lock, closing(_connect()) as conn, conn:
        conn.execute(
            _UPSERT,
            (token, package_name, product_id, order_id, status, reason, raw, now, now),
        )
