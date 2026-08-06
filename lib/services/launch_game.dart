import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/console_system.dart';
import '../models/game_entry.dart';
import '../state/app_settings.dart';
import '../state/core_controller.dart';
import '../state/library_controller.dart';
import 'bios_files.dart';
import 'emulator_bridge.dart';
import 'zip_rom.dart';

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

  // ROM zipada (o mais comum ao baixar da internet): extrai para o cache
  // na primeira jogada. Arcade é exceção — o FinalBurn lê o .zip direto.
  var romPath = game.path;
  if (game.path.toLowerCase().endsWith('.zip') && system.id != 'arcade') {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Extraindo a ROM (só na primeira vez)...')),
    );
    final prepared = await extractZipRom(game.path, system.id);
    if (prepared == null) {
      warn('Não consegui ler essa ROM zipada. Tente descompactá-la primeiro.');
      return;
    }
    romPath = prepared;
  }

  // BIOS exigida e ausente? Não bloqueia (núcleos novos/podem ter BIOS
  // interna), mas explica de antemão o clássico sintoma de tela branca.
  if (system.requiresBios && cores.systemDir.isNotEmpty) {
    final missing = requiredBiosFilesFor(system.id)
        .where((f) => !File('${cores.systemDir}/$f').existsSync())
        .toList();
    if (missing.isNotEmpty) {
      warn('Sem a BIOS de ${system.shortName} (${missing.join(', ')}) o '
          'jogo pode travar em tela branca. Importe em Ajustes > BIOS.');
    }
  }

  try {
    await EmulatorBridge.play(
      corePath: corePath,
      romPath: romPath,
      systemId: system.id,
      coreOptions: context.read<AppSettings>().effectiveCoreOptions(system.id),
    );
    library.markPlayed(game);
  } on PlatformException catch (e) {
    warn(e.message ?? 'Falha ao iniciar o emulador.');
  }
}
