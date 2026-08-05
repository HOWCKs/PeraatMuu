import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/library_controller.dart';

/// Ação compartilhada: pede permissão, abre o seletor de pasta e varre ROMs,
/// exibindo o resultado em SnackBar.
Future<void> addRomsFolder(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final library = context.read<LibraryController>();

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
  } else if (result == 0) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Nenhuma ROM nova encontrada nesta pasta.')),
    );
  } else if (result > 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text('$result novos jogos adicionados à biblioteca!')),
    );
  }
}
