import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../services/url_service.dart';
import '../services/gallery_service.dart';
import '../services/wifi_connect_service.dart';
import '../services/system_settings_service.dart';
import '../utils/validators.dart';
import '../utils/wifi_qr.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/scan_viewmodel.dart';
import '../widgets/premium_upsell_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _scannerControllerProvider =
    Provider.autoDispose<MobileScannerController>((ref) {
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView> {
  final _picker = ImagePicker();
  bool _torchOn = false;
  ProviderSubscription<String?>? _pendingResultSub;
  bool _resultSheetOpen = false;
  String? _lastPresentedValue;
  String? _queuedPresentedValue;

  @override
  void initState() {
    super.initState();
    _pendingResultSub = ref.listenManual<String?>(
      scanViewModelProvider.select((s) => s.pendingResult),
      (prev, next) {
        if (next == null || next.isEmpty) return;
        unawaited(_handlePendingResult(next));
      },
    );
  }

  Future<void> _handlePendingResult(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // If sheet is open and a NEW QR arrives, close the current sheet and
    // show the new one immediately after.
    if (_resultSheetOpen) {
      if (_lastPresentedValue == trimmed) return;
      _queuedPresentedValue = trimmed;
      // Close current bottom sheet (if it's still on top).
      Navigator.of(this.context).maybePop();
      return;
    }

    setState(() {
      _resultSheetOpen = true;
      _lastPresentedValue = trimmed;
    });

    // Clear pending result so it doesn't try to re-trigger.
    ref.read(scanViewModelProvider.notifier).consumePendingResult();

    try {
      await _showResultSheet(trimmed);
    } finally {
      if (!mounted) return;
      setState(() => _resultSheetOpen = false);

      // If a new QR arrived while the sheet was open, show it now.
      final queued = _queuedPresentedValue;
      _queuedPresentedValue = null;
      if (queued != null &&
          queued.isNotEmpty &&
          queued != _lastPresentedValue) {
        unawaited(_handlePendingResult(queued));
      }
    }
  }

  @override
  void dispose() {
    _pendingResultSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(_scannerControllerProvider);
    final scanState = ref.watch(scanViewModelProvider);
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) async {
                final barcode = capture.barcodes.firstOrNull;
                final value = barcode?.rawValue;
                if (value == null) return;

                // In normal mode, avoid repeatedly showing the same QR result
                // while it stays in the camera frame.
                if (!scanState.isBatchMode &&
                    _lastPresentedValue != null &&
                    value.trim() == _lastPresentedValue) {
                  return;
                }

                await ref
                    .read(scanViewModelProvider.notifier)
                    .onDetected(value);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Pill(
                    icon: Icons.qr_code_scanner,
                    label: scanState.isBatchMode
                        ? 'Toplu (${scanState.batchResults.length})'
                        : 'Tarama',
                  ),
                  _CircleIconButton(
                    tooltip: _torchOn ? 'Fener açık' : 'Fener kapalı',
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    onPressed: () async {
                      await controller.toggleTorch();
                      if (!mounted) return;
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scanState.isBatchMode)
                      _BatchPanel(
                        values: scanState.batchResults,
                        onClear: () => ref
                            .read(scanViewModelProvider.notifier)
                            .clearBatch(),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _scanFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeriden Tara'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              if (!isPremium) {
                                _showPremiumDialog(
                                  title: 'Toplu Tarama (Premium)',
                                  description:
                                      'Toplu tarama ile art arda QR kod okuyup listeye ekleyebilirsin.',
                                );
                                return;
                              }
                              ref
                                  .read(scanViewModelProvider.notifier)
                                  .toggleBatchMode();
                            },
                            icon: Icon(
                              scanState.isBatchMode
                                  ? Icons.stop_circle_outlined
                                  : Icons.playlist_add,
                            ),
                            label: Text(
                              scanState.isBatchMode
                                  ? 'Toplu Durdur'
                                  : 'Toplu Tarama',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final controller = ref.read(_scannerControllerProvider);
    try {
      final capture = await controller.analyzeImage(picked.path);
      if (!mounted) return;

      if (capture == null || capture.barcodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görselden QR kod bulunamadı.')),
        );
        return;
      }

      final value = capture.barcodes.first.rawValue;
      if (value == null || value.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR kod okunamadı.')));
        return;
      }

      await ref.read(scanViewModelProvider.notifier).onDetected(value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görsel tarama desteklenmiyor.')),
      );
    }
  }

  void _showPremiumDialog({
    required String title,
    required String description,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => PremiumUpsellDialog(
        title: title,
        description: description,
        onUpgrade: () {
          // Mock flow: kullanıcıyı Ayarlar sekmesine yönlendir.
          ref.read(navigationIndexProvider.notifier).setIndex(3);
        },
      ),
    );
  }

  Future<void> _showResultSheet(String value) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final isUrl = Validators.looksLikeUrl(value);
        final wifi = WifiQr.parse(value);

        // For Wi‑Fi QR codes, we intentionally keep the UI minimal:
        // only "Connect" and "Share" actions (no raw payload shown).
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sonuç', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (wifi != null) ...[
                Text(wifi.ssid, style: Theme.of(context).textTheme.titleMedium),
              ] else ...[
                SelectableText(value),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (wifi != null)
                    FilledButton.icon(
                      onPressed: () async {
                        // Close sheet before starting connect flow.
                        Navigator.of(context).pop();
                        final ok = await ref
                            .read(wifiConnectServiceProvider)
                            .connect(
                              wifi,
                              settings: ref.read(systemSettingsServiceProvider),
                            );
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Bağlantı denendi. Bağlandıysa bildirim çubuğunda görürsün.'
                                  : 'Wi‑Fi açılamadı/bağlanılamadı. Panel açıldıysa Wi‑Fi’yi açıp geri dön.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.wifi),
                      label: const Text('Wi‑Fi’ye Bağlan'),
                    ),
                  if (wifi != null)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        // Share as a QR image, not as plain text.
                        final ok = await _shareWifiQrAsImage(value);
                        if (!mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Wi‑Fi QR paylaşımı başarısız oldu',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Paylaş'),
                    ),
                  if (wifi == null)
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: value));
                        if (!mounted || !context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Kopyalandı')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopyala'),
                    ),
                  if (wifi == null)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await ref.read(shareServiceProvider).shareText(value);
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Paylaş'),
                    ),
                  if (wifi == null && isUrl)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final ok = await ref
                            .read(urlServiceProvider)
                            .openExternal(value);
                        if (!mounted || !context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Link açılamadı')),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Aç'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _shareWifiQrAsImage(String payload) async {
    try {
      final painter = QrPainter(
        data: payload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF111827),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF111827),
        ),
      );

      final bytes = await painter.toImageData(720);
      final data = bytes?.buffer.asUint8List();
      if (data == null) return false;

      final file = await ref
          .read(galleryServiceProvider)
          .writeTempPng(data, name: 'wifi_qr.png');
      await ref.read(shareServiceProvider).shareFile(file, text: 'Wi‑Fi QR');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        shape: const CircleBorder(),
        child: IconButton(onPressed: onPressed, icon: Icon(icon)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _BatchPanel extends StatelessWidget {
  const _BatchPanel({required this.values, required this.onClear});

  final List<String> values;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplu Liste',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (values.isEmpty)
              const Text('Henüz bir şey eklenmedi. QR kod okutmaya devam et.')
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  itemCount: values.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      values[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
