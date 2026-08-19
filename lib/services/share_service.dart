import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> shareFile(File file, {String? text}) async {
    final xFile = XFile(file.path);
    await SharePlus.instance.share(ShareParams(files: [xFile], text: text));
  }
}

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});


