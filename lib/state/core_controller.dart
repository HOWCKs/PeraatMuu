import 'package:flutter/foundation.dart';

import '../models/console_system.dart';
import '../services/emulator_bridge.dart';

/// Controla a disponibilidade dos núcleos de emulação embutidos no APK.
class CoreController extends ChangeNotifier {
  bool loading = true;
  String coresDir = '';
  String systemDir = '';
  String statesDir = '';
  String savesDir = '';
  String abi = '';

  /// Disponibilidade por id de núcleo (ex.: `snes9x` -> true).
  final Map<String, bool> availability = {};

  Future<void> refresh() async {
    loading = true;
    try {
      final paths = await EmulatorBridge.paths();
      coresDir = paths['coresDir'] ?? '';
      systemDir = paths['systemDir'] ?? '';
      statesDir = paths['statesDir'] ?? '';
      savesDir = paths['savesDir'] ?? '';
      abi = await EmulatorBridge.primaryAbi();

      availability.clear();
      for (final coreId in kUniqueCoreIds) {
        availability[coreId] =
            await EmulatorBridge.isCoreAvailable(coreFileName(coreId));
      }
    } catch (_) {
      // Canal indisponível (ex.: rodando fora do Android) — mantém padrões.
    }
    loading = false;
    notifyListeners();
  }

  bool isReady(ConsoleSystem system) =>
      system.coreId != null && (availability[system.coreId] ?? false);

  String? corePathFor(ConsoleSystem system) {
    if (!system.playable || system.coreId == null || coresDir.isEmpty) {
      return null;
    }
    return '$coresDir/${system.coreFile}';
  }

  int get readyCount => kConsoleCatalog
      .where((s) => s.status != ConsoleStatus.soon && isReady(s))
      .length;
}
