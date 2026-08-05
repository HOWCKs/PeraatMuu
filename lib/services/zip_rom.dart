import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/console_system.dart';

/// Utilidades para ROMs empacotadas em .zip.
///
/// A maioria das ROMs baixadas da internet vem zipada ("pokemon.zip",
/// "sonic (usa).zip"...). O PeraatMuu:
///   * na varredura, inspeciona o conteúdo do .zip para descobrir o console
///     (ver [detectSystemInZip]);
///   * na hora de jogar, extrai a ROM para o cache do app e alimenta o núcleo
///     com o arquivo extraído (ver [extractZipRom]).
///
/// Exceção: romsets de ARCADE (FinalBurn Neo) precisam continuar zipadas —
/// nesse caso o .zip vai direto para o núcleo.

/// Zips maiores que isso são ignorados na varredura (custo de leitura/decode).
const int kMaxZipScanBytes = 96 * 1024 * 1024;

/// .bin/.iso com no mínimo este tamanho é tratado como imagem de CD (PS1).
/// ROMs de cartucho raramente passam de alguns MB.
const int _cdImageMinBytes = 32 * 1024 * 1024;

/// Uma entrada de ROM reconhecível dentro de um .zip.
class ZipRomEntry {
  final String name; // caminho interno no zip
  final String systemId; // console detectado
  final int size; // bytes descomprimidos

  const ZipRomEntry(this.name, this.systemId, this.size);
}

class _ZipInspection {
  final List<ZipRomEntry> roms;
  final int totalFiles;
  const _ZipInspection(this.roms, this.totalFiles);
}

String _extOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Regra especial para .bin: cartucho pequeno (MD) vs imagem de CD (PS1).
String? _systemForZipEntry(String ext, int uncompressedSize) {
  if (ext == 'bin' || ext == 'iso' || ext == 'img') {
    return uncompressedSize >= _cdImageMinBytes ? 'ps1' : 'md';
  }
  return kExtensionToSystem[ext];
}

Future<_ZipInspection?> _readZip(File zipFile) async {
  try {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final roms = <ZipRomEntry>[];
    var files = 0;
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      files++;
      final name = entry.name;
      final base = name.split('/').last;
      if (base.startsWith('.') || name.contains('__MACOSX')) continue;
      final ext = _extOf(name);
      if (ext == 'zip' || ext.isEmpty) continue;
      final systemId = _systemForZipEntry(ext, entry.size);
      if (systemId == null) continue;
      roms.add(ZipRomEntry(name, systemId, entry.size));
    }
    return _ZipInspection(roms, files);
  } catch (_) {
    return null;
  }
}

/// Detecta o console de um arquivo .zip olhando o conteúdo.
/// Retorna o id do sistema ou null se nada reconhecível for encontrado.
///
/// Heurística para ARCADE: romsets do FinalBurn trazem vários arquivos com
/// nomes arbitrários (ex.: "mslug" -> p1.p1, s1.s1...). Se o zip tem 2+
/// arquivos e nenhum mapeia para um console, assumimos romset de arcade.
Future<String?> detectSystemInZip(String zipPath) async {
  final file = File(zipPath);
  try {
    if (!file.existsSync()) return null;
    if (await file.length() > kMaxZipScanBytes) return null;
  } catch (_) {
    return null;
  }
  final info = await _readZip(file);
  if (info == null) return null;
  if (info.roms.isEmpty) {
    return info.totalFiles >= 2 ? 'arcade' : null;
  }
  final roms = List<ZipRomEntry>.from(info.roms)
    ..sort((a, b) => b.size.compareTo(a.size));
  return roms.first.systemId;
}

/// Extrai a ROM principal de um .zip para o cache do app e retorna o caminho
/// do arquivo extraído (reutilizado nas próximas execuções).
///
/// Arquivos auxiliares do zip são extraídos lado a lado (necessário para
/// pares .cue/.bin, por exemplo). Retorna null se o zip não contém ROM
/// compatível com [systemId] ou se a extração falhar.
Future<String?> extractZipRom(
  String zipPath,
  String systemId, {
  Directory? cacheDir,
}) async {
  final file = File(zipPath);
  if (!file.existsSync()) return null;

  final info = await _readZip(file);
  if (info == null || info.roms.isEmpty) return null;

  // Prefere entrada do console pedido; senão a maior ROM reconhecida.
  final matches = info.roms.where((e) => e.systemId == systemId).toList();
  final pool = matches.isNotEmpty ? matches : info.roms;
  pool.sort((a, b) => b.size.compareTo(a.size));
  final target = pool.first;

  try {
    final root = cacheDir ?? await getTemporaryDirectory();
    final key = '${zipPath.hashCode.toRadixString(16)}_${file.lengthSync()}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final outDir = Directory('${root.path}/peraatmuu_roms/$key');
    final outFile = File('${outDir.path}/${target.name.split('/').last}');
    if (outFile.existsSync() && outFile.lengthSync() == target.size) {
      return outFile.path;
    }

    // (Re)extrai todos os arquivos do zip lado a lado (cue+bin, etc.).
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final data = entry.readBytes();
      if (data.isEmpty) continue;
      final dest = File('${outDir.path}/${entry.name.split('/').last}');
      dest.parent.createSync(recursive: true);
      dest.writeAsBytesSync(data, flush: false);
    }
    return outFile.existsSync() ? outFile.path : null;
  } catch (_) {
    return null;
  }
}

/// Limpa o cache de ROMs extraídas (chamado na inicialização do app).
/// Entradas velhas (mais de 7 dias) são removidas para não acumular.
Future<void> cleanZipRomCache() async {
  try {
    final root = await getTemporaryDirectory();
    final dir = Directory('${root.path}/peraatmuu_roms');
    if (!dir.existsSync()) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) await entity.delete();
      } catch (_) {
        // arquivo em uso ou sem acesso — ignora
      }
    }
  } catch (_) {
    // cache indisponível — não é crítico
  }
}
