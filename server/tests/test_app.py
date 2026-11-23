import json
import sqlite3

import pytest
import requests
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app import config, main
from app.guards import RateLimit
from app.play import PlayVerifier, VerifyResult

PKG = "com.safarahmancenkci.qrpro"
PRODUCT = "qr_pro_lifetime"


@pytest.fixture(scope="module")
def client():
    with TestClient(main.app) as c:
        yield c


def _row(token):
    conn = sqlite3.connect(config.DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        return conn.execute("SELECT * FROM purchases WHERE token = ?", (token,)).fetchone()
    finally:
        conn.close()


def _body(token, **over):
    body = {"packageName": PKG, "productId": PRODUCT, "purchaseToken": token, "orderId": "GPA.1"}
    body.update(over)
    return body


def test_health_and_root(client):
    assert client.get("/health").json() == {"ok": True}
    r = client.get("/", follow_redirects=False)
    assert r.status_code == 302 and r.headers["location"] == "/privacy"


def test_privacy_page(client):
    r = client.get("/privacy")
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/html")
    html = r.text
    for text in ("QR Pro", "2026-11-23", "Gizlilik Politikası", "Privacy Policy", "Android 12",
                 "Google Play mağaza sayfasındaki geliştirici iletişim adresi"):
        assert text in html


def test_privacy_contact_email_escaped(monkeypatch, client):
    monkeypatch.setattr(config, "CONTACT_EMAIL", "a<b>@ornek.com")
    html = client.get("/privacy").text
    assert "mailto:a&lt;b&gt;@ornek.com" in html and "a<b>" not in html


def test_verify_without_key_is_unverified_and_recorded(client):
    r = client.post("/v1/purchases/verify", json=_body("tok-nokey"))
    assert r.json() == {"valid": None, "status": "unverified", "reason": "service_account_missing"}
    row = _row("tok-nokey")
    assert row["status"] == "unverified" and row["order_id"] == "GPA.1" and row["product_id"] == PRODUCT
    client.post("/v1/purchases/verify", json=_body("tok-nokey", orderId=None))
    row = _row("tok-nokey")
    assert row["request_count"] == 2 and row["order_id"] == "GPA.1"


def test_verify_wrong_package_and_product(client):
    r = client.post("/v1/purchases/verify", json=_body("tok-pkg", packageName="com.baska"))
    assert r.json() == {"valid": False, "status": "invalid", "reason": "package_mismatch"}
    assert _row("tok-pkg")["status"] == "invalid"
    r = client.post("/v1/purchases/verify", json=_body("tok-prod", productId="baska"))
    assert r.json()["valid"] is False and r.json()["reason"] == "product_mismatch"


def test_verify_rejects_bad_body(client):
    assert client.post("/v1/purchases/verify", json={"packageName": PKG}).status_code == 422
    big = _body("x" * 9000)
    assert client.post("/v1/purchases/verify", json=big).status_code == 413


def test_google_result_not_overwritten_by_unverified(monkeypatch, client):
    monkeypatch.setattr(
        main.verifier, "verify",
        lambda *a: VerifyResult(True, "verified", None, {"purchaseState": 0}),
    )
    assert client.post("/v1/purchases/verify", json=_body("tok-ok")).json()["valid"] is True
    monkeypatch.undo()
    client.post("/v1/purchases/verify", json=_body("tok-ok", packageName="com.baska"))
    row = _row("tok-ok")
    assert row["status"] == "verified" and row["package_name"] == PKG
    assert json.loads(row["raw_response"]) == {"purchaseState": 0}


class FakeResp:
    def __init__(self, status, data=None):
        self.status_code = status
        self._data = data
        self.text = json.dumps(data) if data is not None else ""

    def json(self):
        if self._data is None:
            raise ValueError("no json")
        return self._data


class FakeSession:
    def __init__(self, get_resp=None, get_exc=None, post_status=204):
        self.get_resp, self.get_exc, self.post_status = get_resp, get_exc, post_status
        self.posts = []

    def get(self, url, timeout):
        self.url = url
        if self.get_exc:
            raise self.get_exc
        return self.get_resp

    def post(self, url, json, timeout):
        self.posts.append(url)
        return FakeResp(self.post_status)


def _verifier(session):
    v = PlayVerifier("/yok")
    v._session = session
    return v


def test_play_verified_and_acknowledged():
    s = FakeSession(FakeResp(200, {"purchaseState": 0, "acknowledgementState": 0, "consumptionState": 0}))
    r = _verifier(s).verify(PKG, PRODUCT, "t/1")
    assert (r.valid, r.status, r.reason) == (True, "verified", None)
    assert s.url.endswith(f"/applications/{PKG}/purchases/products/{PRODUCT}/tokens/t%2F1")
    assert s.posts == [s.url + ":acknowledge"]


def test_play_already_acknowledged_no_post():
    s = FakeSession(FakeResp(200, {"purchaseState": 0, "acknowledgementState": 1}))
    assert _verifier(s).verify(PKG, PRODUCT, "t").valid is True and s.posts == []


def test_play_ack_failure_still_valid():
    s = FakeSession(FakeResp(200, {"purchaseState": 0, "acknowledgementState": 0}), post_status=500)
    r = _verifier(s).verify(PKG, PRODUCT, "t")
    assert r.valid is True and r.reason == "acknowledge_failed"


@pytest.mark.parametrize(
    "resp, exc, expected",
    [
        (FakeResp(200, {"purchaseState": 1}), None, (False, "invalid", "canceled")),
        (FakeResp(200, {"purchaseState": 2}), None, (False, "invalid", "pending")),
        (FakeResp(200, {"purchaseState": 0, "consumptionState": 1}), None, (False, "invalid", "consumed")),
        (FakeResp(404, {"error": {"code": 404}}), None, (False, "invalid", "purchase_not_found")),
        (FakeResp(410, {"error": {"code": 410}}), None, (False, "invalid", "purchase_not_found")),
        (FakeResp(503, {"error": {"code": 503}}), None, (None, "unverified", "google_error_503")),
        (FakeResp(403, {"error": {"code": 403}}), None, (None, "unverified", "google_permission_denied")),
        (None, requests.ConnectionError("ag yok"), (None, "unverified", "google_unreachable")),
    ],
)
def test_play_states(resp, exc, expected):
    r = _verifier(FakeSession(resp, exc)).verify(PKG, PRODUCT, "t")
    assert (r.valid, r.status, r.reason) == expected


def test_play_unreadable_key(tmp_path):
    key = tmp_path / "key.json"
    key.write_text("bozuk", encoding="utf-8")
    r = PlayVerifier(str(key)).verify(PKG, PRODUCT, "t")
    assert (r.valid, r.status, r.reason) == (None, "unverified", "service_account_unreadable")


def test_rate_limit():
    inner = FastAPI()

    @inner.post("/v1/x")
    def x():
        return {"ok": True}

    @inner.get("/health")
    def h():
        return {"ok": True}

    c = TestClient(RateLimit(inner, per_minute=3))
    codes = [c.post("/v1/x").status_code for _ in range(4)]
    assert codes == [200, 200, 200, 429]
    assert c.get("/health").status_code == 200
