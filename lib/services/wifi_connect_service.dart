import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../services/system_settings_service.dart';
import '../utils/wifi_qr.dart';

class WifiConnectService {
  /// Tries to connect to Wi-Fi based on parsed WIFI: QR data.
  ///
  /// Notes:
  /// - Not all Android OEMs support QR-driven connection for WPA3 (SAE).
  /// - iOS support depends on platform capabilities; if it fails, user must
  ///   connect manually in Settings.
  Future<bool> connect(WifiQrData data, {SystemSettingsService? settings}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    // Best-effort: ensure Wi‑Fi is enabled (Android only; iOS does not allow).
    if (Platform.isAndroid) {
      try {
        final enabled = await WiFiForIoTPlugin.isEnabled();
        if (!enabled) {
          // Android 10+ often blocks programmatic toggles. We'll still try,
          // then fall back to opening the system Wi‑Fi panel and waiting.
          await WiFiForIoTPlugin.setEnabled(true);

          final enabledAfter = await WiFiForIoTPlugin.isEnabled();
          if (!enabledAfter) {
            final s = settings;
            if (s != null) {
              await s.openWifiPanel();
            }

            final becameEnabled = await _waitForWifiEnabled(timeout: const Duration(seconds: 30));
            if (!becameEnabled) return false;
          }
        }
      } catch (_) {
        // Fall back to opening the system Wi‑Fi panel if possible.
        final s = settings;
        if (Platform.isAndroid && s != null) {
          await s.openWifiPanel();
          final becameEnabled = await _waitForWifiEnabled(timeout: const Duration(seconds: 30));
          if (!becameEnabled) return false;
        }
      }
    }

    // Required permissions vary by Android version/device.
    if (Platform.isAndroid) {
      final ok = await _ensureAndroidWifiPermissions();
      if (!ok) return false;
    }

    final auth = data.auth.toUpperCase();
    final hasPassword = auth != 'NOPASS';
    final password = hasPassword ? data.password : '';

    NetworkSecurity security;
    switch (auth) {
      case 'WEP':
        security = NetworkSecurity.WEP;
        break;
      case 'NOPASS':
        security = NetworkSecurity.NONE;
        break;
      case 'WPA3':
        // wifi_iot doesn't have a dedicated WPA3 enum; WPA often works for WPA2/WPA3 mixed.
        security = NetworkSecurity.WPA;
        break;
      case 'WPA':
      default:
        security = NetworkSecurity.WPA;
        break;
    }

    try {
      // On Android 10+, this should open the system panel / suggestion flow.
      // On older versions it may connect directly.
      return await WiFiForIoTPlugin.connect(
        data.ssid,
        password: password,
        security: security,
        joinOnce: true,
        withInternet: true,
        isHidden: data.hidden,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _waitForWifiEnabled({required Duration timeout}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        if (await WiFiForIoTPlugin.isEnabled()) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    return false;
  }

  Future<bool> _ensureAndroidWifiPermissions() async {
    // Android 13+ prefers NEARBY_WIFI_DEVICES; earlier versions often require location.
    try {
      final near = await Permission.nearbyWifiDevices.request();
      if (near.isGranted) return true;
    } catch (_) {
      // Permission may not exist on older SDKs; ignore and fall back.
    }

    final fine = await Permission.locationWhenInUse.request();
    if (fine.isGranted) return true;

    final coarse = await Permission.location.request();
    return coarse.isGranted;
  }
}

final wifiConnectServiceProvider = Provider<WifiConnectService>((ref) {
  return WifiConnectService();
});


