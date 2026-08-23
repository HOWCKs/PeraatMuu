import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/core_controller.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import 'home_shell.dart';

/// Tela de abertura: carrega núcleos e biblioteca antes de entrar no app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cores = context.read<CoreController>();
    final library = context.read<LibraryController>();
    await Future.wait([
      cores.refresh(),
      library.init(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                ),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: AppTheme.glow(
                        AppTheme.purple,
                        blur: 40 + 20 * _pulse.value,
                      ),
                    ),
                    child: child,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports_esports_rounded,
                        size: 120,
                        color: AppTheme.neon,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('PERAATMUU', style: AppTheme.display(30, letterSpacing: 6)),
              const SizedBox(height: 10),
              const Text(
                'Todos os consoles. Um só app.',
                style: TextStyle(color: AppTheme.textMid, fontSize: 15),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Color(0xFF1B1B2E),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neon),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
