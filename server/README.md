# QR Pro sunucusu

Android uygulaması QR Pro (`com.safarahmancenkci.qrpro`) için küçük bir ASP.NET Core (.NET 10, minimal API) servisi,
veritabanı PostgreSQL 17:

| Uç | Açıklama |
| --- | --- |
| `POST /v1/purchases/verify` | `qr_pro_lifetime` satın alımını Google Play Developer API ile doğrular |
| `GET /privacy` | Türkçe + İngilizce gizlilik politikası |
| `GET /health` | `{"ok":true}` |
| `GET /` | `/privacy`'ye yönlendirir (302) |

Canlı adres: `https://qrpro.safarahmancenkci.com` (yedek ad `https://qrpro.76-13-1-231.sslip.io`; sunucu `76.13.1.231`,
kod `/opt/qrpro`, compose projesi `qrpro`, önünde nginx + Let's Encrypt).

| Konteyner | Görev |
| --- | --- |
| `qrpro-api` | API; yalnızca `127.0.0.1:4400`'e bağlı, uid 10001 ile çalışır |
| `qrpro-postgres` | `postgres:17-alpine`; host'a port açmaz, yalnızca compose iç ağı. Veri: volume `qrpro_qrpro-pgdata` |
| `qrpro-backup` | Her gün 03:00 UTC `pg_dump`, 14 gün saklar. Yedekler: volume `qrpro_qrpro-backups` |

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
- Eksik ya da hatalı gövde → `422` (`{"detail": [...]}`); bilinmeyen alanlar yok sayılır.
- Her istek Postgres'te `purchases` tablosuna yazılır (token başına tek satır, upsert): `token` (UNIQUE),
  `package_name`, `product_id`, `order_id`, `status`, `reason`, `raw_response` (Google'ın ham yanıtı, jsonb),
  `client_ip`, `request_count`, `created_at`, `updated_at`. Aynı token tekrar gelirse satır güncellenir.
  Google'ın yanıtına dayanan bir kayıt, Google'a sorulmadan verilen bir sonuçla (ör. yanlış paket adıyla gönderilen
  aynı token) ezilmez. Kayıt yazılamazsa yanıt yine döner (hata günlüğe yazılır).
- Koruma: gövde en çok 8 KB (`413`), `/v1/` altında IP başına kayan 60 saniyelik pencerede 30 istek (`429` ve
  `Retry-After`, bellek içi). İstemci IP'si `X-Forwarded-For`'un ilk girdisi, yoksa `X-Real-IP`, o da yoksa bağlantı
  adresi (nginx ikisini de `$remote_addr` ile doldurur; konteyner yalnızca 127.0.0.1'e açık olduğundan başlığı başkası
  uyduramaz).

Tablo şeması EF Core migration'larıyla (`QrPro.Api/Data/Migrations`) yönetilir; uygulama açılışta bekleyen
migration'ları kendisi uygular (Postgres hazır değilse 60 sn boyunca yeniden dener).

Ayarlar `.env` dosyasından okunur (bkz. `.env.example`). `POSTGRES_PASSWORD` zorunludur, gerisi isteğe bağlıdır.
`CONTACT_EMAIL` gizlilik sayfasındaki silme talebi adresidir.

## İlk kurulum

Sunucuda Docker ve compose eklentisi kurulu olmalı. Depo kökünden (Windows'ta Git Bash):

```sh
cd server
tar --exclude=secrets --exclude=.env --exclude=bin --exclude=obj --exclude=TestResults -czf - . \
  | ssh root@76.13.1.231 'mkdir -p /opt/qrpro && tar --no-same-owner -xzf - -C /opt/qrpro'
ssh root@76.13.1.231 'cd /opt/qrpro \
  && mkdir -p secrets && chown 10001:10001 secrets && chmod 700 secrets \
  && cp .env.example .env && chmod 600 .env \
  && sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 24)/" .env \
  && docker compose up -d --build && docker compose ps'
```

Sonra `.env` içinde `CONTACT_EMAIL`'i doldurun (`docker compose up -d` ile uygulanır). `POSTGRES_PASSWORD`'ü
veritabanı oluşturulduktan sonra değiştirmeyin: Postgres parolayı yalnızca ilk açılışta ayarlar (değiştirmek
gerekirse önce `docker compose exec postgres psql -U qrpro -d qrpro -c "ALTER USER qrpro PASSWORD '...'"`).

## Yeniden dağıtım

```sh
cd server
tar --exclude=secrets --exclude=.env --exclude=bin --exclude=obj --exclude=TestResults -czf - . \
  | ssh root@76.13.1.231 'tar --no-same-owner -xzf - -C /opt/qrpro'
ssh root@76.13.1.231 'cd /opt/qrpro && docker compose up -d --build && docker compose ps'
curl -s https://qrpro.safarahmancenkci.com/health
```

`secrets/` ve `.env` sunucuda kalır, kopyalama onlara dokunmaz. Veritabanı ve yedekler volume'lardadır;
`docker compose down` onları silmez (`down -v` siler, **kullanmayın**). Silinen dosyalar kopyalamayla gitmez;
eski dosya kalırsa elle silin (derlemeye yalnızca `QrPro.Api/` girer).

Yararlı komutlar (sunucuda, `/opt/qrpro` içinde):

```sh
docker compose logs -f api                      # günlükler
docker compose up -d                            # .env değişince (konteyner yeniden oluşturulur)
docker compose restart api                      # servis hesabı anahtarı değişince
docker compose exec postgres psql -U qrpro -d qrpro -c \
  "select token, status, reason, order_id, client_ip, updated_at from purchases order by updated_at desc limit 10"
docker compose exec postgres psql -U qrpro -d qrpro -c \
  "delete from purchases where order_id = 'GPA....'"   # silme talebi
```

## Yedekler ve geri dönme

`qrpro-backup` her gün 03:00 UTC'de `pg_dump --format=custom` ile `/backups/qrpro-YYYYmmdd-HHMMSS.dump` yazar,
14 günden eskileri siler; açılışta son 24 saatte yedek yoksa hemen bir tane alır.

```sh
docker compose exec backup ls -lh /backups                       # yedekleri listele
docker compose exec backup sh -c 'pg_dump --format=custom --file=/backups/qrpro-elle-$(date -u +%Y%m%d-%H%M%S).dump'
docker compose logs --tail 20 backup                             # son yedek kayıtları
docker cp qrpro-backup:/backups/qrpro-20261124-030000.dump .     # sunucuya kopyala
```

Bir yedekten geri dönme (veritabanının bütün içeriği yedektekiyle değişir):

```sh
cd /opt/qrpro
docker compose stop api
docker compose exec -T postgres psql -U qrpro -d postgres \
  -c 'DROP DATABASE qrpro WITH (FORCE)' -c 'CREATE DATABASE qrpro OWNER qrpro'
docker compose exec -T backup pg_restore --no-owner --dbname=qrpro /backups/qrpro-20261124-030000.dump
docker compose start api
docker compose exec postgres psql -U qrpro -d qrpro -c 'select count(*) from purchases'
```

Yedek volume'u aynı sunucudadır; disk kaybına karşı ara sıra bir yedeği sunucu dışına kopyalayın (`docker cp` + `scp`).

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
3. **Anahtarı sunucuya koyun** (konteyner uid 10001 ile çalışır, klasör ona okunur olmalı; salt okunur bağlanır):

   ```sh
   scp play-service-account.json root@76.13.1.231:/opt/qrpro/secrets/play-service-account.json
   ssh root@76.13.1.231 'cd /opt/qrpro \
     && chown -R 10001:10001 secrets && chmod 700 secrets && chmod 600 secrets/play-service-account.json \
     && docker compose restart api'
   ```

4. Kontrol: `docker compose logs --tail 20 api` içinde "Servis hesabı anahtarı bulundu" yazmalı. Uygulamadan
   gerçek bir satın alma (lisans test hesabıyla) `valid:true` döndürmeli. Anahtar bozuksa yanıt
   `service_account_unreadable`, Google belirteç vermiyorsa `google_auth_failed` olur.

## nginx ve TLS

`/etc/nginx/sites-available/qrpro` (bağlantı `sites-enabled/qrpro`) `qrpro.safarahmancenkci.com` ve
`qrpro.76-13-1-231.sslip.io` adlarını `127.0.0.1:4400`'e aktarır; sertifika `certbot --nginx` ile alındı ve
kendiliğinden yenilenir, HTTP → HTTPS yönlendirilir. `qrpro.safarahmancenkci.com` için Hostinger DNS'te `qrpro` →
`76.13.1.231` A kaydı gerekir. nginx dosyasını değiştirdikten sonra her zaman `nginx -t && systemctl reload nginx`.

## Geliştirme ve testler

.NET SDK 10 ve Docker gerekir (testler Testcontainers ile geçici bir `postgres:17-alpine` açar; Google çağrıları
`IPlayPublisher` arayüzü arkasında taklit edilir).

```sh
cd server
dotnet test
```

Şema değişikliği: `QrPro.Api/Data/QrProDbContext.cs`'i değiştirip yeni migration ekleyin
(`dotnet tool install -g dotnet-ef` bir kez):

```sh
cd server
ConnectionStrings__Postgres="Host=localhost;Database=x;Username=x;Password=x" \
  dotnet ef migrations add <Ad> -p QrPro.Api -o Data/Migrations
```

Yerelde çalıştırma: `.env.example`'ı `.env` olarak kopyalayıp `POSTGRES_PASSWORD` verin, `docker compose up -d --build`
(API `http://127.0.0.1:4400`).
