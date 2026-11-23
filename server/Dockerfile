FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /srv
COPY requirements.txt .
RUN pip install -r requirements.txt

# Ayrıcalıksız kullanıcı (uid 10001). /secrets bağlaması bu kullanıcıya okunur olmalı (README).
RUN useradd --system --uid 10001 --no-create-home qrpro \
    && mkdir -p /data \
    && chown qrpro:qrpro /data
COPY app ./app

USER qrpro
EXPOSE 8000
# Konteyner yalnızca 127.0.0.1'e yayınlanır; gelen her bağlantı nginx'tendir, X-Forwarded-For güvenilir.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", \
     "--proxy-headers", "--forwarded-allow-ips", "*", "--no-server-header"]
