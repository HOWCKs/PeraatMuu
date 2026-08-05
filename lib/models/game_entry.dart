import 'dart:io';

/// Uma ROM encontrada no dispositivo e registrada na biblioteca.
class GameEntry {
  final String path;
  final String systemId;
  final String title;
  final int sizeBytes;
  final DateTime addedAt;
  DateTime? lastPlayed;

  GameEntry({
    required this.path,
    required this.systemId,
    required this.title,
    required this.sizeBytes,
    required this.addedAt,
    this.lastPlayed,
  });

  factory GameEntry.fromFile(File file, String systemId) {
    final name = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path.split('/').last;
    final dot = name.lastIndexOf('.');
    var base = dot > 0 ? name.substring(0, dot) : name;
    // Limpa tags comuns de ROM: "Game (USA) [!]" -> "Game"
    base = base
        .replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]'), '')
        .replaceAll('_', ' ')
        .trim();
    if (base.isEmpty) base = name;
    final now = DateTime.now();
    return GameEntry(
      path: file.path,
      systemId: systemId,
      title: base,
      sizeBytes: file.lengthSync(),
      addedAt: now,
    );
  }

  String get sizeLabel {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'systemId': systemId,
        'title': title,
        'sizeBytes': sizeBytes,
        'addedAt': addedAt.toIso8601String(),
        'lastPlayed': lastPlayed?.toIso8601String(),
      };

  factory GameEntry.fromJson(Map<String, dynamic> json) => GameEntry(
        path: json['path'] as String? ?? '',
        systemId: json['systemId'] as String? ?? '',
        title: json['title'] as String? ?? 'Sem título',
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
        lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? ''),
      );
}
