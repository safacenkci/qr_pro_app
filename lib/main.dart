import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/app_theme.dart';
import 'views/home_view.dart';

void main() {
  runApp(const ProviderScope(child: QrProApp()));
}

class QrProApp extends StatelessWidget {
  const QrProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Kod Okuyucu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeView(),
    );
  }
}
