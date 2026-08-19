import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/history_viewmodel.dart';

class ScanState {
  const ScanState({
    required this.isBatchMode,
    required this.batchResults,
    this.pendingResult,
    this.lastValue,
    this.lastAtMillis,
  });

  final bool isBatchMode;
  final List<String> batchResults;
  final String? pendingResult;

  final String? lastValue;
  final int? lastAtMillis;

  ScanState copyWith({
    bool? isBatchMode,
    List<String>? batchResults,
    String? pendingResult,
    String? lastValue,
    int? lastAtMillis,
  }) {
    return ScanState(
      isBatchMode: isBatchMode ?? this.isBatchMode,
      batchResults: batchResults ?? this.batchResults,
      pendingResult: pendingResult,
      lastValue: lastValue ?? this.lastValue,
      lastAtMillis: lastAtMillis ?? this.lastAtMillis,
    );
  }
}

class ScanViewModel extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState(isBatchMode: false, batchResults: []);

  void toggleBatchMode() {
    state = state.copyWith(isBatchMode: !state.isBatchMode, pendingResult: null);
  }

  void clearBatch() {
    state = state.copyWith(batchResults: const [], pendingResult: null);
  }

  /// Called by the view when a QR code is detected.
  /// - Adds to history always.
  /// - In non-batch mode, sets `pendingResult` so the view can open a sheet.
  Future<void> onDetected(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Simple duplicate throttle.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (state.lastValue == trimmed &&
        state.lastAtMillis != null &&
        (now - state.lastAtMillis!) < 1200) {
      return;
    }

    state = state.copyWith(lastValue: trimmed, lastAtMillis: now);

    await ref.read(historyViewModelProvider.notifier).addScanned(trimmed);

    if (state.isBatchMode) {
      if (!state.batchResults.contains(trimmed)) {
        state = state.copyWith(batchResults: [trimmed, ...state.batchResults]);
      }
      return;
    }

    state = state.copyWith(pendingResult: trimmed);
  }

  void consumePendingResult() {
    if (state.pendingResult == null) return;
    state = state.copyWith(pendingResult: null);
  }
}

final scanViewModelProvider =
    NotifierProvider<ScanViewModel, ScanState>(ScanViewModel.new);


