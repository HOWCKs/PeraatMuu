import 'package:flutter/material.dart';

import '../../models/console_system.dart';
import '../../models/game_entry.dart';
import '../../theme/app_theme.dart';

/// Item de lista de uma ROM com botão de jogar.
class GameTile extends StatelessWidget {
  final GameEntry game;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final bool compact;

  const GameTile({
    super.key,
    required this.game,
    this.onPlay,
    this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final system = consoleById(game.systemId);
    final color = system?.gradient.first ?? AppTheme.purple;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232338)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: system?.gradient ?? const [AppTheme.purple, AppTheme.bg1],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.glow(color, blur: 14),
          ),
          child: Icon(system?.icon ?? Icons.videogame_asset_rounded,
              color: Colors.white, size: 22),
        ),
        title: Text(
          game.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textHigh,
          ),
        ),
        subtitle: Text(
          '${system?.shortName ?? game.systemId.toUpperCase()} • ${game.sizeLabel}',
          style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemove != null)
              IconButton(
                tooltip: 'Remover da biblioteca',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textMid),
                onPressed: onRemove,
              ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.glow(AppTheme.neon, blur: 16),
              ),
              child: IconButton(
                tooltip: 'Jogar',
                icon: const Icon(Icons.play_arrow_rounded,
                    color: AppTheme.neon, size: 30),
                onPressed: onPlay,
              ),
            ),
          ],
        ),
        onTap: onPlay,
      ),
    );
  }
}
