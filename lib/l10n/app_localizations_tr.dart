// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'QR Kod Okuyucu';

  @override
  String get navScan => 'Tara';

  @override
  String get navGenerate => 'Oluştur';

  @override
  String get navHistory => 'Geçmiş';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get share => 'Paylaş';

  @override
  String get close => 'Kapat';

  @override
  String get getPremium => 'Premium Al';

  @override
  String get scanModeSingle => 'Tarama';

  @override
  String scanModeBatch(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Toplu ($countString)';
  }

  @override
  String get torchOn => 'Fener açık';

  @override
  String get torchOff => 'Fener kapalı';

  @override
  String get scanFromGallery => 'Galeriden Tara';

  @override
  String get batchScanStart => 'Toplu Tarama';

  @override
  String get batchScanStop => 'Toplu Durdur';

  @override
  String get batchScanPremiumTitle => 'Toplu Tarama (Premium)';

  @override
  String get batchScanPremiumDescription =>
      'Toplu tarama ile art arda QR kod okuyup listeye ekleyebilirsin.';

  @override
  String get scanNoQrInImage => 'Görselden QR kod bulunamadı.';

  @override
  String get scanQrUnreadable => 'QR kod okunamadı.';

  @override
  String get scanImageUnsupported => 'Görsel tarama desteklenmiyor.';

  @override
  String get scanResultTitle => 'Sonuç';

  @override
  String get wifiConnect => 'Wi‑Fi’ye Bağlan';

  @override
  String get wifiConnectAttempted =>
      'Bağlantı denendi. Bağlandıysa bildirim çubuğunda görürsün.';

  @override
  String get wifiConnectFailed =>
      'Wi‑Fi açılamadı/bağlanılamadı. Panel açıldıysa Wi‑Fi’yi açıp geri dön.';

  @override
  String get wifiShareFailed => 'Wi‑Fi QR paylaşımı başarısız oldu';

  @override
  String get wifiQrShareText => 'Wi‑Fi QR';

  @override
  String get linkOpenFailed => 'Link açılamadı';

  @override
  String get open => 'Aç';

  @override
  String get batchListTitle => 'Toplu Liste';

  @override
  String get clear => 'Temizle';

  @override
  String get batchListEmpty =>
      'Henüz bir şey eklenmedi. QR kod okutmaya devam et.';

  @override
  String get generateTitle => 'Oluştur';

  @override
  String get generateType => 'Tür';

  @override
  String get generateTypeText => 'Metin';

  @override
  String get generateTypeUrl => 'URL';

  @override
  String get generateTypeWifi => 'Wi‑Fi';

  @override
  String get generatePreview => 'Önizleme';

  @override
  String get generateResetCustomization => 'Sadeleştir';

  @override
  String get addToHistory => 'Geçmişe Ekle';

  @override
  String get addedToHistory => 'Geçmişe eklendi';

  @override
  String get save => 'Kaydet';

  @override
  String get generateCustomization => 'Özelleştirme';

  @override
  String get color => 'Renk';

  @override
  String get colorPremiumTitle => 'Renk Değiştirme (Premium)';

  @override
  String get colorPremiumDescription =>
      'QR rengini değiştirmek Premium özellik.';

  @override
  String get addLogo => 'Logo Ekle';

  @override
  String get logoPremiumTitle => 'Logo Ekleme (Premium)';

  @override
  String get logoPremiumDescription =>
      'QR kodun ortasına logo eklemek Premium özellik.';

  @override
  String get pickQrColor => 'QR Rengi Seç';

  @override
  String get savedToGallery => 'Galeriye kaydedildi';

  @override
  String get saveToGalleryFailed => 'Galeriye kaydedilemedi';

  @override
  String get saveFailed => 'Kaydetme başarısız oldu';

  @override
  String get qrShareText => 'QR Kod';

  @override
  String get shareFailed => 'Paylaşma başarısız oldu';

  @override
  String get generateTextLabel => 'Metin';

  @override
  String get generateTextHint => 'Örn. “Merhaba Dünya”';

  @override
  String get generateUrlLabel => 'URL';

  @override
  String get wifiSsidLabel => 'Wi‑Fi Adı';

  @override
  String get wifiPasswordLabel => 'Şifre';

  @override
  String get wifiSecurityLabel => 'Güvenlik';

  @override
  String get wifiAuthWpa3 => 'WPA3‑Kişisel (SAE)';

  @override
  String get wifiAuthNone => 'Şifresiz';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get exportCsv => 'CSV İndir';

  @override
  String get exportCsvPremium => 'CSV İndir (Premium)';

  @override
  String get csvShareText => 'QR geçmişim (CSV)';

  @override
  String get exportFailed => 'Dışa aktarma başarısız';

  @override
  String get deleteAll => 'Tümünü Sil';

  @override
  String get historyCleared => 'Tüm geçmiş silindi';

  @override
  String errorWithDetail(String error) {
    return 'Hata: $error';
  }

  @override
  String get historyEmpty => 'Henüz bir geçmiş yok.';

  @override
  String historyItemSubtitle(String type, String date) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'scanned': 'Okutuldu',
      'other': 'Oluşturuldu',
    });
    return '$_temp0 • $date';
  }

  @override
  String get openLink => 'Linki Aç';

  @override
  String get delete => 'Sil';

  @override
  String get deleted => 'Silindi';

  @override
  String get csvPremiumTitle => 'CSV Dışa Aktarma (Premium)';

  @override
  String get csvPremiumDescription =>
      'Geçmişi CSV/Excel olarak indirmek Premium özellik.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get premiumActive => 'Premium Aktif';

  @override
  String get premiumActiveDescription =>
      'Tüm premium özellikler açık. Teşekkürler!';

  @override
  String get freePlan => 'Ücretsiz Plan';

  @override
  String get freePlanDescription =>
      'Renk, logo, toplu tarama ve CSV dışa aktarma Premium ile açılır.';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumOneTimePayment => 'Tek seferlik ödeme, abonelik yok.';

  @override
  String get upgradeToPro => 'Pro\'ya Geç';

  @override
  String upgradeToProWithPrice(String price) {
    return 'Pro\'ya Geç · $price';
  }

  @override
  String get restorePurchase => 'Satın Alımı Geri Yükle';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get version => 'Sürüm';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get premiumMsgPurchaseError => 'Satın alma sırasında bir hata oluştu.';

  @override
  String get premiumMsgStoreUnavailable =>
      'Google Play mağazasına şu anda ulaşılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get premiumMsgPurchaseStartFailed => 'Satın alma başlatılamadı.';

  @override
  String get premiumMsgRestored => 'Premium geri yüklendi.';

  @override
  String get premiumMsgNothingToRestore =>
      'Bu Google hesabında Premium satın alımı bulunamadı.';

  @override
  String get premiumMsgRestoreFailed => 'Geri yükleme başarısız.';

  @override
  String get premiumMsgPaymentPending => 'Ödeme onayı bekleniyor…';

  @override
  String get premiumMsgPurchaseFailed => 'Satın alma tamamlanamadı.';

  @override
  String get premiumMsgPurchaseSuccess => 'Teşekkürler! Premium aktif.';

  @override
  String get premiumMsgVerificationFailed => 'Satın alma doğrulanamadı.';
}
