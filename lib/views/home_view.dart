import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../viewmodels/navigation_viewmodel.dart';
import 'generate_view.dart';
import 'history_view.dart';
import 'scan_view.dart';
import 'settings_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static const _pages = <Widget>[
    ScanView(),
    GenerateView(),
    HistoryView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final l10n = AppLocalizations.of(context);

    // Satın alma sonuçlarını hangi sekmede olunursa olunsun göster.
    ref.listen<PremiumMessage?>(premiumProvider.select((s) => s.message), (
      _,
      msg,
    ) {
      if (msg == null) return;
      final text = _premiumMessageText(AppLocalizations.of(context), msg);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
      ref.read(premiumProvider.notifier).clearMessage();
    });

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(navigationIndexProvider.notifier).setIndex(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: l10n.navScan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_2_outlined),
            selectedIcon: const Icon(Icons.qr_code_2),
            label: l10n.navGenerate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }

  static String _premiumMessageText(AppLocalizations l10n, PremiumMessage msg) {
    return switch (msg) {
      PremiumMessage.purchaseError => l10n.premiumMsgPurchaseError,
      PremiumMessage.storeUnavailable => l10n.premiumMsgStoreUnavailable,
      PremiumMessage.purchaseStartFailed => l10n.premiumMsgPurchaseStartFailed,
      PremiumMessage.restored => l10n.premiumMsgRestored,
      PremiumMessage.nothingToRestore => l10n.premiumMsgNothingToRestore,
      PremiumMessage.restoreFailed => l10n.premiumMsgRestoreFailed,
      PremiumMessage.paymentPending => l10n.premiumMsgPaymentPending,
      PremiumMessage.purchaseFailed => l10n.premiumMsgPurchaseFailed,
      PremiumMessage.purchaseSuccess => l10n.premiumMsgPurchaseSuccess,
      PremiumMessage.verificationFailed =>
        l10n.premiumMsgVerificationFailed,
    };
  }
}
