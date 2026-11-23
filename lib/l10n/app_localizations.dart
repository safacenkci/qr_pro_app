// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulama adı (görev değiştiricide görünen başlık).
  ///
  /// In tr, this message translates to:
  /// **'QR Kod Okuyucu'**
  String get appTitle;

  /// Alt gezinme çubuğu: tarama sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Tara'**
  String get navScan;

  /// Alt gezinme çubuğu: QR oluşturma sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get navGenerate;

  /// Alt gezinme çubuğu: geçmiş sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get navHistory;

  /// Alt gezinme çubuğu: ayarlar sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// Değeri panoya kopyalama düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// Panoya kopyalandıktan sonraki bildirim.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get copied;

  /// Paylaşma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// Diyaloğu kapatma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// Premium tanıtım diyaloğundaki satın alma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Premium Al'**
  String get getPremium;

  /// Kamera ekranındaki mod etiketi: tekli tarama.
  ///
  /// In tr, this message translates to:
  /// **'Tarama'**
  String get scanModeSingle;

  /// Kamera ekranındaki mod etiketi: toplu tarama ve listedeki kod sayısı.
  ///
  /// In tr, this message translates to:
  /// **'Toplu ({count})'**
  String scanModeBatch(int count);

  /// Fener düğmesinin ipucu: fener açıkken.
  ///
  /// In tr, this message translates to:
  /// **'Fener açık'**
  String get torchOn;

  /// Fener düğmesinin ipucu: fener kapalıyken.
  ///
  /// In tr, this message translates to:
  /// **'Fener kapalı'**
  String get torchOff;

  /// Galeriden görsel seçip QR okuma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Tara'**
  String get scanFromGallery;

  /// Toplu tarama modunu başlatan düğme.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Tarama'**
  String get batchScanStart;

  /// Toplu tarama modunu durduran düğme.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Durdur'**
  String get batchScanStop;

  /// Toplu tarama için Premium diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Tarama (Premium)'**
  String get batchScanPremiumTitle;

  /// Toplu tarama için Premium diyaloğunun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Toplu tarama ile art arda QR kod okuyup listeye ekleyebilirsin.'**
  String get batchScanPremiumDescription;

  /// Galeriden seçilen görselde QR kod yoksa.
  ///
  /// In tr, this message translates to:
  /// **'Görselden QR kod bulunamadı.'**
  String get scanNoQrInImage;

  /// QR bulundu ama içeriği okunamadıysa.
  ///
  /// In tr, this message translates to:
  /// **'QR kod okunamadı.'**
  String get scanQrUnreadable;

  /// Cihaz görselden tarama yapamıyorsa.
  ///
  /// In tr, this message translates to:
  /// **'Görsel tarama desteklenmiyor.'**
  String get scanImageUnsupported;

  /// Tarama sonucu alt sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç'**
  String get scanResultTitle;

  /// Wi‑Fi QR kodundaki ağa bağlanma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi’ye Bağlan'**
  String get wifiConnect;

  /// Wi‑Fi bağlantısı başlatıldıktan sonraki bildirim.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı denendi. Bağlandıysa bildirim çubuğunda görürsün.'**
  String get wifiConnectAttempted;

  /// Wi‑Fi bağlantısı başarısız olduğunda.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi açılamadı/bağlanılamadı. Panel açıldıysa Wi‑Fi’yi açıp geri dön.'**
  String get wifiConnectFailed;

  /// Wi‑Fi QR görseli paylaşılamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi QR paylaşımı başarısız oldu'**
  String get wifiShareFailed;

  /// Wi‑Fi QR görseli paylaşılırken eklenen metin.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi QR'**
  String get wifiQrShareText;

  /// Bağlantı tarayıcıda açılamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Link açılamadı'**
  String get linkOpenFailed;

  /// Bağlantıyı tarayıcıda açma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get open;

  /// Toplu taramada okunan kodların listesi başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Liste'**
  String get batchListTitle;

  /// Toplu listeyi temizleme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// Toplu liste boşken.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir şey eklenmedi. QR kod okutmaya devam et.'**
  String get batchListEmpty;

  /// QR oluşturma ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get generateTitle;

  /// QR içerik türü seçiminin başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get generateType;

  /// İçerik türü: düz metin.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get generateTypeText;

  /// İçerik türü: web adresi.
  ///
  /// In tr, this message translates to:
  /// **'URL'**
  String get generateTypeUrl;

  /// İçerik türü: Wi‑Fi ağı.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi'**
  String get generateTypeWifi;

  /// QR önizleme kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get generatePreview;

  /// Renk ve logoyu kaldıran düğmenin ipucu.
  ///
  /// In tr, this message translates to:
  /// **'Sadeleştir'**
  String get generateResetCustomization;

  /// Oluşturulan QR'ı geçmişe ekleme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişe Ekle'**
  String get addToHistory;

  /// QR geçmişe eklendikten sonraki bildirim.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişe eklendi'**
  String get addedToHistory;

  /// QR görselini galeriye kaydetme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// Renk ve logo seçeneklerinin başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Özelleştirme'**
  String get generateCustomization;

  /// QR rengini seçme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Renk'**
  String get color;

  /// Renk seçimi için Premium diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Renk Değiştirme (Premium)'**
  String get colorPremiumTitle;

  /// Renk seçimi için Premium diyaloğunun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'QR rengini değiştirmek Premium özellik.'**
  String get colorPremiumDescription;

  /// QR ortasına logo ekleme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Logo Ekle'**
  String get addLogo;

  /// Logo ekleme için Premium diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Logo Ekleme (Premium)'**
  String get logoPremiumTitle;

  /// Logo ekleme için Premium diyaloğunun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'QR kodun ortasına logo eklemek Premium özellik.'**
  String get logoPremiumDescription;

  /// Renk seçme diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'QR Rengi Seç'**
  String get pickQrColor;

  /// QR görseli galeriye kaydedildiğinde.
  ///
  /// In tr, this message translates to:
  /// **'Galeriye kaydedildi'**
  String get savedToGallery;

  /// QR görseli galeriye kaydedilemediğinde.
  ///
  /// In tr, this message translates to:
  /// **'Galeriye kaydedilemedi'**
  String get saveToGalleryFailed;

  /// Kaydetme sırasında beklenmeyen hata.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme başarısız oldu'**
  String get saveFailed;

  /// QR görseli paylaşılırken eklenen metin.
  ///
  /// In tr, this message translates to:
  /// **'QR Kod'**
  String get qrShareText;

  /// Paylaşma sırasında hata.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşma başarısız oldu'**
  String get shareFailed;

  /// Metin alanının etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get generateTextLabel;

  /// Metin alanının örnek ipucu.
  ///
  /// In tr, this message translates to:
  /// **'Örn. “Merhaba Dünya”'**
  String get generateTextHint;

  /// Web adresi alanının etiketi.
  ///
  /// In tr, this message translates to:
  /// **'URL'**
  String get generateUrlLabel;

  /// Wi‑Fi ağ adı (SSID) alanının etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Wi‑Fi Adı'**
  String get wifiSsidLabel;

  /// Wi‑Fi şifresi alanının etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get wifiPasswordLabel;

  /// Wi‑Fi güvenlik türü seçiminin etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get wifiSecurityLabel;

  /// Wi‑Fi güvenlik türü: WPA3 Personal.
  ///
  /// In tr, this message translates to:
  /// **'WPA3‑Kişisel (SAE)'**
  String get wifiAuthWpa3;

  /// Wi‑Fi güvenlik türü: açık ağ, şifre yok.
  ///
  /// In tr, this message translates to:
  /// **'Şifresiz'**
  String get wifiAuthNone;

  /// Geçmiş ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get historyTitle;

  /// Geçmişi CSV olarak dışa aktarma düğmesinin ipucu.
  ///
  /// In tr, this message translates to:
  /// **'CSV İndir'**
  String get exportCsv;

  /// Ücretsiz planda CSV dışa aktarma düğmesinin ipucu.
  ///
  /// In tr, this message translates to:
  /// **'CSV İndir (Premium)'**
  String get exportCsvPremium;

  /// CSV dosyası paylaşılırken eklenen metin.
  ///
  /// In tr, this message translates to:
  /// **'QR geçmişim (CSV)'**
  String get csvShareText;

  /// CSV dışa aktarılamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarma başarısız'**
  String get exportFailed;

  /// Bütün geçmişi silme menü öğesi.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Sil'**
  String get deleteAll;

  /// Bütün geçmiş silindikten sonraki bildirim.
  ///
  /// In tr, this message translates to:
  /// **'Tüm geçmiş silindi'**
  String get historyCleared;

  /// Geçmiş yüklenemediğinde gösterilen hata.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorWithDetail(String error);

  /// Geçmiş boşken.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir geçmiş yok.'**
  String get historyEmpty;

  /// Geçmiş öğesinin alt satırı: kaydın türü (scanned = taranan, generated = oluşturulan) ve tarihi.
  ///
  /// In tr, this message translates to:
  /// **'{type, select, scanned{Okutuldu} other{Oluşturuldu}} • {date}'**
  String historyItemSubtitle(String type, String date);

  /// Geçmiş öğesindeki bağlantıyı açma menü öğesi.
  ///
  /// In tr, this message translates to:
  /// **'Linki Aç'**
  String get openLink;

  /// Geçmiş öğesini silme menü öğesi.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// Geçmiş öğesi silindikten sonraki bildirim.
  ///
  /// In tr, this message translates to:
  /// **'Silindi'**
  String get deleted;

  /// CSV dışa aktarma için Premium diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'CSV Dışa Aktarma (Premium)'**
  String get csvPremiumTitle;

  /// CSV dışa aktarma için Premium diyaloğunun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi CSV/Excel olarak indirmek Premium özellik.'**
  String get csvPremiumDescription;

  /// Ayarlar ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// Premium sahibinin plan başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Premium Aktif'**
  String get premiumActive;

  /// Premium sahibinin plan açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Tüm premium özellikler açık. Teşekkürler!'**
  String get premiumActiveDescription;

  /// Ücretsiz kullanıcının plan başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Plan'**
  String get freePlan;

  /// Ücretsiz kullanıcının plan açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Renk, logo, toplu tarama ve CSV dışa aktarma Premium ile açılır.'**
  String get freePlanDescription;

  /// Premium satın alma kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// Premium satın alma kartının açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Tek seferlik ödeme, abonelik yok.'**
  String get premiumOneTimePayment;

  /// Fiyat bilinmezken satın alma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Pro\'ya Geç'**
  String get upgradeToPro;

  /// Satın alma düğmesi; fiyat mağazadan biçimlenmiş gelir.
  ///
  /// In tr, this message translates to:
  /// **'Pro\'ya Geç · {price}'**
  String upgradeToProWithPrice(String price);

  /// Önceki satın alımı geri yükleme düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Satın Alımı Geri Yükle'**
  String get restorePurchase;

  /// Gizlilik politikasını açan satır.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// Uygulama sürümü satırı.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get version;

  /// Dil seçimi satırının ve diyaloğunun başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// Dil seçeneği: cihaz dilini kullan.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get languageSystem;

  /// Satın alma akışından hata geldiğinde.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma sırasında bir hata oluştu.'**
  String get premiumMsgPurchaseError;

  /// Mağaza ya da ürün bilgisi kullanılamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Google Play mağazasına şu anda ulaşılamıyor. Lütfen daha sonra tekrar deneyin.'**
  String get premiumMsgStoreUnavailable;

  /// Satın alma ekranı açılamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma başlatılamadı.'**
  String get premiumMsgPurchaseStartFailed;

  /// Geri yükleme başarılı olduğunda.
  ///
  /// In tr, this message translates to:
  /// **'Premium geri yüklendi.'**
  String get premiumMsgRestored;

  /// Geri yüklenecek satın alım bulunamadığında.
  ///
  /// In tr, this message translates to:
  /// **'Bu Google hesabında Premium satın alımı bulunamadı.'**
  String get premiumMsgNothingToRestore;

  /// Geri yükleme sırasında hata.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme başarısız.'**
  String get premiumMsgRestoreFailed;

  /// Ödeme beklemede olduğunda.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme onayı bekleniyor…'**
  String get premiumMsgPaymentPending;

  /// Mağaza satın almayı hata ile bitirdiğinde.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı.'**
  String get premiumMsgPurchaseFailed;

  /// Satın alma doğrulanıp Premium açıldığında.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler! Premium aktif.'**
  String get premiumMsgPurchaseSuccess;

  /// Sunucu satın almayı geçersiz saydığında.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma doğrulanamadı.'**
  String get premiumMsgVerificationFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
