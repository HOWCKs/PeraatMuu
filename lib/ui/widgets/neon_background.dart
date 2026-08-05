import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';

/// Fundo gamer: grid em perspectiva (synthwave). A varredura luminosa animada
/// só roda quando "efeitos reduzidos" está DESLIGADO nos Ajustes —
/// no modo leve o fundo é pintado uma única vez (navegação muito mais fluida).
class NeonBackground extends StatefulWidget {
  final Widget child;

  const NeonBackground({super.key, required this.child});

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.watch<AppSettings>().reducedEffects;

    if (reduced) {
      _controller.stop();
      return RepaintBoundary(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.bg1, AppTheme.bg0],
            ),
          ),
          child: CustomPaint(
            painter: _GridPainter(),
            child: widget.child,
          ),
        ),
      );
    }

    _controller.repeat();
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bg1, AppTheme.bg0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _ScanPainter(_controller.value),
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neon.withValues(alpha: 0.055)
      ..strokeWidth = 1;

    final horizon = size.height * 0.60;

    final vanishingX = size.width / 2;
    const count = 14;
    for (var i = -count; i <= count; i++) {
      final bottomX = vanishingX + i * size.width * 0.16;
      canvas.drawLine(
        Offset(vanishingX + i * size.width * 0.008, horizon),
        Offset(bottomX, size.height),
        paint,
      );
    }

    for (var i = 0; i < 12; i++) {
      final t = i / 12;
      final depth = math.pow(t, 1.8).toDouble();
      final y = horizon + depth * (size.height - horizon);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.purple.withValues(alpha: 0.16),
          AppTheme.purple.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(vanishingX, horizon),
        radius: size.width * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanPainter extends CustomPainter {
  final double progress;

  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.neon.withValues(alpha: 0.0),
          AppTheme.neon.withValues(alpha: 0.05),
          AppTheme.neon.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 60, size.width, 120));
    canvas.drawRect(Rect.fromLTWH(0, y - 60, size.width, 120), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
