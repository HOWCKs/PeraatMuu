import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/console_system.dart';
import '../models/game_entry.dart';
import '../state/core_controller.dart';
import '../state/library_controller.dart';
import 'emulator_bridge.dart';

/// Fluxo único para abrir um jogo: valida console, núcleo e ROM antes de
/// chamar a tela nativa de emulação.
Future<void> launchGame(BuildContext context, GameEntry game) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final library = context.read<LibraryController>();
  final cores = context.read<CoreController>();

  void warn(String message) =>
      messenger?.showSnackBar(SnackBar(content: Text(message)));

  final system = consoleById(game.systemId);
  if (system == null) {
    warn('Console desconhecido para este jogo.');
    return;
  }
  if (system.status == ConsoleStatus.soon) {
    warn('${system.shortName} chega em uma próxima versão do PeraatMuu.');
    return;
  }
  final corePath = cores.corePathFor(system);
  if (corePath == null || !cores.isReady(system)) {
    warn('Núcleo "${system.coreName ?? system.coreId}" não encontrado. '
        'Reinstale o APK ou verifique a página de núcleos nos Ajustes.');
    return;
  }

  try {
    await EmulatorBridge.play(
      corePath: corePath,
      romPath: game.path,
      systemId: system.id,
    );
    library.markPlayed(game);
  } on PlatformException catch (e) {
    warn(e.message ?? 'Falha ao iniciar o emulador.');
  }
}
