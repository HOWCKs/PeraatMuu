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
  if (system.arm64Only && cores.abi.contains('armeabi')) {
    warn('${system.shortName} precisa de um aparelho 64 bits. '
        'Baixe o APK arm64-v8a em um celular 64 bits.');
    return;
  }
  final corePath = cores.corePathFor(system);
  if (corePath == null || !cores.isReady(system)) {
    warn('Núcleo "${system.coreName ?? system.coreId}" não encontrado '
        'neste APK. Em consoles 64 bits, baixe a versão arm64-v8a do app.');
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

  // PS1 com .bin solto: PCSX-ReARMed carrega muito melhor via .cue.
  // Sintetizamos um cue mínimo ao lado da imagem quando falta.
  if (system.id == 'ps1' && romPath.toLowerCase().endsWith('.bin')) {
    final bin = File(romPath);
    final cuePath =
        romPath.substring(0, romPath.length - 4) + '.cue';
    if (!File(cuePath).existsSync()) {
      try {
        final name = bin.uri.pathSegments.last;
        File(cuePath).writeAsStringSync(
            'FILE "$name" BINARY\n  TRACK 01 MODE2/2352\n    INDEX 01 00:00:00\n');
      } catch (_) {
        // Pasta sem permissão de escrita — segue com o .bin direto.
      }
    }
    if (File(cuePath).existsSync()) romPath = cuePath;
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
