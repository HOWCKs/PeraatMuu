import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/neon_background.dart';
import 'consoles_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

/// Estrutura principal com navegação inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    ConsolesScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: _pages),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF22223A))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.bg1.withOpacity(0.96),
          elevation: 0,
          selectedItemColor: AppTheme.neon,
          unselectedItemColor: AppTheme.textMid,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Audiowide',
            fontSize: 10,
            letterSpacing: 1.4,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'INÍCIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_rounded),
              label: 'CONSOLES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark_rounded),
              label: 'BIBLIOTECA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'AJUSTES',
            ),
          ],
        ),
      ),
    );
  }
}
