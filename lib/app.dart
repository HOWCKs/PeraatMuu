import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

class PeraatMuuApp extends StatelessWidget {
  const PeraatMuuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeraatMuu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
