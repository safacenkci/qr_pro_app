import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'utils/app_theme.dart';
import 'viewmodels/locale_viewmodel.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final language = await LocaleViewModel.loadSaved();
  runApp(
    ProviderScope(
      overrides: [initialAppLanguageProvider.overrideWithValue(language)],
      child: const QrProApp(),
    ),
  );
}

class QrProApp extends ConsumerWidget {
  const QrProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeViewModelProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // null: cihaz dili. Desteklenmeyen dillerde supportedLocales'in ilki
      // (en, bkz. l10n.yaml preferred-supported-locales) seçilir.
      locale: language.locale,
      // AppLocalizations + Material, Cupertino ve Widgets yerelleştirmeleri.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeView(),
    );
  }
}
