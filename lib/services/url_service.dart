import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  Future<bool> openExternal(String url) async {
    final normalized = _normalizeUrl(url);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return true;
    // Fallback: let platform decide best handler.
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  String _normalizeUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;
    final uri = Uri.tryParse(v);
    if (uri != null && uri.hasScheme) return v;

    // If it looks like "example.com" or "www.example.com/path", prefix https.
    final domainLike = RegExp(r'^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+([:/?#].*)?$');
    if (domainLike.hasMatch(v)) {
      return 'https://$v';
    }
    return v;
  }
}

final urlServiceProvider = Provider<UrlService>((ref) {
  return UrlService();
});


