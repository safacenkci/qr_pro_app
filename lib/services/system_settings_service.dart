import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemSettingsService {
  static const _channel = MethodChannel('qr_kod/system_settings');

  Future<bool> openWifiPanel() async {
    try {
      final ok = await _channel.invokeMethod<bool>('openWifiPanel');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openWifiSettings() async {
    try {
      final ok = await _channel.invokeMethod<bool>('openWifiSettings');
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}

final systemSettingsServiceProvider = Provider<SystemSettingsService>((ref) {
  return SystemSettingsService();
});


