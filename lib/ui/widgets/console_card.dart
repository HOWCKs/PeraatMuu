import 'package:flutter/material.dart';

import '../../models/console_system.dart';
import '../../theme/app_theme.dart';
import 'status_badge.dart';

/// Card visual de um console (negradiente + ícone com brilho + selo).
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: disabled
                  ? const [Color(0xFF1C1C26), Color(0xFF101018)]
                  : system.gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: disabled
                  ? const Color(0xFF2A2A3A)
                  : system.gradient.first.withOpacity(0.6),
            ),
            boxShadow: disabled ? null : AppTheme.glow(system.gradient.first),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(large ? 12 : 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.30),
                        shape: BoxShape.circle,
                        boxShadow: disabled
                            ? null
                            : AppTheme.glow(system.gradient.first, blur: 16),
                      ),
                      child: Icon(
                        system.icon,
                        size: large ? 34 : 28,
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
                    color: Colors.white.withOpacity(disabled ? 0.35 : 0.75),
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
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          system.coreName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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
        ),
      ),
    );
  }
}
