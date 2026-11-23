import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

import '../l10n/app_localizations.dart';
import '../services/gallery_service.dart';
import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../viewmodels/generate_viewmodel.dart';
import '../widgets/premium_upsell_dialog.dart';

class GenerateView extends ConsumerStatefulWidget {
  const GenerateView({super.key});

  @override
  ConsumerState<GenerateView> createState() => _GenerateViewState();
}

class _GenerateViewState extends ConsumerState<GenerateView> {
  final _screenshot = ScreenshotController();
  late final TextEditingController _textController;
  late final TextEditingController _urlController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _urlController = TextEditingController();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _syncControllers(GenerateState state) {
    // Keep controllers in sync with state if state is changed programmatically.
    // (We avoid over-optimizing cursor behavior for now; this is good enough.)
    if (_textController.text != state.text) _textController.text = state.text;
    if (_urlController.text != state.url) _urlController.text = state.url;
    if (_ssidController.text != state.wifiSsid) _ssidController.text = state.wifiSsid;
    if (_passwordController.text != state.wifiPassword) {
      _passwordController.text = state.wifiPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateViewModelProvider);
    final vm = ref.read(generateViewModelProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final data = state.data;
    final l10n = AppLocalizations.of(context);

    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.generateTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.generateType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<GenerateType>(
                    segments: [
                      ButtonSegment(
                        value: GenerateType.text,
                        label: Text(l10n.generateTypeText),
                        icon: const Icon(Icons.text_fields),
                      ),
                      ButtonSegment(
                        value: GenerateType.url,
                        label: Text(l10n.generateTypeUrl),
                        icon: const Icon(Icons.link),
                      ),
                      ButtonSegment(
                        value: GenerateType.wifi,
                        label: Text(l10n.generateTypeWifi),
                        icon: const Icon(Icons.wifi),
                      ),
                    ],
                    selected: {state.type},
                    onSelectionChanged: (s) => vm.setType(s.first),
                  ),
                  const SizedBox(height: 14),
                  _Form(
                    state: state,
                    vm: vm,
                    textController: _textController,
                    urlController: _urlController,
                    ssidController: _ssidController,
                    passwordController: _passwordController,
                  ),
                ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.generatePreview,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (state.logoPath != null)
                        IconButton(
                          tooltip: l10n.generateResetCustomization,
                          onPressed: vm.resetCustomization,
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Screenshot(
                      controller: _screenshot,
                      child: _QrPreview(
                        data: data.isEmpty ? ' ' : data,
                        color: state.qrColor,
                        logoPath: state.logoPath,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await vm.saveToHistoryIfValid();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.addedToHistory)),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: Text(l10n.addToHistory),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: data.trim().isEmpty
                            ? null
                            : _shareQrAsImage,
                        icon: const Icon(Icons.share_outlined),
                        label: Text(l10n.share),
                      ),
                      FilledButton.icon(
                        onPressed: data.trim().isEmpty ? null : _saveQrToGallery,
                        icon: const Icon(Icons.download),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    l10n.generateCustomization,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () {
                          if (!isPremium) {
                            _showPremiumDialog(
                              title: l10n.colorPremiumTitle,
                              description: l10n.colorPremiumDescription,
                            );
                            return;
                          }
                          _pickColor();
                        },
                        icon: const Icon(Icons.palette_outlined),
                        label: Text(l10n.color),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          if (!isPremium) {
                            _showPremiumDialog(
                              title: l10n.logoPremiumTitle,
                              description: l10n.logoPremiumDescription,
                            );
                            return;
                          }
                          final file = await vm.pickLogoFromGallery();
                          if (!mounted) return;
                          if (file == null) return;
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l10n.addLogo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog({required String title, required String description}) {
    showDialog<void>(
      context: context,
      builder: (_) => PremiumUpsellDialog(
        title: title,
        description: description,
        onUpgrade: () => ref.read(premiumProvider.notifier).buy(),
      ),
    );
  }

  Future<void> _pickColor() async {
    final vm = ref.read(generateViewModelProvider.notifier);
    final colors = [
      Colors.black,
      const Color(0xFF111827),
      const Color(0xFF4F46E5),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFEA580C),
    ];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).pickQrColor),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in colors)
                InkWell(
                  onTap: () {
                    vm.setQrColor(c);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> _captureQrPng() async {
    try {
      return await _screenshot.capture();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveQrToGallery() async {
    try {
      final bytes = await _captureQrPng();
      if (bytes == null) return;

      final ok = await ref.read(galleryServiceProvider).savePngToGallery(bytes);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.savedToGallery : l10n.saveToGalleryFailed),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
      );
    }
  }

  Future<void> _shareQrAsImage() async {
    final shareText = AppLocalizations.of(context).qrShareText;
    try {
      final bytes = await _captureQrPng();
      if (bytes == null) return;

      final file = await ref.read(galleryServiceProvider).writeTempPng(bytes);
      await ref.read(shareServiceProvider).shareFile(
            file,
            text: shareText,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).shareFailed)),
      );
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.vm,
    required this.textController,
    required this.urlController,
    required this.ssidController,
    required this.passwordController,
  });

  final GenerateState state;
  final GenerateViewModel vm;
  final TextEditingController textController;
  final TextEditingController urlController;
  final TextEditingController ssidController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (state.type) {
      case GenerateType.text:
        return TextField(
          key: const ValueKey('generate_text'),
          controller: textController,
          onChanged: vm.setText,
          decoration: InputDecoration(
            labelText: l10n.generateTextLabel,
            hintText: l10n.generateTextHint,
          ),
          maxLines: 3,
        );
      case GenerateType.url:
        return TextField(
          key: const ValueKey('generate_url'),
          controller: urlController,
          onChanged: vm.setUrl,
          decoration: InputDecoration(
            labelText: l10n.generateUrlLabel,
            hintText: 'https://',
          ),
          keyboardType: TextInputType.url,
        );
      case GenerateType.wifi:
        return Column(
          children: [
            TextField(
              key: const ValueKey('generate_wifi_ssid'),
              controller: ssidController,
              onChanged: vm.setWifiSsid,
              decoration: InputDecoration(labelText: l10n.wifiSsidLabel),
            ),
            const SizedBox(height: 10),
            if (state.wifiAuth != WifiAuth.nopass) ...[
              TextField(
                key: const ValueKey('generate_wifi_password'),
                controller: passwordController,
                onChanged: vm.setWifiPassword,
                decoration: InputDecoration(labelText: l10n.wifiPasswordLabel),
                obscureText: true,
              ),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<WifiAuth>(
              initialValue: state.wifiAuth,
              items: [
                // WPA/WPA2 ve WEP teknik adlar; her dilde aynı kalır.
                const DropdownMenuItem(
                  value: WifiAuth.wpa,
                  child: Text('WPA/WPA2'),
                ),
                DropdownMenuItem(
                  value: WifiAuth.wpa3,
                  child: Text(l10n.wifiAuthWpa3),
                ),
                const DropdownMenuItem(value: WifiAuth.wep, child: Text('WEP')),
                DropdownMenuItem(
                  value: WifiAuth.nopass,
                  child: Text(l10n.wifiAuthNone),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                vm.setWifiAuth(v);
              },
              decoration: InputDecoration(labelText: l10n.wifiSecurityLabel),
            ),
          ],
        );
    }
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({
    required this.data,
    required this.color,
    required this.logoPath,
  });

  final String data;
  final Color color;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    // QR readability rules:
    // - Keep high contrast (dark modules on light background)
    // - Use high error correction when a logo is present
    // - Keep logo small and surrounded by a white "quiet" area
    final moduleColor = _ensureReadableQrColor(color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: 260,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: moduleColor,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: moduleColor,
            ),
          ),
          if (logoPath != null)
            Container(
              // Keep the logo relatively small compared to QR size.
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x11000000),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(logoPath!), fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  Color _ensureReadableQrColor(Color c) {
    // If a user picked a very light color, QR becomes unreadable on white.
    // Clamp to a dark color while keeping the hue close.
    final lum = c.computeLuminance();
    if (lum <= 0.55) return c;
    // Mix towards a dark neutral.
    return Color.lerp(c, const Color(0xFF111827), 0.75)!;
  }
}


