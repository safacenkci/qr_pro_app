import 'dart:convert';

enum HistoryItemType {
  scanned,
  generated,
}

class HistoryItem {
  HistoryItem({
    required this.id,
    required this.type,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final HistoryItemType type;
  final String value;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
      };

  static HistoryItem fromJson(Map<String, Object?> json) {
    final typeRaw = (json['type'] as String?) ?? HistoryItemType.scanned.name;
    return HistoryItem(
      id: (json['id'] as String?) ?? '',
      type: HistoryItemType.values.firstWhere(
        (t) => t.name == typeRaw,
        orElse: () => HistoryItemType.scanned,
      ),
      value: (json['value'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<HistoryItem> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => HistoryItem.fromJson(e.cast<String, Object?>()))
        .toList(growable: false);
  }

  static String encodeList(List<HistoryItem> items) {
    final list = items.map((e) => e.toJson()).toList(growable: false);
    return jsonEncode(list);
  }
}


