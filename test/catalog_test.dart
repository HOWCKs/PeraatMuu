import 'package:flutter_test/flutter_test.dart';
import 'package:peraatmuu/models/console_system.dart';

void main() {
  test('catálogo não está vazio e ids são únicos', () {
    expect(kConsoleCatalog.isNotEmpty, isTrue);
    final ids = kConsoleCatalog.map((e) => e.id).toSet();
    expect(ids.length, kConsoleCatalog.length);
  });

  test('todo console jogável tem núcleo e extensões definidas', () {
    for (final system in kConsoleCatalog.where((s) => s.playable)) {
      expect(system.coreId, isNotNull, reason: system.id);
      expect(system.coreName, isNotNull, reason: system.id);
      expect(system.extensions, isNotEmpty, reason: system.id);
      expect(system.coreFile, endsWith('_libretro_android.so'));
    }
  });

  test('extensões mapeiam apenas para sistemas existentes', () {
    final ids = kConsoleCatalog.map((e) => e.id).toSet();
    for (final entry in kExtensionToSystem.entries) {
      expect(ids.contains(entry.value), isTrue, reason: entry.key);
      expect(entry.key, isNotEmpty);
    }
  });

  test('ids de núcleo únicos batem com o catálogo', () {
    final ids = kUniqueCoreIds;
    expect(ids.toSet().length, ids.length);
    // Lista usada por tools/download_cores.sh
    expect(ids, containsAll(<String>['snes9x', 'mgba', 'nestopia', 'stella']));
  });
}
