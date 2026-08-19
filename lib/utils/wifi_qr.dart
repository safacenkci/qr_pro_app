class WifiQrData {
  const WifiQrData({
    required this.auth,
    required this.ssid,
    required this.password,
    required this.hidden,
  });

  final String auth; // WPA / WPA2 / WPA3 / WEP / nopass (as in payload)
  final String ssid;
  final String password;
  final bool hidden;
}

class WifiQr {
  /// Parses standard WIFI QR payloads like:
  /// WIFI:T:WPA;S:MyWifi;P:mypassword;H:false;;
  static WifiQrData? parse(String raw) {
    final v = raw.trim();
    if (!v.toUpperCase().startsWith('WIFI:')) return null;

    // Strip prefix
    final body = v.substring(5);

    String auth = 'WPA';
    String ssid = '';
    String pass = '';
    bool hidden = false;

    final parts = _splitUnescaped(body, ';');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final idx = part.indexOf(':');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).toUpperCase();
      final value = _unescape(part.substring(idx + 1));
      switch (key) {
        case 'T':
          auth = value;
          break;
        case 'S':
          ssid = value;
          break;
        case 'P':
          pass = value;
          break;
        case 'H':
          hidden = value.toLowerCase() == 'true';
          break;
      }
    }

    if (ssid.trim().isEmpty) return null;
    return WifiQrData(auth: auth, ssid: ssid, password: pass, hidden: hidden);
  }

  static List<String> _splitUnescaped(String input, String sep) {
    final out = <String>[];
    final buf = StringBuffer();
    var escaping = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (escaping) {
        buf.write(ch);
        escaping = false;
        continue;
      }
      if (ch == r'\') {
        escaping = true;
        continue;
      }
      if (ch == sep) {
        out.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    out.add(buf.toString());
    return out;
  }

  static String _unescape(String input) {
    final buf = StringBuffer();
    var escaping = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (escaping) {
        buf.write(ch);
        escaping = false;
      } else if (ch == r'\') {
        escaping = true;
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }
}


