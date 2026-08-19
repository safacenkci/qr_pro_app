import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);

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
                    ? 'Tüm premium özellikler açık.'
                    : 'Bazı özellikler Premium kilitli.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: isPremium
                        ? null
                        : () => ref
                            .read(premiumProvider.notifier)
                            .upgradeToPro(),
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(isPremium ? 'Premium Aktif' : "Pro'ya Geç (Test)"),
                  ),
                  const SizedBox(height: 10),
                  if (isPremium)
                    TextButton(
                      onPressed: () =>
                          ref.read(premiumProvider.notifier).resetForTesting(),
                      child: const Text('Premium’u Sıfırla (Test)'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Sürüm'),
              subtitle: Text('1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}


