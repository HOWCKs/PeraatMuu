import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../services/launch_game.dart';
import '../../state/core_controller.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/console_card.dart';
import '../widgets/game_tile.dart';
import '../widgets/library_actions.dart';
import '../widgets/section_header.dart';
import '../widgets/tilt_card.dart';
import 'console_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final cores = context.watch<CoreController>();

    final featured = kConsoleCatalog
        .where((s) => s.status == ConsoleStatus.ready)
        .toList();
    final recentPlayed = library.recentPlayed.take(6).toList();
    final recentAdded = library.recentlyAdded.take(5).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _HeroHeader(
          gamesCount: library.games.length,
          coresReady: cores.readyCount,
          onAddRoms: () => chooseRomSource(context),
        ),
        if (library.games.isEmpty) _EmptyLibraryCard(),
        const SectionHeader(title: 'Consoles em destaque'),
        SizedBox(
          height: 185,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final system = featured[index];
              return SizedBox(
                width: 240,
                child: TiltCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConsoleDetailScreen(system: system),
                    ),
                  ),
                  child: ConsoleCard(
                    system: system,
                    large: true,
                    gamesCount: library.countFor(system.id),
                  ),
                ),
              );
            },
          ),
        ),
        if (recentPlayed.isNotEmpty) ...[
          const SectionHeader(title: 'Continuar jogando'),
          ...recentPlayed.map(
            (game) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GameTile(
                game: game,
                onPlay: () => launchGame(context, game),
              ),
            ),
          ),
        ],
        if (recentAdded.isNotEmpty) ...[
          const SectionHeader(title: 'Adicionados recentemente'),
          ...recentAdded.map(
            (game) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GameTile(
                game: game,
                onPlay: () => launchGame(context, game),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final int gamesCount;
  final int coresReady;
  final VoidCallback onAddRoms;

  const _HeroHeader({
    required this.gamesCount,
    required this.coresReady,
    required this.onAddRoms,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TiltCard(
        maxTilt: 0.10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hero.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.purple, AppTheme.bg1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 34,
                            height: 34,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_esports_rounded,
                              color: AppTheme.neon,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'PERAATMUU',
                            style: AppTheme.display(20, letterSpacing: 4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sua central de emuladores retrô',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.videogame_asset_rounded,
                            label: '$gamesCount jogos',
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.memory_rounded,
                            label: '$coresReady consoles prontos',
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: onAddRoms,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('ROMS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neon,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(
                                fontFamily: 'Audiowide',
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.neon),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibraryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2B2B44)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.pink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: AppTheme.pink, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biblioteca vazia',
                    style: TextStyle(
                      fontFamily: 'Audiowide',
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: AppTheme.textHigh,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Toque em "ROMS" acima para escolher a pasta onde estão seus jogos.',
                    style: TextStyle(color: AppTheme.textMid, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
