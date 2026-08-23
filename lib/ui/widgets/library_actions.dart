import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';

/// Diálogo "de qual console é este arquivo?" — extensões ambíguas
/// (.iso/.pbp servem para mais de um console).
Future<String?> _pickSystemFor(
  BuildContext context,
  String path,
  List<ConsoleSystem> candidates,
) {
  final fileName = path.split('/').last;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('QUAL CONSOLE?', style: AppTheme.display(14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMid, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final s in candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(ctx).pop(s.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        s.gradient.first.withValues(alpha: 0.30),
                        s.gradient.last.withValues(alpha: 0.30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: s.gradient.first.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(s.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            color: AppTheme.textHigh,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMid),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Menu "de onde vêm as ROMs?": escolher ARQUIVO(s) (toca direto na ROM)
/// ou PASTA inteira (varre tudo de uma vez).
Future<void> chooseRomSource(BuildContext context) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('ADICIONAR JOGOS', style: AppTheme.display(14)),
      content: const Text(
        'Escolha como adicionar suas ROMs:',
        style: TextStyle(color: AppTheme.textMid),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        _SourceButton(
          icon: Icons.description_rounded,
          label: 'ARQUIVO',
          hint: 'tocar direto na ROM',
          onTap: () => Navigator.of(ctx).pop('file'),
        ),
        _SourceButton(
          icon: Icons.folder_open_rounded,
          label: 'PASTA',
          hint: 'varre a pasta inteira',
          onTap: () => Navigator.of(ctx).pop('folder'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'file') {
    await addSingleRom(context);
  } else if (choice == 'folder') {
    await addRomsFolder(context);
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neon.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.neon, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTheme.display(11)),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMid, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ação: seletor de ARQUIVO do Android — toca direto na(s) ROM(s).
Future<void> addSingleRom(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final library = context.read<LibraryController>();

  // Extensões ambíguas (.iso, .pbp...) perguntam o console antes de varrer.
  library.overrideChooser = (path, candidates) async {
    if (!context.mounted) return null;
    return _pickSystemFor(context, path, candidates);
  };
  final result = await library.addSingleFile();
  library.overrideChooser = null;
  if (!context.mounted) return;

  if (result == -2) {
    messenger?.showSnackBar(
      SnackBar(
        content: const Text(
          'Permissão de armazenamento negada. O PeraatMuu precisa dela para ler suas ROMs.',
        ),
        action: SnackBarAction(
          label: 'CONFIGURAÇÕES',
          onPressed: () => library.openSystemSettings(),
        ),
      ),
    );
  } else if (result == 0) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Nada novo para adicionar — essa ROM já está na biblioteca ou o '
          'formato não é reconhecido (valem .gb, .nes, .sfc, .gba... até .zip!).',
        ),
      ),
    );
  } else if (result > 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text('$result jogo(s) adicionado(s) à biblioteca!')),
    );
  }
}

/// Ação: seletor de PASTA do Android + varredura completa.
Future<void> addRomsFolder(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final library = context.read<LibraryController>();

  // O seletor de pastas do Android NÃO seleciona arquivos — avisa antes,
  // pra ninguém ficar tocando na ROM esperando alguma coisa acontecer.
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('ESCOLHER UMA PASTA', style: AppTheme.display(14)),
      content: const Text(
        'Atenção: a próxima tela é o seletor de PASTAS do Android — '
        'tocar em um arquivo não seleciona nada!\n\n'
        '1. Navegue até a pasta onde suas ROMs estão (ex.: Download)\n'
        '2. Toque em "USAR ESTA PASTA" na parte de baixo da tela\n'
        '3. O PeraatMuu encontra os jogos sozinho (valem zips!)\n\n'
        'Prefere tocar direto na ROM? Use a opção ARQUIVO.',
        style: TextStyle(color: AppTheme.textMid, height: 1.55),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('VOLTAR'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('CONTINUAR'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  final result = await library.addFolderAndScan();
  if (!context.mounted) return;

  if (result == -2) {
    messenger?.showSnackBar(
      SnackBar(
        content: const Text(
          'Permissão de armazenamento negada. O PeraatMuu precisa dela para ler suas ROMs.',
        ),
        action: SnackBarAction(
          label: 'CONFIGURAÇÕES',
          onPressed: () => library.openSystemSettings(),
        ),
      ),
    );
  } else if (result == -3) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(library.lastError ?? 'Pasta não suportada.'),
      ),
    );
  } else if (result == 0) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Nenhuma ROM nova encontrada nesta pasta. '
          'Valem .gb, .gbc, .nes, .sfc, .gba, .bin, .smc... soltos ou em .zip!',
        ),
      ),
    );
  } else if (result > 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text('$result novos jogos adicionados à biblioteca!')),
    );
  }
}
