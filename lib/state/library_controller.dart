import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/console_system.dart';
import '../models/game_entry.dart';

/// Biblioteca de ROMs do usuário: pastas monitoradas, varredura e persistência.
class LibraryController extends ChangeNotifier {
  final List<GameEntry> games = [];
  final List<String> folders = [];

  bool loading = true;
  bool scanning = false;
  String? lastError;

  File? _dbFile;

  // ------------------------------------------------------------------
  // Inicialização / persistência
  // ------------------------------------------------------------------

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _dbFile = File('${dir.path}/library.json');
      await _load();
    } catch (e) {
      lastError = 'Não foi possível ler a biblioteca: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _load() async {
    final file = _dbFile;
    if (file == null || !file.existsSync()) return;
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    folders
      ..clear()
      ..addAll((raw['folders'] as List<dynamic>? ?? [])
          .map((e) => e.toString()));
    games
      ..clear()
      ..addAll((raw['games'] as List<dynamic>? ?? []).map(
        (e) => GameEntry.fromJson(e as Map<String, dynamic>),
      ));
  }

  Future<void> _save() async {
    final file = _dbFile;
    if (file == null) return;
    final payload = jsonEncode({
      'folders': folders,
      'games': games.map((g) => g.toJson()).toList(),
    });
    await file.writeAsString(payload);
  }

  // ------------------------------------------------------------------
  // Permissões
  // ------------------------------------------------------------------

  Future<bool> ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final manage = await Permission.manageExternalStorage.status;
    if (manage.isGranted) return true;

    final requested = await Permission.manageExternalStorage.request();
    if (requested.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> openSystemSettings() => openAppSettings();

  // ------------------------------------------------------------------
  // Pastas e varredura
  // ------------------------------------------------------------------

  /// Abre o seletor de pasta, registra e varre. Retorna quantas ROMs novas
  /// foram encontradas, -1 se o usuário cancelou e -2 se faltar permissão.
  Future<int> addFolderAndScan() async {
    final allowed = await ensureStoragePermission();
    if (!allowed) {
      lastError = 'Permissão de armazenamento negada.';
      notifyListeners();
      return -2;
    }
    final path = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Escolha a pasta de ROMs');
    if (path == null || path.isEmpty) return -1;
    if (!folders.contains(path)) {
      folders.add(path);
    }
    final found = await rescanAll();
    return found;
  }

  /// Varre todas as pastas monitoradas. Retorna quantas ROMs NOVAS entraram.
  Future<int> rescanAll() async {
    if (scanning) return 0;
    scanning = true;
    lastError = null;
    notifyListeners();

    var added = 0;
    final known = games.map((g) => g.path).toSet();

    for (final folder in List<String>.from(folders)) {
      try {
        final dir = Directory(folder);
        if (!dir.existsSync()) {
          lastError = 'Pasta não encontrada: $folder';
          continue;
        }
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final path = entity.path;
          final dot = path.lastIndexOf('.');
          if (dot < 0) continue;
          final ext = path.substring(dot + 1).toLowerCase();
          final systemId = kExtensionToSystem[ext];
          if (systemId == null) continue;
          if (known.contains(path)) continue;
          try {
            final entry = GameEntry.fromFile(entity, systemId);
            games.add(entry);
            known.add(path);
            added++;
          } catch (_) {
            // Arquivo inacessível — ignora.
          }
        }
      } catch (e) {
        lastError = 'Erro ao varrer $folder: $e';
      }
    }

    _sortGames();
    scanning = false;
    notifyListeners();
    unawaited(_save());
    return added;
  }

  /// Remove ROMs cujo arquivo sumiu do dispositivo.
  Future<int> pruneMissing() async {
    final before = games.length;
    games.removeWhere((g) => !File(g.path).existsSync());
    _sortGames();
    notifyListeners();
    if (games.length != before) unawaited(_save());
    return before - games.length;
  }

  void removeFolder(String folder) {
    folders.remove(folder);
    games.removeWhere(
        (g) => g.path.startsWith(folder.endsWith('/') ? folder : '$folder/'));
    notifyListeners();
    unawaited(_save());
  }

  void removeGame(GameEntry game) {
    games.removeWhere((g) => g.path == game.path);
    notifyListeners();
    unawaited(_save());
  }

  Future<void> clearAll() async {
    games.clear();
    folders.clear();
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------------
  // Consultas
  // ------------------------------------------------------------------

  void markPlayed(GameEntry game) {
    game.lastPlayed = DateTime.now();
    notifyListeners();
    unawaited(_save());
  }

  List<GameEntry> gamesFor(String systemId) =>
      games.where((g) => g.systemId == systemId).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  int countFor(String systemId) =>
      games.where((g) => g.systemId == systemId).length;

  List<GameEntry> get recentPlayed => games
      .where((g) => g.lastPlayed != null)
      .toList()
    ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));

  List<GameEntry> get recentlyAdded => games.toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  List<GameEntry> search(String query, {String? systemId}) {
    final q = query.trim().toLowerCase();
    return games.where((g) {
      if (systemId != null && g.systemId != systemId) return false;
      if (q.isEmpty) return true;
      return g.title.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  void _sortGames() {
    games.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
}
