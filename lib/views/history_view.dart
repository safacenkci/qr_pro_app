import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../services/url_service.dart';
import '../utils/validators.dart';
import '../utils/wifi_qr.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/history_viewmodel.dart';
import '../widgets/premium_upsell_dialog.dart';

enum _HistoryAppAction { clearAll }

enum _HistoryItemAction { copy, share, open, delete }

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyViewModelProvider);
    final isPremium = ref.watch(premiumProvider);
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          IconButton(
            tooltip: isPremium ? 'CSV İndir' : 'CSV İndir (Premium)',
            icon: Icon(isPremium ? Icons.download : Icons.lock_outline),
            onPressed: () async {
              if (!isPremium) {
                _showPremiumDialog(context, ref);
                return;
              }
              try {
                final file =
                    await ref.read(historyViewModelProvider.notifier).exportCsv();
                await ref.read(shareServiceProvider).shareFile(
                      file,
                      text: 'QR geçmişim (CSV)',
                    );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dışa aktarma başarısız')),
                );
              }
            },
          ),
          PopupMenuButton<void>(
            // NOTE: PopupMenuButton intentionally does NOT call onSelected
            // when the returned value is null. So we must use a non-null value.
            itemBuilder: (context) => const [
              PopupMenuItem<_HistoryAppAction>(
                value: _HistoryAppAction.clearAll,
                child: Text('Tümünü Sil'),
              ),
            ],
            onSelected: (_) async {
              await ref.read(historyViewModelProvider.notifier).clearAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tüm geçmiş silindi')),
              );
            },
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Henüz bir geçmiş yok.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              final isUrl = Validators.looksLikeUrl(item.value);
              final wifi = WifiQr.parse(item.value);
              final titleText = wifi?.ssid ?? item.value;

              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) async {
                  await ref
                      .read(historyViewModelProvider.notifier)
                      .deleteById(item.id);
                },
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      item.type == HistoryItemType.scanned
                          ? Icons.qr_code_scanner
                          : Icons.qr_code_2,
                    ),
                    title: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.type == HistoryItemType.scanned ? "Okutuldu" : "Oluşturuldu"} • ${df.format(item.createdAt)}',
                    ),
                    trailing: PopupMenuButton<_HistoryItemAction>(
                      onSelected: (action) async {
                        switch (action) {
                          case _HistoryItemAction.copy:
                            await Clipboard.setData(
                              ClipboardData(text: item.value),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kopyalandı')),
                            );
                            break;
                          case _HistoryItemAction.share:
                            await ref
                                .read(shareServiceProvider)
                                .shareText(item.value);
                            break;
                          case _HistoryItemAction.open:
                            if (isUrl) {
                              await ref
                                  .read(urlServiceProvider)
                                  .openExternal(item.value);
                            }
                            break;
                          case _HistoryItemAction.delete:
                            await ref
                                .read(historyViewModelProvider.notifier)
                                .deleteById(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Silindi')),
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _HistoryItemAction.copy,
                          child: Text('Kopyala'),
                        ),
                        const PopupMenuItem(
                          value: _HistoryItemAction.share,
                          child: Text('Paylaş'),
                        ),
                        if (isUrl)
                          const PopupMenuItem(
                            value: _HistoryItemAction.open,
                            child: Text('Linki Aç'),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: _HistoryItemAction.delete,
                          child: Text('Sil'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => PremiumUpsellDialog(
        title: 'CSV Dışa Aktarma (Premium)',
        description: 'Geçmişi CSV/Excel olarak indirmek Premium özellik.',
        onUpgrade: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
      ),
    );
  }
}


