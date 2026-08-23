import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_settings.dart';
import 'theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

class PeraatMuuApp extends StatelessWidget {
  const PeraatMuuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final reduced = context.watch<AppSettings>().reducedEffects;
    return MaterialApp(
      title: 'PeraatMuu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(reducedEffects: reduced),
      home: const SplashScreen(),
    );
  }
}
