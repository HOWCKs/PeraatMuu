import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peraatmuu/services/zip_rom.dart';

Future<File> _makeZip(Map<String, List<int>> entries, String id) async {
  final archive = Archive();
  entries.forEach((name, data) {
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  final bytes = ZipEncoder().encode(archive)!;
  final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}peraatmuu_test_$id.zip');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

List<int> _zeros(int n) => List<int>.filled(n, 0);

void main() {
  group('detectSystemInZip', () {
    test('zip com ROM de Game Boy detecta "gb"', () async {
      final zip = await _makeZip(
        {'Pokemon Blue (UE) (S)[!].gb': _zeros(32768)},
        'gb',
      );
      expect(await detectSystemInZip(zip.path), 'gb');
    });

    test('zip com ROM de GBA detecta "gba"', () async {
      final zip = await _makeZip({'Emerald.gba': _zeros(16384)}, 'gba');
      expect(await detectSystemInZip(zip.path), 'gba');
    });

    test('.bin pequeno dentro do zip é Mega Drive', () async {
      final zip = await _makeZip({'Sonic (USA).bin': _zeros(4 * 1024)}, 'md');
      expect(await detectSystemInZip(zip.path), 'md');
    });

    test('.bin grande dentro do zip é imagem de PS1', () async {
      final zip = await _makeZip(
        {'Game.cue': _zeros(128), 'Game.bin': _zeros(33 * 1024 * 1024)},
        'cd',
      );
      expect(await detectSystemInZip(zip.path), 'ps1');
    });

    test('.sfc (SNES) junto com lixo escolhe a ROM certa', () async {
      final zip = await _makeZip({
        '__MACOSX/._junk': _zeros(8),
        'readme.txt': _zeros(10),
        'Zelda (USA).sfc': _zeros(2 * 1024 * 1024),
      }, 'multi');
      expect(await detectSystemInZip(zip.path), 'snes');
    });

    test('romset de arcade (chunks sem extensão conhecida) vira "arcade"',
        () async {
      final zip = await _makeZip({
        '201-p1.p1': _zeros(4096),
        '201-s1.s1': _zeros(2048),
        '201-m1.m1': _zeros(1024),
      }, 'arcade');
      expect(await detectSystemInZip(zip.path), 'arcade');
    });

    test('zip com um arquivo desconhecido retorna null', () async {
      final zip = await _makeZip({'documento.pdf': _zeros(64)}, 'pdf');
      expect(await detectSystemInZip(zip.path), isNull);
    });

    test('arquivo que não é zip retorna null', () async {
      final fake = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}peraatmuu_test_fake.gb');
      await fake.writeAsString('isso nao e um zip de verdade');
      expect(await detectSystemInZip(fake.path), isNull);
    });
  });

  group('extractZipRom', () {
    test('extrai a ROM e reutiliza o cache', () async {
      final dir = await Directory.systemTemp.createTemp('peraatmuu_cache_test');
      final romBytes = List<int>.generate(4096, (i) => i % 251);
      final zip = await _makeZip({'Mario (World).nes': romBytes}, 'nes');

      final path = await extractZipRom(zip.path, 'nes', cacheDir: dir);
      expect(path, isNotNull);
      final out = File(path!);
      expect(out.existsSync(), isTrue);
      expect(out.readAsBytesSync(), romBytes);

      // Segunda chamada devolve o mesmo caminho (cache).
      expect(await extractZipRom(zip.path, 'nes', cacheDir: dir), path);
    });

    test('extrai cue+bin lado a lado (par de CD)', () async {
      final dir = await Directory.systemTemp.createTemp('peraatmuu_cache_test2');
      final zip = await _makeZip({
        'Game.cue': 'FILE "Game.bin" BINARY'.codeUnits,
        'Game.bin': _zeros(33 * 1024 * 1024),
      }, 'cuebin');

      final path = await extractZipRom(zip.path, 'ps1', cacheDir: dir);
      expect(path, isNotNull);
      final out = File(path!);
      expect(out.uri.pathSegments.last, 'Game.bin');
      expect(File('${out.parent.path}/Game.cue').existsSync(), isTrue);
    });
  });
}
