import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../viewmodels/history_viewmodel.dart';

enum GenerateType { text, url, wifi }

enum WifiAuth { wpa, wpa3, wep, nopass }

class GenerateState {
  const GenerateState({
    required this.type,
    required this.qrColor,
    required this.text,
    required this.url,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.wifiAuth,
    this.logoPath,
  });

  final GenerateType type;
  final Color qrColor;
  final String text;
  final String url;
  final String wifiSsid;
  final String wifiPassword;
  final WifiAuth wifiAuth;
  final String? logoPath;

  String get data {
    switch (type) {
      case GenerateType.text:
        return text.trim();
      case GenerateType.url:
        return url.trim();
      case GenerateType.wifi:
        final auth = switch (wifiAuth) {
          WifiAuth.wpa => 'WPA',
          WifiAuth.wpa3 => 'WPA3',
          WifiAuth.wep => 'WEP',
          WifiAuth.nopass => 'nopass',
        };
        final ssid = _escapeWifiField(wifiSsid);
        final pass = _escapeWifiField(wifiPassword);
        return 'WIFI:T:$auth;S:$ssid;P:$pass;H:false;;';
    }
  }

  static String _escapeWifiField(String value) {
    // Many scanners expect escaping for: \ ; , : "
    // Order matters: escape backslash first.
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:')
        .replaceAll('"', r'\"');
  }

  static const _unset = Object();

  GenerateState copyWith({
    GenerateType? type,
    Color? qrColor,
    String? text,
    String? url,
    String? wifiSsid,
    String? wifiPassword,
    WifiAuth? wifiAuth,
    Object? logoPath = _unset,
  }) {
    return GenerateState(
      type: type ?? this.type,
      qrColor: qrColor ?? this.qrColor,
      text: text ?? this.text,
      url: url ?? this.url,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiAuth: wifiAuth ?? this.wifiAuth,
      logoPath: identical(logoPath, _unset) ? this.logoPath : logoPath as String?,
    );
  }
}

class GenerateViewModel extends Notifier<GenerateState> {
  final _picker = ImagePicker();

  @override
  GenerateState build() => const GenerateState(
        type: GenerateType.text,
        qrColor: Colors.black,
        text: '',
        url: '',
        wifiSsid: '',
        wifiPassword: '',
        wifiAuth: WifiAuth.wpa,
      );

  void setType(GenerateType type) => state = state.copyWith(type: type);

  void setText(String v) => state = state.copyWith(text: v);
  void setUrl(String v) => state = state.copyWith(url: v);
  void setWifiSsid(String v) => state = state.copyWith(wifiSsid: v);
  void setWifiPassword(String v) => state = state.copyWith(wifiPassword: v);
  void setWifiAuth(WifiAuth v) {
    // If user selects "no password", clear any previously entered password.
    if (v == WifiAuth.nopass) {
      state = state.copyWith(wifiAuth: v, wifiPassword: '');
      return;
    }
    state = state.copyWith(wifiAuth: v);
  }

  void setQrColor(Color c) => state = state.copyWith(qrColor: c);

  Future<File?> pickLogoFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    state = state.copyWith(logoPath: file.path);
    return File(file.path);
  }

  void removeLogo() => state = state.copyWith(logoPath: null);

  /// Resets premium customizations to the simplest QR: black modules, no logo.
  void resetCustomization() {
    state = state.copyWith(qrColor: Colors.black, logoPath: null);
  }

  Future<void> saveToHistoryIfValid() async {
    final data = state.data;
    if (data.trim().isEmpty) return;
    await ref.read(historyViewModelProvider.notifier).addGenerated(data);
  }
}

final generateViewModelProvider =
    NotifierProvider<GenerateViewModel, GenerateState>(GenerateViewModel.new);


