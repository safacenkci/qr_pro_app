import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryService {
  /// Saves PNG bytes into the user's gallery (Photos / MediaStore).
  /// Returns true if success.
  Future<bool> savePngToGallery(
    Uint8List pngBytes, {
    String? name,
  }) async {
    final fileName = name ?? 'qr_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // iOS requires explicit "add to photos" permission in many cases.
      if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        if (!status.isGranted && !status.isLimited) return false;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        name: fileName,
        quality: 100,
      );

      final isSuccess = result['isSuccess'] == true || result['success'] == true;
      if (isSuccess) return true;

      // Android 9 and below may require storage permission. Retry once.
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final retry = await ImageGallerySaverPlus.saveImage(
            pngBytes,
            name: fileName,
            quality: 100,
          );
          return retry['isSuccess'] == true || retry['success'] == true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Writes PNG bytes to a temporary file for sharing.
  Future<File> writeTempPng(Uint8List pngBytes, {String? name}) async {
    final dir = await getTemporaryDirectory();
    final fileName = name ?? 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }
}

final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});


