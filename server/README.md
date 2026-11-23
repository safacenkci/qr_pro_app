# QR Pro sunucusu

Android uygulaması QR Pro (`com.safarahmancenkci.qrpro`) için küçük bir FastAPI servisi:

| Uç | Açıklama |
| --- | --- |
| `POST /v1/purchases/verify` | `qr_pro_lifetime` satın alımını Google Play Developer API ile doğrular |
| `GET /privacy` | Türkçe + İngilizce gizlilik politikası |
| `GET /health` | `{"ok": true}` |
| `GET /` | `/privacy`'ye yönlendirir |

Canlı adres: `https://qrpro.safarahmancenkci.com` (yedek ad `https://qrpro.76-13-1-231.sslip.io`; sunucu `76.13.1.231`, kod `/opt/qrpro`, konteyner `qrpro-api`,
yalnızca `127.0.0.1:4400`, önünde nginx + Let's Encrypt).

## Doğrulama ucu

İstek: `{"packageName": "...", "productId": "...", "purchaseToken": "...", "orderId": "..." | null}`

Yanıt: `{"valid": true|false|null, "status": "verified"|"invalid"|"unverified", "reason": str|null}`

- Paket ya da ürün kimliği farklı → `valid:false` (`package_mismatch` / `product_mismatch`).
- Google `purchaseState == 0` → `valid:true`; onaylanmamışsa (`acknowledgementState == 0`) sunucu
  `purchases.products.acknowledge` çağırır (başarısızsa yine `valid:true`, `reason:"acknowledge_failed"`).
- İptal/iade (`purchaseState == 1`), bekleyen ödeme (`2`), tüketilmiş ürün, Google'ın bulamadığı token
  (400/404/410) → `valid:false`.
- Servis hesabı anahtarı yok/okunamıyor, Google'a ulaşılamıyor, 5xx/429 ya da izin hatası (401/403) →
  `valid:null, status:"unverified"`. İstemci bu durumda Play'in kendi sonucuna güvenir.
- Her istek SQLite'a (`/data/qrpro.db`, Docker volume `qrpro_qrpro-data`) `purchases` tablosuna yazılır; aynı token
  tekrar gelirse satır güncellenir. Google'ın yanıtına dayanan bir kayıt, Google'a sorulmadan verilen bir sonuçla
  (ör. yanlış paket adıyla gönderilen aynı token) ezilmez.
- Koruma: gövde en çok 8 KB (`413`), `/v1/` altında IP başına dakikada 30 istek (`429`, bellek içi).

Ayarlar `.env` dosyasından okunur (bkz. `.env.example`); hepsi isteğe bağlıdır. `CONTACT_EMAIL` gizlilik
sayfasındaki silme talebi adresidir.

## Servis hesabı anahtarını ekleme

Anahtar olmadan servis çalışır, yalnızca her doğrulama `unverified` döner.

1. **Google Cloud'da servis hesabı:** [Google Cloud Console](https://console.cloud.google.com/) → bir proje seçin
   ya da açın → *APIs & Services → Library* → **Google Play Android Developer API**'yi etkinleştirin.
   *IAM & Admin → Service Accounts → Create service account* ile bir hesap açın (Cloud rolü gerekmez).
   Hesabın *Keys* sekmesinden *Add key → Create new key → JSON* ile anahtarı indirin.
2. **Play Console'da yetki:** Play Console → *Kurulum → API erişimi* (Setup → API access) sayfasında aynı Cloud
   projesini bağlayın. (Bu sayfa yoksa: *Kullanıcılar ve izinler → Yeni kullanıcıları davet et* ile servis
   hesabının e-posta adresini ekleyin.) Servis hesabına uygulama izinlerinden en az şunları verin:
   **Finansal verileri görüntüleme** (View financial data) ve **Siparişleri ve abonelikleri yönet**
   (Manage orders and subscriptions). İzinlerin etkinleşmesi bazen birkaç saat sürer; o arada yanıt
   `unverified` / `google_permission_denied` olur.
3. **Anahtarı sunucuya koyun** (konteyner uid 10001 ile çalışır, klasör ona okunur olmalı):

   ```sh
   scp play-service-account.json root@76.13.1.231:/opt/qrpro/secrets/play-service-account.json
   ssh root@76.13.1.231 'cd /opt/qrpro \
     && chown -R 10001:10001 secrets && chmod 700 secrets && chmod 600 secrets/play-service-account.json \
     && docker compose restart'
   ```

4. Kontrol: `docker compose logs --tail 20 api` içinde "Servis hesabı anahtarı bulundu" yazmalı. Uygulamadan
   gerçek bir satın alma (lisans test hesabıyla) `valid:true` döndürmeli.

## Yeniden dağıtım

Depo kökünden (Windows'ta Git Bash):

```sh
cd server
tar --exclude=secrets --exclude=.env --exclude=__pycache__ --exclude=.pytest_cache -czf - . \
  | ssh root@76.13.1.231 'mkdir -p /opt/qrpro && tar --no-same-owner -xzf - -C /opt/qrpro'
ssh root@76.13.1.231 'cd /opt/qrpro && docker compose up -d --build && docker compose ps'
curl -s https://qrpro.safarahmancenkci.com/health
```

`secrets/` ve `.env` sunucuda kalır, kopyalama onlara dokunmaz. Veritabanı `qrpro_qrpro-data` volume'undadır;
`docker compose down` onu silmez (`down -v` siler, kullanmayın).

Yararlı komutlar (sunucuda, `/opt/qrpro` içinde):

```sh
docker compose logs -f api                      # günlükler
docker compose restart                          # .env ya da anahtar değişince
docker compose exec api python -c "import sqlite3; c=sqlite3.connect('/data/qrpro.db'); \
  print(c.execute('select token,status,reason,updated_at from purchases order by updated_at desc limit 10').fetchall())"
```

## nginx ve TLS

`/etc/nginx/sites-available/qrpro` (bağlantı `sites-enabled/qrpro`) `qrpro.safarahmancenkci.com` ve
`qrpro.76-13-1-231.sslip.io` adlarını
`127.0.0.1:4400`'e aktarır; sertifika `certbot --nginx` ile alındı ve kendiliğinden yenilenir, HTTP → HTTPS
yönlendirilir. `qrpro.safarahmancenkci.com` için Hostinger DNS'te `qrpro` → `76.13.1.231` A kaydı gerekir;
kayıt yayıldıktan sonra `certbot --nginx -d qrpro.safarahmancenkci.com --redirect`. nginx dosyasını değiştirdikten sonra her zaman `nginx -t && systemctl reload nginx`.

## Testler

```sh
cd server
python -m pip install -r requirements-dev.txt
python -m pytest -q
```
