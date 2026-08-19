import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_item.dart';

class HistoryStorageService {
  static const _key = 'history_items_v1';

  Future<List<HistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return HistoryItem.decodeList(raw);
    } catch (_) {
      // If parsing fails, don't crash the app.
      return const [];
    }
  }

  Future<void> save(List<HistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, HistoryItem.encodeList(items));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final historyStorageProvider = Provider<HistoryStorageService>((ref) {
  return HistoryStorageService();
});


