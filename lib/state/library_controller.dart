import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/console_system.dart';
import '../models/game_entry.dart';
import '../services/zip_rom.dart';

/// Converte o resultado do seletor de pastas em caminho real do sistema.
/// No Android o seletor pode devolver uma URI content:// (SAF); este helper
/// mapeia pastas do armazenamento interno para /storage/emulated/0/...
/// Retorna null quando não conseguimos resolver (ex.: cartão SD externo).
String? normalizePickedPath(String picked) {
  if (!picked.startsWith('content://')) return picked;
  final decoded = Uri.decodeComponent(picked);
  final match = RegExp(r'/tree/primary:(.*)$').firstMatch(decoded);
  if (match == null) return null;
  final sub = match.group(1)!;
  return sub.isEmpty ? '/storage/emulated/0' : '/storage/emulated/0/$sub';
}

/// Biblioteca de ROMs do usuário: pastas monitoradas, varredura e persistência.
class LibraryController extends ChangeNotifier {
  final List<GameEntry> games = [];
  final List<String> folders = [];

  /// Escolha manual de console por arquivo, para extensões ambíguas
  /// (ex.: .iso serve para PS1 e PSP). Chave = caminho do arquivo.
  final Map<String, String> fileOverrides = {};

  /// Pergunta à UI qual console usar num arquivo ambíguo (configurada
  /// temporariamente pelos fluxos de adicionar ROM).
  Future<String?> Function(String path, List<ConsoleSystem> candidates)?
      overrideChooser;

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
    fileOverrides
      ..clear()
      ..addAll((raw['overrides'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())));
  }

  Future<void> _save() async {
    final file = _dbFile;
    if (file == null) return;
    final payload = jsonEncode({
      'folders': folders,
      'games': games.map((g) => g.toJson()).toList(),
      'overrides': fileOverrides,
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
    final picked = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Escolha a pasta de ROMs');
    if (picked == null || picked.isEmpty) return -1;
    final path = normalizePickedPath(picked);
    if (path == null) {
      lastError = 'Não foi possível acessar essa pasta. '
          'Escolha uma pasta do armazenamento interno (ex.: Download).';
      notifyListeners();
      return -3;
    }
    if (!folders.contains(path)) {
      folders.add(path);
    }
    final found = await rescanAll();
    return found;
  }

  /// Abre o seletor de ARQUIVO do Android (permite tocar direto na ROM!).
  /// Cada arquivo escolhido registra automaticamente a pasta onde ele está
  /// na lista monitorada — futuras ROMs naquela pasta passam a aparecer
  /// sozinhas. Arquivos que o Android só entrega como cópia temporária são
  /// importados para uma pasta própria do app.
  /// Retorna quantos jogos novos entraram, -1 = cancelou, -2 = sem permissão.
  Future<int> addSingleFile() async {
    final allowed = await ensureStoragePermission();
    if (!allowed) {
      lastError = 'Permissão de armazenamento negada.';
      notifyListeners();
      return -2;
    }
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Escolha suas ROMs',
      type: FileType.custom,
      allowedExtensions: kRomFileExtensions,
      allowMultiple: true,
    );
    if (result == null || result.count == 0) return -1;

    final parentDirs = <String>{};
    var importedAny = false;
    final cacheRoot = (await getTemporaryDirectory()).path;

    for (final picked in result.files) {
      final raw = picked.path;
      if (raw == null || raw.isEmpty) continue;
      var path = normalizePickedPath(raw) ?? raw;
      var file = File(path);
      if (!file.existsSync()) continue;

      if (path.startsWith(cacheRoot)) {
        // Cópia temporária do SAF: importa para pasta própria monitorada.
        final docs = await getApplicationDocumentsDirectory();
        final importDir = Directory('${docs.path}/roms_import')
          ..createSync(recursive: true);
        final name =
            picked.name.isNotEmpty ? picked.name : file.uri.pathSegments.last;
        final dest = File('${importDir.path}/$name');
        if (dest.existsSync()) dest.deleteSync();
        file = await file.copy(dest.path);
        await _maybeOverride(path: dest.path);
        parentDirs.add(importDir.path);
        importedAny = true;
        continue;
      }
      await _maybeOverride(path: path);
      final slash = path.lastIndexOf('/');
      if (slash <= 0) continue;
      parentDirs.add(path.substring(0, slash));
    }

    if (parentDirs.isEmpty) return -1;
    for (final dir in parentDirs) {
      if (!folders.contains(dir)) folders.add(dir);
    }
    final added = await rescanAll();
    // Se só importamos cópias e nada entrou, ao menos avise.
    if (added == 0 && importedAny) {
      lastError = 'Arquivo importado, mas não reconhecido como ROM.';
    }
    return added;
  }

  /// Extensão com mais de um dono? Pergunta ao usuário (via UI) e grava.
  Future<void> _maybeOverride({required String path}) async {
    final chooser = overrideChooser;
    if (chooser == null) return;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return;
    final candidates = systemsForExtension(path.substring(dot + 1));
    if (candidates.length < 2) return;
    final chosen = await chooser(path, candidates);
    if (chosen != null && chosen.isNotEmpty) {
      fileOverrides[path] = chosen;
    }
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
          // ".zip" é avaliado pelo CONTEÚDO (ROMs baixadas quase sempre vêm zipadas).
          // Escolha manual do usuário vence a inferência por extensão.
          final systemId = ext == 'zip'
              ? await detectSystemInZip(path)
              : (fileOverrides[path] ?? kExtensionToSystem[ext]);
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
