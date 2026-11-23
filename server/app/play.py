"""Google Play Developer API (androidpublisher v3) ile tek seferlik ürün satın alımı doğrulama.

Servis hesabı anahtarı yoksa, okunamıyorsa ya da Google'a ulaşılamıyorsa sonuç `unverified` olur (valid=None):
istemci bu durumda Play'in kendi sonucuna güvenir. Google'ın kesin olarak "geçersiz" dediği durumlar
(token yok, iptal, iade, bekleyen ödeme) `invalid` (valid=False) olur.
"""

import logging
import os
import threading
from dataclasses import dataclass
from urllib.parse import quote

import requests
from google.auth.exceptions import GoogleAuthError, RefreshError, TransportError
from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account

from . import config

log = logging.getLogger("qrpro.play")

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
API_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"

# ProductPurchase.purchaseState: 0 satın alındı, 1 iptal (iade/geri ödeme dahil), 2 bekliyor.
_STATE_REASONS = {1: "canceled", 2: "pending"}


@dataclass
class VerifyResult:
    valid: bool | None
    status: str  # "verified" | "invalid" | "unverified"
    reason: str | None
    raw: dict | None = None


def _unverified(reason: str, raw: dict | None = None) -> VerifyResult:
    return VerifyResult(valid=None, status="unverified", reason=reason, raw=raw)


def _invalid(reason: str, raw: dict | None = None) -> VerifyResult:
    return VerifyResult(valid=False, status="invalid", reason=reason, raw=raw)


def _json_or_text(resp: requests.Response) -> dict:
    try:
        data = resp.json()
        if isinstance(data, dict):
            return {"httpStatus": resp.status_code, **data}
    except ValueError:
        pass
    return {"httpStatus": resp.status_code, "text": resp.text[:2000]}


class PlayVerifier:
    def __init__(self, service_account_file: str) -> None:
        self._path = service_account_file
        self._session: AuthorizedSession | None = None
        self._lock = threading.Lock()

    def is_configured(self) -> bool:
        return os.path.isfile(self._path)

    def _get_session(self) -> AuthorizedSession | None:
        """Anahtar dosyası ilk kez görüldüğünde oturum kurulur; dosya yoksa her istekte yeniden bakılır."""
        if self._session is not None:
            return self._session
        with self._lock:
            if self._session is None and os.path.isfile(self._path):
                creds = service_account.Credentials.from_service_account_file(self._path, scopes=[SCOPE])
                self._session = AuthorizedSession(creds)
            return self._session

    def _url(self, package_name: str, product_id: str, token: str) -> str:
        return (
            f"{API_BASE}/{quote(package_name, safe='')}/purchases/products/"
            f"{quote(product_id, safe='')}/tokens/{quote(token, safe='')}"
        )

    def verify(self, package_name: str, product_id: str, token: str) -> VerifyResult:
        try:
            session = self._get_session()
        except (OSError, ValueError, KeyError, GoogleAuthError) as exc:
            log.error("Servis hesabı anahtarı okunamadı (%s): %s", self._path, exc)
            return _unverified("service_account_unreadable")
        if session is None:
            return _unverified("service_account_missing")

        url = self._url(package_name, product_id, token)
        try:
            resp = session.get(url, timeout=config.GOOGLE_TIMEOUT)
        except RefreshError as exc:
            log.error("Google erişim belirteci alınamadı: %s", exc)
            return _unverified("google_auth_failed")
        except (requests.RequestException, TransportError) as exc:
            log.warning("Google Play API'ye ulaşılamadı: %s", exc)
            return _unverified("google_unreachable")

        if resp.status_code != 200:
            raw = _json_or_text(resp)
            if resp.status_code in (400, 404, 410):
                return _invalid("purchase_not_found", raw)
            if resp.status_code in (401, 403):
                # Yapılandırma sorunu (izin verilmemiş servis hesabı): kullanıcıyı cezalandırma.
                log.error("Google Play API izin hatası %s: %s", resp.status_code, raw)
                return _unverified("google_permission_denied", raw)
            log.warning("Google Play API hatası %s", resp.status_code)
            return _unverified(f"google_error_{resp.status_code}", raw)

        try:
            data = resp.json()
        except ValueError:
            return _unverified("google_bad_response")
        if not isinstance(data, dict):
            return _unverified("google_bad_response")

        state = data.get("purchaseState")
        if state != 0:
            return _invalid(_STATE_REASONS.get(state, "unknown_state"), data)
        if data.get("consumptionState") == 1:
            # Ömür boyu ürün tüketilmişse kullanıcı artık ona sahip değildir.
            return _invalid("consumed", data)

        reason = None
        if data.get("acknowledgementState") == 0:
            if not self._acknowledge(session, url):
                reason = "acknowledge_failed"
        return VerifyResult(valid=True, status="verified", reason=reason, raw=data)

    def _acknowledge(self, session: AuthorizedSession, url: str) -> bool:
        try:
            resp = session.post(f"{url}:acknowledge", json={}, timeout=config.GOOGLE_TIMEOUT)
        except (requests.RequestException, GoogleAuthError) as exc:
            log.warning("Onaylama (acknowledge) isteği başarısız: %s", exc)
            return False
        if resp.status_code not in (200, 204):
            log.warning("Onaylama (acknowledge) hatası %s: %s", resp.status_code, resp.text[:500])
            return False
        return True
