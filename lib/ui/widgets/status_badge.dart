import 'package:flutter/material.dart';

import '../../models/console_system.dart';
import '../../theme/app_theme.dart';

/// Selo de estado do console: PRONTO / EXPERIMENTAL / EM BREVE.
class StatusBadge extends StatelessWidget {
  final ConsoleStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConsoleStatus.ready => ('PRONTO', AppTheme.neon),
      ConsoleStatus.experimental => ('EXPERIMENTAL', AppTheme.yellow),
      ConsoleStatus.soon => ('EM BREVE', AppTheme.textMid),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Audiowide',
          fontSize: compact ? 8 : 9,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}
