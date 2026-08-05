import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/zip_rom.dart';
import 'state/app_settings.dart';
import 'state/core_controller.dart';
import 'state/library_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07070D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Faxina sem bloquear o boot: apaga extrações de ROM com mais de 7 dias.
  unawaited(cleanZipRomCache());
  final settings = AppSettings();
  unawaited(settings.init());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => CoreController()),
        ChangeNotifierProvider(create: (_) => LibraryController()),
      ],
      child: const PeraatMuuApp(),
    ),
  );
}
