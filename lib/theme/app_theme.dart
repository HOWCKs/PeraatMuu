import 'package:flutter/material.dart';

/// Identidade visual gamer/neon do PeraatMuu.
class AppTheme {
  static const Color bg0 = Color(0xFF07070D);
  static const Color bg1 = Color(0xFF0D0D1A);
  static const Color card = Color(0xFF131321);
  static const Color cardAlt = Color(0xFF1B1B30);

  static const Color neon = Color(0xFF00F5D4);
  static const Color pink = Color(0xFFFF2E88);
  static const Color purple = Color(0xFF7B2FFF);
  static const Color yellow = Color(0xFFF9F871);

  static const Color textHigh = Color(0xFFF2F2FA);
  static const Color textMid = Color(0xFF9D9DB8);

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bg0,
      textTheme: base.textTheme.apply(fontFamily: 'Rajdhani'),
      colorScheme: const ColorScheme.dark(
        primary: neon,
        secondary: pink,
        tertiary: purple,
        surface: card,
        onSurface: textHigh,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardAlt,
        contentTextStyle: TextStyle(color: textHigh, fontFamily: 'Rajdhani'),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF262640),
        thickness: 1,
      ),
    );
  }

  /// Títulos estilizados (fonte Audiowide).
  static TextStyle display(
    double size, {
    Color color = textHigh,
    double letterSpacing = 1.6,
  }) {
    return TextStyle(
      fontFamily: 'Audiowide',
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.1,
    );
  }

  static List<BoxShadow> glow(Color color, {double blur = 22}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: blur,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];
}
