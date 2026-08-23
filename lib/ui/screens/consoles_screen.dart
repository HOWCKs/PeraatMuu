import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/console_card.dart';
import 'console_detail_screen.dart';

/// Grade com todos os consoles do catálogo.
class ConsolesScreen extends StatelessWidget {
  const ConsolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(
              'CONSOLES',
              style: AppTheme.display(18, letterSpacing: 4),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final system = kConsoleCatalog[index];
                return ConsoleCard(
                  system: system,
                  gamesCount: library.countFor(system.id),
                  onTap: () {
                    if (system.status == ConsoleStatus.soon) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${system.shortName} chega em breve — ${system.notes}',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConsoleDetailScreen(system: system),
                      ),
                    );
                  },
                );
              },
              childCount: kConsoleCatalog.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.74,
            ),
          ),
        ),
      ],
    );
  }
}
