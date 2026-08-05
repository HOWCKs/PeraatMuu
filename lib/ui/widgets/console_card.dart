import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import 'status_badge.dart';

/// Card visual de um console: arte do aparelho + gradiente neon + selo.
class ConsoleCard extends StatelessWidget {
  final ConsoleSystem system;
  final int gamesCount;
  final VoidCallback? onTap;
  final bool large;

  const ConsoleCard({
    super.key,
    required this.system,
    this.gamesCount = 0,
    this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = system.status == ConsoleStatus.soon;
    final reduced = context.watch<AppSettings>().reducedEffects;
    final tint = disabled ? const Color(0xFF15151F) : system.gradient.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: disabled
                  ? const Color(0xFF2A2A3A)
                  : system.gradient.first.withValues(alpha: 0.6),
            ),
            color: AppTheme.card,
            boxShadow:
                disabled || reduced ? null : AppTheme.glow(system.gradient.first),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arte representando o console
              Opacity(
                opacity: disabled ? 0.35 : 0.9,
                child: Image.asset(
                  system.imageAsset,
                  fit: BoxFit.cover,
                  cacheWidth: 512,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // Véu de gradiente para legibilidade do texto
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.bg0.withValues(alpha: disabled ? 0.72 : 0.52),
                      tint.withValues(alpha: disabled ? 0.82 : 0.55),
                      AppTheme.bg0.withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(large ? 10 : 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                            boxShadow: disabled || reduced
                                ? null
                                : AppTheme.glow(system.gradient.first, blur: 14),
                          ),
                          child: Icon(
                            system.icon,
                            size: large ? 30 : 24,
                            color: disabled ? AppTheme.textMid : Colors.white,
                          ),
                        ),
                        StatusBadge(status: system.status, compact: !large),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      system.shortName,
                      style: AppTheme.display(
                        large ? 22 : 18,
                        color: disabled ? AppTheme.textMid : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${system.maker} • ${system.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white.withValues(alpha: disabled ? 0.35 : 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (system.coreName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.memory_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              system.coreName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (gamesCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$gamesCount ${gamesCount == 1 ? 'jogo' : 'jogos'}',
                        style: const TextStyle(
                          color: AppTheme.neon,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
