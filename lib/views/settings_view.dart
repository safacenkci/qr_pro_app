import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../services/url_service.dart';
import '../viewmodels/locale_viewmodel.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(localeViewModelProvider);
    final premium = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);
    final isPremium = premium.isPremium;
    final price = premium.product?.price;
    final version = ref.watch(_packageInfoProvider).whenOrNull(
          data: (info) => '${info.version} (${info.buildNumber})',
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(isPremium ? Icons.workspace_premium : Icons.lock),
              title: Text(isPremium ? l10n.premiumActive : l10n.freePlan),
              subtitle: Text(
                isPremium
                    ? l10n.premiumActiveDescription
                    : l10n.freePlanDescription,
              ),
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.premiumTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.premiumOneTimePayment),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: premium.busy ? null : notifier.buy,
                      icon: premium.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.workspace_premium),
                      label: Text(
                        price == null
                            ? l10n.upgradeToPro
                            : l10n.upgradeToProWithPrice(price),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: premium.busy ? null : notifier.restore,
                      child: Text(l10n.restorePurchase),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  subtitle: Text(_languageLabel(l10n, language)),
                  onTap: () => _pickLanguage(context, ref, language),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => ref
                      .read(urlServiceProvider)
                      .openExternal(AppConfig.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.version),
                  subtitle: Text(version ?? '…'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dil adları kendi dillerinde yazılır (Türkçe / English); böylece yanlış
  /// dile geçen kullanıcı da kendi dilini bulur.
  static String _languageLabel(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.tr => 'Türkçe',
      AppLanguage.en => 'English',
    };
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          RadioGroup<AppLanguage>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(_languageLabel(l10n, language)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    await ref.read(localeViewModelProvider.notifier).setLanguage(selected);
  }
}
