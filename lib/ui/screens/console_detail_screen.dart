import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../models/core_option.dart';
import '../../models/game_entry.dart';
import '../../services/launch_game.dart';
import '../../state/app_settings.dart';
import '../../state/core_controller.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/game_tile.dart';
import '../widgets/library_actions.dart';
import '../widgets/status_badge.dart';

/// Detalhe de um console: informações do núcleo + jogos da biblioteca.
class ConsoleDetailScreen extends StatelessWidget {
  final ConsoleSystem system;

  const ConsoleDetailScreen({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final cores = context.watch<CoreController>();
    final games = library.gamesFor(system.id);
    final coreReady = cores.isReady(system);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bg1, AppTheme.bg0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(system: system)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoreCard(system: system, ready: coreReady),
                      if (system.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DescriptionCard(system: system),
                      ],
                      if (system.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _NotesCard(system: system),
                      ],
                      if (coreOptionDefsFor(system.id).isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CoreOptionsCard(system: system),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => chooseRomSource(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('ADICIONAR JOGOS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neon,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                textStyle: const TextStyle(
                                  fontFamily: 'Audiowide',
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (library.scanning)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppTheme.neon,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'JOGOS (${games.length})',
                        style: AppTheme.display(12, letterSpacing: 2.4),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              if (games.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          size: 44,
                          color: AppTheme.textMid.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Nenhuma ROM encontrada para este console.\nAdicione a pasta onde estão seus jogos.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppTheme.textMid, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final game = games[index];
                        return GameTile(
                          game: game,
                          onPlay: () => launchGame(context, game),
                          onRemove: () =>
                              _confirmRemove(context, library, game),
                        );
                      },
                      childCount: games.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    LibraryController library,
    GameEntry game,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover da biblioteca?'),
        content: Text(
          'O arquivo da ROM não será apagado do dispositivo.',
          style: TextStyle(color: AppTheme.textMid.withValues(alpha: 0.95)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVER',
                style: TextStyle(color: AppTheme.pink)),
          ),
        ],
      ),
    );
    if (remove == true) {
      library.removeGame(game);
    }
  }
}

class _DescriptionCard extends StatelessWidget {
  final ConsoleSystem system;

  const _DescriptionCard({required this.system});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262640)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.videogame_asset_rounded,
              color: system.gradient.first, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              system.description,
              style: const TextStyle(
                  color: AppTheme.textHigh, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card com as opções do núcleo (core options) do console — chips de
/// escolha única, persistidos e aplicados na hora de abrir o jogo.
class _CoreOptionsCard extends StatelessWidget {
  final ConsoleSystem system;

  const _CoreOptionsCard({required this.system});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final defs = coreOptionDefsFor(system.id);
    final accent = system.gradient.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262640)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text('OPÇÕES DO NÚCLEO', style: AppTheme.display(12,
                  letterSpacing: 1.4, color: accent)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Vale para o próximo jogo que você abrir.',
            style: TextStyle(color: AppTheme.textMid, fontSize: 11.5),
          ),
          for (final def in defs) ...[
            const SizedBox(height: 12),
            Text(def.title,
                style: const TextStyle(
                    color: AppTheme.textHigh,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (def.subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(def.subtitle!,
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 11.5, height: 1.35)),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in def.choices)
                  ChoiceChip(
                    label: Text(choice.label),
                    selected:
                        settings.coreOptionValue(system.id, def) == choice.value,
                    onSelected: (_) => settings.setCoreOption(
                        system.id, def.key, choice.value),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: settings.coreOptionValue(system.id, def) ==
                              choice.value
                          ? AppTheme.bg0
                          : AppTheme.textHigh,
                    ),
                    selectedColor: accent,
                    backgroundColor: const Color(0xFF1B1B2E),
                    side: const BorderSide(color: Color(0xFF2E2E4D)),
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ConsoleSystem system;

  const _Header({required this.system});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg0,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Arte do console ao fundo do cabeçalho
          Positioned.fill(
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                system.imageAsset,
                fit: BoxFit.cover,
                cacheWidth: 512,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    system.gradient.first.withValues(alpha: 0.65),
                    system.gradient.last.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.glow(system.gradient.first),
                    ),
                    child: Icon(system.icon, size: 38, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          system.shortName,
                          style: AppTheme.display(24),
                        ),
                        Text(
                          '${system.maker} • ${system.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: system.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

class _CoreCard extends StatelessWidget {
  final ConsoleSystem system;
  final bool ready;

  const _CoreCard({required this.system, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262640)),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.error_rounded,
            color: ready ? AppTheme.neon : AppTheme.pink,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  system.coreName ?? 'Sem núcleo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textHigh,
                  ),
                ),
                Text(
                  ready
                      ? 'Núcleo embutido — pronto para jogar'
                      : 'Núcleo não encontrado nesta instalação',
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
                ),
              ],
            ),
          ),
          if (system.requiresBios)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Tooltip(
                message: 'Este console requer arquivo de BIOS',
                child: Icon(Icons.shield_rounded,
                    color: AppTheme.yellow, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final ConsoleSystem system;

  const _NotesCard({required this.system});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.yellow, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              system.notes,
              style: const TextStyle(color: AppTheme.textHigh, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
