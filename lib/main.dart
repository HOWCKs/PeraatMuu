import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PeraatMuuApp());
}

class PeraatMuuApp extends StatelessWidget {
  const PeraatMuuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeraatMuu — Lan House de Emuladores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.purpleAccent,
          secondary: Colors.deepPurple,
          surface: Colors.deepPurple.shade900,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Orbitron',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.black, letterSpacing: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.purpleAccent,
          circularTrackColor: Colors.deepPurple,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
