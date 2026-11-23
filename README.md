# QR Kod Okuyucu (qr_pro_app)

QR kod tarama, oluşturma ve geçmiş yönetimi için bir Flutter uygulaması. Uygulama kimliği `com.safarahmancenkci.qrpro`.

- `lib/`: Flutter uygulaması (Riverpod, MVVM)
- `server/`: satın alma doğrulama API'si ve gizlilik politikası sayfası (Docker, `qrpro.76-13-1-231.sslip.io`)
- `store/`: Play Console görselleri (512×512 ikon, 1024×500 öne çıkan görsel)
- `tool/generate_store_assets.py`: ikon ve mağaza görsellerini yeniden üretir

## Geliştirme

```bash
flutter pub get
flutter run
```

İkonu değiştirdikten sonra şu komutları çalıştırın:

```bash
python tool/generate_store_assets.py
dart run flutter_launcher_icons
```

## Release derlemesi (Google Play)

1. `android/key.properties` ve `android/upload-keystore.jks` dosyaları git dışında tutulur. Yedekleri sunucuda
   `/root/qrpro-secrets/android-signing/` altındadır. Yeni bir makinede bu iki dosyayı aynı konuma kopyalayın
   (biçim için `android/key.properties.example` dosyasına bakın). Bu anahtar kaybolursa Play Console'dan
   "upload key reset" istemeniz gerekir.
2. Her yüklemeden önce `pubspec.yaml` içindeki `version: x.y.z+N` değerinde **N'yi artırın**.
3. Paketi derleyin:

   ```bash
   flutter build appbundle --release
   ```

   Çıktı `build/app/outputs/bundle/release/app-release.aab` dosyasıdır. `key.properties` yoksa paket debug
   anahtarıyla imzalanır, Play bu dosyayı kabul etmez.

## Play Console kontrol listesi

- **Uygulama imzalama:** Play App Signing'i açın. İlk `.aab` dosyasını yüklediğinizde upload anahtarı otomatik
  kaydedilir.
- **Uygulama içi ürün:** Para kazanma → Ürünler → Uygulama içi ürünler bölümünde **`qr_pro_lifetime`** kimlikli,
  tek seferlik bir ürün oluşturup etkinleştirin. Ürünler ancak uygulama bir test kanalına yüklendikten sonra
  görünür. Lisans testi için Ayarlar → Lisans testi bölümüne test hesaplarını ekleyin.
- **Sunucu doğrulaması:** Kurulum için `server/README.md` dosyasına bakın (servis hesabı ve API erişimi). Anahtar
  eklenene kadar sunucu satın almaları kaydeder ama "unverified" döner. Bu durumda uygulama Google Play'in
  sonucuna güvenir.
- **Gizlilik politikası URL'si:** `https://qrpro.76-13-1-231.sslip.io/privacy`
- **Reklam içeriyor mu:** Hayır.
- **İçerik derecelendirmesi:** Yardımcı program. Şiddet, kullanıcılar arası iletişim veya konum paylaşımı yok.
- **Hedef kitle:** 13 yaş ve üzeri önerilir (çocuklara yönelik değil).
- **Kapalı test:** Yeni kişisel hesaplarda, üretime çıkmadan önce en az 12 test kullanıcısıyla 14 gün kapalı
  test zorunludur.

### Veri güvenliği formu için yanıtlar

| Soru | Yanıt |
|---|---|
| Veri topluyor veya paylaşıyor mu? | Evet, yalnızca satın alma bilgisi |
| Toplanan veri türü | Finansal bilgiler → **Satın alma geçmişi** (Play satın alma jetonu, ürün kimliği, sipariş no.) |
| Amaç | Uygulama işlevselliği (satın almayı doğrulama), dolandırıcılık önleme |
| Üçüncü taraflarla paylaşılıyor mu? | Hayır |
| İsteğe bağlı mı? | Evet (yalnızca Premium satın alanlar) |
| Aktarım sırasında şifreleniyor mu? | Evet (HTTPS) |
| Silme talebi | Gizlilik politikasındaki iletişim adresi üzerinden |
| Konum | **Toplanmaz.** İzin yalnızca Android 12 ve altında, Wi‑Fi QR'ı ile ağa bağlanırken sistem gerektirdiği için istenir. Veri cihazdan çıkmaz. |
| Fotoğraflar / kamera | **Toplanmaz.** Görüntüler cihazda işlenir. Galeriden seçim sistemin fotoğraf seçicisiyle yapılır. |
| Tarama geçmişi | **Toplanmaz.** Yalnızca cihazda saklanır. |
