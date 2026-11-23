/// Uygulama genelindeki sabit yapılandırma.
class AppConfig {
  AppConfig._();

  /// android/app/build.gradle.kts içindeki applicationId ile aynı olmalı.
  static const String packageName = 'com.safarahmancenkci.qrpro';

  /// Satın alma doğrulama ve gizlilik politikası sunucusu.
  static const String apiBaseUrl = 'https://qrpro.safarahmancenkci.com';

  /// Play Console'daki gizlilik politikası alanına da bu adres yazılır.
  static const String privacyPolicyUrl = '$apiBaseUrl/privacy';

  /// Play Console → Ürünler → Uygulama içi ürünler'de tanımlanan
  /// tek seferlik (yönetilen) ürünün kimliği.
  static const String premiumProductId = 'qr_pro_lifetime';
}
