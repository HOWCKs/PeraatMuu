import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências globais do app (persistidas no dispositivo).
class AppSettings extends ChangeNotifier {
  static const _kReducedEffects = 'reduced_effects';

  late SharedPreferences _prefs;
  bool _loaded = false;

  /// Páginas mais leves: sem varredura animada, sem tilt 3D nos cards.
  /// Ligado por padrão — a experiência fica visivelmente mais fluida em
  /// aparelhos de entrada.
  bool _reducedEffects = true;

  bool get loaded => _loaded;
  bool get reducedEffects => _reducedEffects;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _reducedEffects = _prefs.getBool(_kReducedEffects) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setReducedEffects(bool value) async {
    _reducedEffects = value;
    notifyListeners();
    await _prefs.setBool(_kReducedEffects, value);
  }
}
