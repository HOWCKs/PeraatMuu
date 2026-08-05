import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Cabeçalho de seção com traço neon.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.neon,
              borderRadius: BorderRadius.circular(2),
              boxShadow: AppTheme.glow(AppTheme.neon, blur: 10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTheme.display(14, letterSpacing: 2.4),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
