import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/history_item.dart';

class ExportService {
  Future<File> exportHistoryToCsv(List<HistoryItem> items) async {
    final rows = <List<String>>[
      ['id', 'type', 'value', 'createdAt'],
      ...items.map(
        (e) => [
          e.id,
          e.type.name,
          e.value,
          e.createdAt.toIso8601String(),
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/qr_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file;
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});


