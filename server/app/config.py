"""Ortam değişkenlerinden okunan ayarlar."""

import os


def _int(name: str, default: int) -> int:
    try:
        return int(os.environ.get(name, default))
    except ValueError:
        return default


PACKAGE_NAME = os.environ.get("PACKAGE_NAME", "com.safarahmancenkci.qrpro")
PRODUCT_ID = os.environ.get("PRODUCT_ID", "qr_pro_lifetime")
DB_PATH = os.environ.get("DB_PATH", "/data/qrpro.db")
SERVICE_ACCOUNT_FILE = os.environ.get("SERVICE_ACCOUNT_FILE", "/secrets/play-service-account.json")
CONTACT_EMAIL = os.environ.get("CONTACT_EMAIL", "").strip()

# Kötüye kullanım koruması.
MAX_BODY_BYTES = _int("MAX_BODY_BYTES", 8 * 1024)
RATE_LIMIT_PER_MINUTE = _int("RATE_LIMIT_PER_MINUTE", 30)

# Google Play Developer API isteklerinin zaman aşımı (saniye).
GOOGLE_TIMEOUT = _int("GOOGLE_TIMEOUT", 10)
