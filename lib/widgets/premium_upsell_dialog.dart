import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text(title),
      content: Text(description),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade();
          },
          child: const Text('Premium Al'),
        ),
      ],
    );
  }
}


