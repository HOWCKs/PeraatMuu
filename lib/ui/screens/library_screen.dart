import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../services/launch_game.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/game_tile.dart';
import '../widgets/library_actions.dart';

/// Todas as ROMs do usuário, com busca e filtro por console.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  String? _systemFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final results =
        library.search(_searchController.text, systemId: _systemFilter);
    final usedSystems = library.games.map((g) => g.systemId).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text('BIBLIOTECA', style: AppTheme.display(18, letterSpacing: 4)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppTheme.textHigh),
            decoration: InputDecoration(
              hintText: 'Buscar jogo...',
              hintStyle: const TextStyle(color: AppTheme.textMid),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppTheme.textMid),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textMid),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF262640)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF262640)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.neon),
              ),
            ),
          ),
        ),
        if (usedSystems.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _systemFilter == null,
                  onTap: () => setState(() => _systemFilter = null),
                ),
                ...usedSystems.map((id) {
                  final system = consoleById(id);
                  return _FilterChip(
                    label: system?.shortName ?? id.toUpperCase(),
                    selected: _systemFilter == id,
                    onTap: () => setState(() => _systemFilter =
                        _systemFilter == id ? null : id),
                  );
                }),
              ],
            ),
          ),
        Expanded(
          child: results.isEmpty
              ? _LibraryEmpty(
                  onAddFile: () => addSingleRom(context),
                  onAddFolder: () => addRomsFolder(context),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final game = results[index];
                    return GameTile(
                      game: game,
                      onPlay: () => launchGame(context, game),
                      onRemove: () => library.removeGame(game),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.neon : AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.neon : const Color(0xFF2B2B44),
            ),
            boxShadow: selected ? AppTheme.glow(AppTheme.neon, blur: 14) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Audiowide',
              fontSize: 10,
              letterSpacing: 1.2,
              color: selected ? Colors.black : AppTheme.textMid,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryEmpty extends StatelessWidget {
  final VoidCallback onAddFile;
  final VoidCallback onAddFolder;

  const _LibraryEmpty({required this.onAddFile, required this.onAddFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purple.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.videogame_asset_off_rounded,
                size: 48,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'NENHUM JOGO POR AQUI',
              style: AppTheme.display(13, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text(
              'Escolha uma ROM direto no gerenciador de arquivos, ou adicione a '
              'pasta onde suas ROMs estão guardadas e o PeraatMuu organiza tudo '
              'automaticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMid, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddFile,
              icon: const Icon(Icons.videogame_asset_rounded),
              label: const Text('ESCOLHER ROM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neon,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAddFolder,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('ADICIONAR PASTA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neon,
                side: const BorderSide(color: AppTheme.neon),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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
          ],
        ),
      ),
    );
  }
}
