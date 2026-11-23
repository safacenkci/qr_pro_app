import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class PremiumUpsellDialog extends StatelessWidget {
  const PremiumUpsellDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onUpgrade,
  });

  final String title;
  final String description;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(description),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade();
          },
          child: Text(l10n.getPremium),
        ),
      ],
    );
  }
}


