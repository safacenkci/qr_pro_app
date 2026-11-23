import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../services/premium_service.dart';
import '../services/url_service.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);
    final isPremium = premium.isPremium;
    final price = premium.product?.price;
    final version = ref.watch(_packageInfoProvider).whenOrNull(
          data: (info) => '${info.version} (${info.buildNumber})',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(isPremium ? Icons.workspace_premium : Icons.lock),
              title: Text(isPremium ? 'Premium Aktif' : 'Ücretsiz Plan'),
              subtitle: Text(
                isPremium
                    ? 'Tüm premium özellikler açık. Teşekkürler!'
                    : 'Renk, logo, toplu tarama ve CSV dışa aktarma Premium ile açılır.',
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
                      'Premium',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Tek seferlik ödeme, abonelik yok.'),
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
                        price == null ? "Pro'ya Geç" : "Pro'ya Geç · $price",
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: premium.busy ? null : notifier.restore,
                      child: const Text('Satın Alımı Geri Yükle'),
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
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Gizlilik Politikası'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => ref
                      .read(urlServiceProvider)
                      .openExternal(AppConfig.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sürüm'),
                  subtitle: Text(version ?? '…'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
