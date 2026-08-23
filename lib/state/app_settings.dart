import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/core_option.dart';

/// Preferências globais do app (persistidas no dispositivo).
class AppSettings extends ChangeNotifier {
  static const _kReducedEffects = 'reduced_effects';
  static const _kCoreOptions = 'core_options_json';

  late SharedPreferences _prefs;
  bool _loaded = false;

  /// Páginas mais leves: sem varredura animada, sem tilt 3D nos cards.
  /// Desligado por padrão desde a v1.4 (as animações são leves o bastante
  /// para aparelhos medianos) — ligue em aparelhos muito fracos.
  bool _reducedEffects = false;

  /// Escolhas do usuário nas opções de núcleo:
  /// systemId -> (chave da opção -> valor).
  Map<String, Map<String, String>> _coreOptions = {};

  bool get loaded => _loaded;
  bool get reducedEffects => _reducedEffects;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _reducedEffects = _prefs.getBool(_kReducedEffects) ?? false;
    final raw = _prefs.getString(_kCoreOptions);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _coreOptions = decoded.map(
            (k, v) => MapEntry(
              '$k',
              v is Map ? v.map((kk, vv) => MapEntry('$kk', '$vv')) : <String, String>{},
            ),
          );
        }
      } catch (_) {
        _coreOptions = {};
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setReducedEffects(bool value) async {
    _reducedEffects = value;
    notifyListeners();
    await _prefs.setBool(_kReducedEffects, value);
  }

  // ------------------------------------------------- Opções de núcleo

  /// Valor atual de uma opção (escolha do usuário ou padrão).
  String coreOptionValue(String systemId, CoreOptionDef def) =>
      _coreOptions[systemId]?[def.key] ?? def.defaultValue;

  Future<void> setCoreOption(
      String systemId, String key, String value) async {
    final perSystem = _coreOptions.putIfAbsent(systemId, () => {});
    if (value.isEmpty) {
      perSystem.remove(key);
    } else {
      perSystem[key] = value;
    }
    notifyListeners();
    await _prefs.setString(_kCoreOptions, jsonEncode(_coreOptions));
  }

  /// Mapa chave -> valor com TODAS as opções do console (padrões
  /// incluídos), pronto para enviar à camada nativa ao abrir o jogo.
  Map<String, String> effectiveCoreOptions(String systemId) {
    final result = <String, String>{};
    for (final def in coreOptionDefsFor(systemId)) {
      result[def.key] = coreOptionValue(systemId, def);
    }
    return result;
  }
}
