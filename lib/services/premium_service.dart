import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock Premium service. Replace later with real IAP integration.
class PremiumService extends Notifier<bool> {
  @override
  bool build() => false;

  bool get isPremium => state;

  void upgradeToPro() => state = true;

  void resetForTesting() => state = false;
}

final premiumProvider = NotifierProvider<PremiumService, bool>(PremiumService.new);


