import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/history_item.dart';
import '../services/export_service.dart';
import '../services/history_storage_service.dart';

class HistoryViewModel extends AsyncNotifier<List<HistoryItem>> {
  @override
  Future<List<HistoryItem>> build() async {
    final storage = ref.read(historyStorageProvider);
    return storage.load();
  }

  Future<void> addScanned(String value) async {
    await _addItem(
      HistoryItem(
        id: const Uuid().v4(),
        type: HistoryItemType.scanned,
        value: value,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> addGenerated(String value) async {
    await _addItem(
      HistoryItem(
        id: const Uuid().v4(),
        type: HistoryItemType.generated,
        value: value,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _addItem(HistoryItem item) async {
    final storage = ref.read(historyStorageProvider);
    final current = state.asData?.value ?? await storage.load();
    final updated = [item, ...current];
    state = AsyncData(updated);
    await storage.save(updated);
  }

  Future<void> deleteById(String id) async {
    final storage = ref.read(historyStorageProvider);
    final current = state.asData?.value ?? await storage.load();
    final updated = current.where((e) => e.id != id).toList(growable: false);
    state = AsyncData(updated);
    await storage.save(updated);
  }

  Future<void> clearAll() async {
    final storage = ref.read(historyStorageProvider);
    state = const AsyncData([]);
    await storage.clear();
  }

  Future<File> exportCsv() async {
    final items = state.asData?.value ?? const [];
    final exporter = ref.read(exportServiceProvider);
    return exporter.exportHistoryToCsv(items);
  }
}

final historyViewModelProvider =
    AsyncNotifierProvider<HistoryViewModel, List<HistoryItem>>(
        HistoryViewModel.new);


