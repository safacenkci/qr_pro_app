import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

@immutable
class PremiumState {
  const PremiumState({
    this.isPremium = false,
    this.storeAvailable = false,
    this.product,
    this.busy = false,
    this.message,
  });

  final bool isPremium;
  final bool storeAvailable;
  final ProductDetails? product;
  final bool busy;

  /// Kullanıcıya bir kez gösterilecek bilgi/hata mesajı.
  final String? message;

  PremiumState copyWith({
    bool? isPremium,
    bool? storeAvailable,
    ProductDetails? product,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      product: product ?? this.product,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Google Play Billing üzerinden tek seferlik "Pro" satın alımı.
///
/// Satın alma sunucuda doğrulanır (bkz. `server/`). Sunucu satın almayı açıkça
/// geçersiz sayarsa premium verilmez. Sunucuya ulaşılamazsa ya da sunucu
/// doğrulama yapamıyorsa Google Play'in bildirdiği sonuca güvenilir; böylece
/// ödeme yapan kullanıcı sunucu kesintisinde kilitli kalmaz.
class PremiumService extends Notifier<PremiumState> {
  static const _prefsKey = 'premium_unlocked_v1';

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;

  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  PremiumState build() {
    ref.onDispose(() => _sub?.cancel());
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_init);
    }
    return const PremiumState();
  }

  bool get _supportsBilling =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKey) ?? false) {
        state = state.copyWith(isPremium: true);
      }
    } catch (_) {
      // Test ortamı veya eklenti yok: yok say.
    }

    if (!_supportsBilling) return;

    try {
      final available = await _iap.isAvailable();
      state = state.copyWith(storeAvailable: available);
      if (!available) return;

      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          state = state.copyWith(busy: false, message: 'Satın alma hatası: $e');
        },
      );

      final resp = await _iap.queryProductDetails({AppConfig.premiumProductId});
      if (resp.productDetails.isNotEmpty) {
        state = state.copyWith(product: resp.productDetails.first);
      }

      await _syncOwnedPurchases();
    } catch (e) {
      debugPrint('PremiumService init failed: $e');
    }
  }

  /// Satın alma ekranını açar.
  Future<void> buy() async {
    if (state.isPremium) return;
    final product = state.product;
    if (!state.storeAvailable || product == null) {
      state = state.copyWith(
        message: 'Google Play mağazasına şu anda ulaşılamıyor. '
            'Lütfen daha sonra tekrar deneyin.',
      );
      return;
    }
    state = state.copyWith(busy: true, clearMessage: true);
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      state = state.copyWith(busy: false, message: 'Satın alma başlatılamadı.');
    }
  }

  /// Daha önce yapılmış satın alımı geri yükler (cihaz değişimi vb.).
  Future<void> restore() async {
    if (!state.storeAvailable) {
      state = state.copyWith(
        message: 'Google Play mağazasına şu anda ulaşılamıyor.',
      );
      return;
    }
    state = state.copyWith(busy: true, clearMessage: true);
    try {
      final found = await _syncOwnedPurchases();
      state = state.copyWith(
        busy: false,
        message: found
            ? 'Premium geri yüklendi.'
            : 'Bu Google hesabında Premium satın alımı bulunamadı.',
      );
    } catch (_) {
      state = state.copyWith(busy: false, message: 'Geri yükleme başarısız.');
    }
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  /// Android'de sahip olunan satın alımları Play'den sorgular. Satın alma
  /// iade edildiyse yerel premium kaydı kaldırılır. Premium bulunduysa true.
  Future<bool> _syncOwnedPurchases() async {
    if (!Platform.isAndroid) {
      await _iap.restorePurchases();
      return state.isPremium;
    }

    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final resp = await addition.queryPastPurchases();
    if (resp.error != null) return state.isPremium;

    final owned = resp.pastPurchases.where(
      (p) =>
          p.productID == AppConfig.premiumProductId &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored),
    );

    if (owned.isEmpty) {
      await _setPremium(false);
      return false;
    }

    for (final p in owned) {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    final valid = await _verify(owned.first);
    await _setPremium(valid);
    return valid;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID == AppConfig.premiumProductId) {
        switch (p.status) {
          case PurchaseStatus.pending:
            state = state.copyWith(
              busy: true,
              message: 'Ödeme onayı bekleniyor…',
            );
            break;
          case PurchaseStatus.canceled:
            state = state.copyWith(busy: false);
            break;
          case PurchaseStatus.error:
            state = state.copyWith(
              busy: false,
              message: 'Satın alma tamamlanamadı.',
            );
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final valid = await _verify(p);
            await _setPremium(valid);
            state = state.copyWith(
              busy: false,
              message: valid
                  ? 'Teşekkürler! Premium aktif.'
                  : 'Satın alma doğrulanamadı.',
            );
            break;
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// Sunucu `valid:false` derse false; diğer her durumda true.
  Future<bool> _verify(PurchaseDetails p) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/v1/purchases/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'packageName': AppConfig.packageName,
              'productId': p.productID,
              'purchaseToken': p.verificationData.serverVerificationData,
              'orderId': p.purchaseID,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return true;
      final body = jsonDecode(resp.body);
      if (body is Map && body['valid'] == false) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _setPremium(bool value) async {
    state = state.copyWith(isPremium: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }
}

final premiumProvider =
    NotifierProvider<PremiumService, PremiumState>(PremiumService.new);

/// Görünümlerin kullandığı basit premium bayrağı.
final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(premiumProvider.select((s) => s.isPremium)));
