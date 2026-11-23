// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QR Code Reader';

  @override
  String get navScan => 'Scan';

  @override
  String get navGenerate => 'Create';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get getPremium => 'Get Premium';

  @override
  String get scanModeSingle => 'Scanning';

  @override
  String scanModeBatch(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Batch ($countString)';
  }

  @override
  String get torchOn => 'Flashlight on';

  @override
  String get torchOff => 'Flashlight off';

  @override
  String get scanFromGallery => 'Scan from Gallery';

  @override
  String get batchScanStart => 'Batch Scan';

  @override
  String get batchScanStop => 'Stop Batch';

  @override
  String get batchScanPremiumTitle => 'Batch Scan (Premium)';

  @override
  String get batchScanPremiumDescription =>
      'Scan QR codes back to back and collect them in a list.';

  @override
  String get scanNoQrInImage => 'No QR code found in the image.';

  @override
  String get scanQrUnreadable => 'Couldn\'t read the QR code.';

  @override
  String get scanImageUnsupported => 'Scanning images isn\'t supported.';

  @override
  String get scanResultTitle => 'Result';

  @override
  String get wifiConnect => 'Connect to Wi‑Fi';

  @override
  String get wifiConnectAttempted =>
      'Connection attempted. If it worked, you\'ll see it in the status bar.';

  @override
  String get wifiConnectFailed =>
      'Couldn\'t turn on or connect to Wi‑Fi. If a panel opened, turn Wi‑Fi on and come back.';

  @override
  String get wifiShareFailed => 'Couldn\'t share the Wi‑Fi QR';

  @override
  String get wifiQrShareText => 'Wi‑Fi QR';

  @override
  String get linkOpenFailed => 'Couldn\'t open the link';

  @override
  String get open => 'Open';

  @override
  String get batchListTitle => 'Batch List';

  @override
  String get clear => 'Clear';

  @override
  String get batchListEmpty => 'Nothing here yet. Keep scanning QR codes.';

  @override
  String get generateTitle => 'Create';

  @override
  String get generateType => 'Type';

  @override
  String get generateTypeText => 'Text';

  @override
  String get generateTypeUrl => 'URL';

  @override
  String get generateTypeWifi => 'Wi‑Fi';

  @override
  String get generatePreview => 'Preview';

  @override
  String get generateResetCustomization => 'Reset style';

  @override
  String get addToHistory => 'Add to History';

  @override
  String get addedToHistory => 'Added to history';

  @override
  String get save => 'Save';

  @override
  String get generateCustomization => 'Customize';

  @override
  String get color => 'Color';

  @override
  String get colorPremiumTitle => 'Custom Color (Premium)';

  @override
  String get colorPremiumDescription =>
      'Changing the QR color is a Premium feature.';

  @override
  String get addLogo => 'Add Logo';

  @override
  String get logoPremiumTitle => 'Add Logo (Premium)';

  @override
  String get logoPremiumDescription =>
      'Adding a logo to the center of the QR code is a Premium feature.';

  @override
  String get pickQrColor => 'Choose QR Color';

  @override
  String get savedToGallery => 'Saved to gallery';

  @override
  String get saveToGalleryFailed => 'Couldn\'t save to gallery';

  @override
  String get saveFailed => 'Couldn\'t save';

  @override
  String get qrShareText => 'QR Code';

  @override
  String get shareFailed => 'Couldn\'t share';

  @override
  String get generateTextLabel => 'Text';

  @override
  String get generateTextHint => 'e.g. “Hello World”';

  @override
  String get generateUrlLabel => 'URL';

  @override
  String get wifiSsidLabel => 'Network Name';

  @override
  String get wifiPasswordLabel => 'Password';

  @override
  String get wifiSecurityLabel => 'Security';

  @override
  String get wifiAuthWpa3 => 'WPA3‑Personal (SAE)';

  @override
  String get wifiAuthNone => 'None';

  @override
  String get historyTitle => 'History';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvPremium => 'Export CSV (Premium)';

  @override
  String get csvShareText => 'My QR history (CSV)';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get historyCleared => 'History cleared';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get historyEmpty => 'No history yet.';

  @override
  String historyItemSubtitle(String type, String date) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'scanned': 'Scanned',
      'other': 'Created',
    });
    return '$_temp0 • $date';
  }

  @override
  String get openLink => 'Open Link';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get csvPremiumTitle => 'CSV Export (Premium)';

  @override
  String get csvPremiumDescription =>
      'Exporting your history as CSV/Excel is a Premium feature.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get premiumActive => 'Premium Active';

  @override
  String get premiumActiveDescription =>
      'All Premium features are unlocked. Thank you!';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get freePlanDescription =>
      'Unlock colors, logos, batch scanning and CSV export with Premium.';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumOneTimePayment => 'One-time payment, no subscription.';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String upgradeToProWithPrice(String price) {
    return 'Upgrade to Pro · $price';
  }

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get version => 'Version';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get premiumMsgPurchaseError =>
      'Something went wrong with the purchase.';

  @override
  String get premiumMsgStoreUnavailable =>
      'Google Play is unavailable right now. Please try again later.';

  @override
  String get premiumMsgPurchaseStartFailed => 'Couldn\'t start the purchase.';

  @override
  String get premiumMsgRestored => 'Premium restored.';

  @override
  String get premiumMsgNothingToRestore =>
      'No Premium purchase found on this Google account.';

  @override
  String get premiumMsgRestoreFailed => 'Restore failed.';

  @override
  String get premiumMsgPaymentPending => 'Waiting for payment confirmation…';

  @override
  String get premiumMsgPurchaseFailed => 'The purchase couldn\'t be completed.';

  @override
  String get premiumMsgPurchaseSuccess => 'Thanks! Premium is now active.';

  @override
  String get premiumMsgVerificationFailed => 'Couldn\'t verify the purchase.';
}
