"""QR Pro sunucusu: Google Play satın alma doğrulama, gizlilik politikası ve sağlık ucu."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel, ConfigDict, Field

from . import config, db
from .guards import BodySizeLimit, RateLimit
from .play import PlayVerifier, VerifyResult
from .privacy import render_privacy

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("qrpro")

verifier = PlayVerifier(config.SERVICE_ACCOUNT_FILE)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    db.init_db()
    if verifier.is_configured():
        log.info("Servis hesabı anahtarı bulundu: Google Play doğrulaması açık.")
    else:
        log.warning("Servis hesabı anahtarı yok (%s): yanıtlar 'unverified' olacak.", config.SERVICE_ACCOUNT_FILE)
    yield


app = FastAPI(title="QR Pro", docs_url=None, redoc_url=None, openapi_url=None, lifespan=lifespan)
# Son eklenen en dışta çalışır: önce hız sınırı, sonra gövde sınırı.
app.add_middleware(BodySizeLimit, max_bytes=config.MAX_BODY_BYTES)
app.add_middleware(RateLimit, per_minute=config.RATE_LIMIT_PER_MINUTE, path_prefix="/v1/")


class VerifyRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    packageName: str = Field(min_length=1, max_length=255)
    productId: str = Field(min_length=1, max_length=255)
    purchaseToken: str = Field(min_length=1, max_length=4096)
    orderId: str | None = Field(default=None, max_length=255)


class VerifyResponse(BaseModel):
    valid: bool | None
    status: str
    reason: str | None


@app.post("/v1/purchases/verify", response_model=VerifyResponse)
def verify_purchase(req: VerifyRequest) -> VerifyResponse:
    # Eşzamanlı (def) uç: FastAPI iş parçacığı havuzunda çalıştırır, Google isteği olay döngüsünü tıkamaz.
    if req.packageName != config.PACKAGE_NAME:
        result = VerifyResult(valid=False, status="invalid", reason="package_mismatch")
    elif req.productId != config.PRODUCT_ID:
        result = VerifyResult(valid=False, status="invalid", reason="product_mismatch")
    else:
        result = verifier.verify(req.packageName, req.productId, req.purchaseToken)

    try:
        db.record_purchase(
            token=req.purchaseToken,
            package_name=req.packageName,
            product_id=req.productId,
            order_id=req.orderId,
            status=result.status,
            reason=result.reason,
            raw_response=result.raw,
        )
    except Exception:  # Kayıt hatası doğrulama sonucunu bozmasın.
        log.exception("Satın alma kaydı yazılamadı")

    log.info(
        "verify token=%s… order=%s -> %s (%s)",
        req.purchaseToken[:12],
        req.orderId,
        result.status,
        result.reason,
    )
    return VerifyResponse(valid=result.valid, status=result.status, reason=result.reason)


_PRIVACY_HEADERS = {
    "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
    "form-action 'none'; frame-ancestors 'none'",
    "Cache-Control": "public, max-age=3600",
}


@app.get("/privacy", response_class=HTMLResponse)
def privacy() -> HTMLResponse:
    return HTMLResponse(render_privacy(config.CONTACT_EMAIL), headers=_PRIVACY_HEADERS)


@app.get("/health")
def health() -> dict:
    return {"ok": True}


@app.get("/")
def root() -> RedirectResponse:
    return RedirectResponse("/privacy", status_code=302)
