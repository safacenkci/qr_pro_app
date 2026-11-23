import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/history_item.dart';
import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../services/url_service.dart';
import '../utils/validators.dart';
import '../utils/wifi_qr.dart';
import '../viewmodels/history_viewmodel.dart';
import '../widgets/premium_upsell_dialog.dart';

enum _HistoryAppAction { clearAll }

enum _HistoryItemAction { copy, share, open, delete }

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyViewModelProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final l10n = AppLocalizations.of(context);
    // Yerel ayara uygun kısa tarih ve saat (tr: 24.11.2026 14:05,
    // en: 11/24/2026 2:05 PM).
    final df = DateFormat.yMd(l10n.localeName).add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            tooltip: isPremium ? l10n.exportCsv : l10n.exportCsvPremium,
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
                      text: l10n.csvShareText,
                    );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.exportFailed)),
                );
              }
            },
          ),
          PopupMenuButton<void>(
            // NOTE: PopupMenuButton intentionally does NOT call onSelected
            // when the returned value is null. So we must use a non-null value.
            itemBuilder: (context) => [
              PopupMenuItem<_HistoryAppAction>(
                value: _HistoryAppAction.clearAll,
                child: Text(l10n.deleteAll),
              ),
            ],
            onSelected: (_) async {
              await ref.read(historyViewModelProvider.notifier).clearAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.historyCleared)),
              );
            },
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithDetail('$e'))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(l10n.historyEmpty),
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
                      l10n.historyItemSubtitle(
                        item.type.name,
                        df.format(item.createdAt),
                      ),
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
                              SnackBar(content: Text(l10n.copied)),
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
                              SnackBar(content: Text(l10n.deleted)),
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _HistoryItemAction.copy,
                          child: Text(l10n.copy),
                        ),
                        PopupMenuItem(
                          value: _HistoryItemAction.share,
                          child: Text(l10n.share),
                        ),
                        if (isUrl)
                          PopupMenuItem(
                            value: _HistoryItemAction.open,
                            child: Text(l10n.openLink),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _HistoryItemAction.delete,
                          child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => PremiumUpsellDialog(
        title: l10n.csvPremiumTitle,
        description: l10n.csvPremiumDescription,
        onUpgrade: () => ref.read(premiumProvider.notifier).buy(),
      ),
    );
  }
}


