class Validators {
  static bool looksLikeUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    if (v.startsWith('WIFI:')) return false;

    final uri = Uri.tryParse(v);
    if (uri == null) return false;

    if (uri.hasScheme) {
      return uri.scheme == 'http' || uri.scheme == 'https';
    }

    // Accept common "www.example.com" / "example.com/path" formats (no scheme).
    final domainLike = RegExp(r'^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+([:/?#].*)?$');
    return domainLike.hasMatch(v);
  }
}


