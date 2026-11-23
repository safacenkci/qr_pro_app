import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının seçtiği uygulama dili. [system] cihaz dilini izler.
enum AppLanguage {
  system(null),
  tr('tr'),
  en('en');

  const AppLanguage(this.code);

  /// Saklanan dil kodu; [system] için null.
  final String? code;

  /// `MaterialApp.locale` için değer; null ise cihaz dili kullanılır.
  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (l) => l.code != null && l.code == code,
        orElse: () => AppLanguage.system,
      );
}

/// Uygulama açılırken saklanan dil. `main()` önceden okuyup bu sağlayıcıyı
/// ezer; böylece ilk karede yanlış dil görünmez. Ezilmezse cihaz dili.
final initialAppLanguageProvider = Provider<AppLanguage>(
  (ref) => AppLanguage.system,
);

class LocaleViewModel extends Notifier<AppLanguage> {
  static const _prefsKey = 'app_language_v1';

  @override
  AppLanguage build() => ref.read(initialAppLanguageProvider);

  /// Saklanan dil seçimini okur. Eklenti yoksa (test ortamı) cihaz dili.
  static Future<AppLanguage> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppLanguage.fromCode(prefs.getString(_prefsKey));
    } catch (_) {
      return AppLanguage.system;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = language.code;
      if (code == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, code);
      }
    } catch (_) {
      // Test ortamı veya eklenti yok: seçim yalnızca bu oturumda geçerli.
    }
  }
}

final localeViewModelProvider =
    NotifierProvider<LocaleViewModel, AppLanguage>(LocaleViewModel.new);
