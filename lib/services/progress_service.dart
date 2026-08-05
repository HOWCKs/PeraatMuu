import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

class ProgressService {
  static const String _key = 'peraatmuu_progress';

  static Future<UserProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return UserProgress();
    try {
      return UserProgress.fromJson(json.decode(raw));
    } catch (_) {
      return UserProgress();
    }
  }

  static Future<void> save(UserProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(p.toJson()));
  }

  static Future<void> addSession(SessionModel s) async {
    final p = await load();
    p.addSession(s);
    await save(p);
  }

  static Future<UserProgress> syncWithTermux() async {
    // Futuro: ler ~/ .peraatmuu/progress.json via path_provider + process
    // e mesclar com progresso local.
    return load();
  }
}
