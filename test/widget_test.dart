// Uygulama da material.dart kullanıyor; material_ui'ye geçiş ayrı iş.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qr_pro_app/main.dart';
import 'package:qr_pro_app/viewmodels/locale_viewmodel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Uygulamayı verilen cihaz diliyle başlatır. Kamera önizlemesi takılabildiği
  /// için pumpAndSettle yerine tek pump.
  Future<void> pumpApp(
    WidgetTester tester, {
    required Locale deviceLocale,
    AppLanguage? savedLanguage,
  }) async {
    tester.platformDispatcher.localesTestValue = [deviceLocale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      savedLanguage == null
          ? const ProviderScope(child: QrProApp())
          : ProviderScope(
              overrides: [
                initialAppLanguageProvider.overrideWithValue(savedLanguage),
              ],
              child: const QrProApp(),
            ),
    );
    await tester.pump();
  }

  void expectTabs(List<String> labels) {
    for (final label in labels) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'sekme: $label',
      );
    }
  }

  String appTitle(WidgetTester tester) =>
      tester.widget<Title>(find.byType(Title)).title;

  const trTabs = ['Tara', 'Oluştur', 'Geçmiş', 'Ayarlar'];
  const enTabs = ['Scan', 'Create', 'History', 'Settings'];

  testWidgets('App boots in Turkish (locale: tr)', (tester) async {
    await pumpApp(tester, deviceLocale: const Locale('tr'));

    expectTabs(trTabs);
    expect(appTitle(tester), 'QR Kod Okuyucu');
  });

  testWidgets('App boots in English (locale: en)', (tester) async {
    await pumpApp(tester, deviceLocale: const Locale('en'));

    expectTabs(enTabs);
    expect(appTitle(tester), 'QR Code Reader');
  });

  testWidgets('Unsupported device language falls back to English', (
    tester,
  ) async {
    await pumpApp(tester, deviceLocale: const Locale('de'));

    expectTabs(enTabs);
  });

  testWidgets('Saved language overrides the device language', (tester) async {
    await pumpApp(
      tester,
      deviceLocale: const Locale('en'),
      savedLanguage: AppLanguage.tr,
    );

    expectTabs(trTabs);
  });

  testWidgets('Choosing English in Settings switches the UI language', (
    tester,
  ) async {
    await pumpApp(tester, deviceLocale: const Locale('tr'));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ayarlar'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Dil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expectTabs(enTabs);
    expect(find.text('Language'), findsOneWidget);
    expect(await LocaleViewModel.loadSaved(), AppLanguage.en);
  });

  test('Language choice is persisted and restored', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(localeViewModelProvider.notifier);

    expect(await LocaleViewModel.loadSaved(), AppLanguage.system);

    await notifier.setLanguage(AppLanguage.en);
    expect(container.read(localeViewModelProvider), AppLanguage.en);
    expect(await LocaleViewModel.loadSaved(), AppLanguage.en);

    await notifier.setLanguage(AppLanguage.system);
    expect(await LocaleViewModel.loadSaved(), AppLanguage.system);
  });
}
