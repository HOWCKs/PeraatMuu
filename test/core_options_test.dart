import 'package:flutter_test/flutter_test.dart';
import 'package:peraatmuu/models/console_system.dart';
import 'package:peraatmuu/models/core_option.dart';
import 'package:peraatmuu/services/bios_files.dart';
import 'package:peraatmuu/state/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defs de opções: só consoles mapeados e padrão é uma escolha válida',
      () {
    final ids = kConsoleCatalog.map((s) => s.id).toSet();
    for (final entry in kCoreOptionDefsBySystem.entries) {
      expect(ids.contains(entry.key), isTrue, reason: entry.key);
      for (final def in entry.value) {
        expect(def.choices, isNotEmpty, reason: def.key);
        expect(def.choices.map((c) => c.value), contains(def.defaultValue),
            reason: def.key);
        expect(def.choices.map((c) => c.value).toSet().length,
            def.choices.length, // sem valores duplicados
            reason: def.key);
      }
    }
    expect(coreOptionDefsFor('n64'), isNotEmpty);
    expect(coreOptionDefsFor('psp'), isNotEmpty);
    expect(coreOptionDefsFor('snes'), isEmpty);
  });

  test('AppSettings: padrão, persistência e mapa efetivo', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.init();

    final resolucao = kCoreOptionDefsBySystem['n64']!
        .firstWhere((d) => d.key == 'parallel-n64-screensize');
    // padrão antes de mexer
    expect(settings.coreOptionValue('n64', resolucao), '320x240');
    expect(settings.effectiveCoreOptions('snes'), isEmpty);

    await settings.setCoreOption(
        'n64', 'parallel-n64-screensize', '640x480');
    final efective = settings.effectiveCoreOptions('n64');
    expect(efective['parallel-n64-screensize'], '640x480');
    // demais opções do N64 entram com o padrão
    expect(efective['parallel-n64-angrylion-multithreading'], 'enabled');

    // recarrega do disco e confirma persistência
    final fresh = AppSettings();
    await fresh.init();
    expect(fresh.effectiveCoreOptions('n64')['parallel-n64-screensize'],
        '640x480');

    // valor vazio remove o override e volta ao padrão
    await fresh.setCoreOption('n64', 'parallel-n64-screensize', '');
    expect(fresh.coreOptionValue('n64', resolucao), '320x240');
  });

  test('BIOS: catálogo PS1, normalização e NDS sem exigência (DeSmuME)',
      () {
    expect(requiredBiosFilesFor('ps1'), contains('scph5501.bin'));
    // NDS agora usa DeSmuME — não exige BIOS (fim da tela branca)
    expect(requiredBiosFilesFor('nds'), isEmpty);
    expect(requiredBiosFilesFor('snes'), isEmpty);

    expect(canonicalBiosName('SCPH5501.BIN'), 'scph5501.bin');
    expect(canonicalBiosName('scph5501.bin'), 'scph5501.bin');
    expect(canonicalBiosName('qualquercoisa.bin'), isNull);

    final nds = kConsoleCatalog.firstWhere((s) => s.id == 'nds');
    expect(nds.requiresBios, isFalse);
    expect(nds.coreId, 'desmume');
  });

  test('novos consoles pesados: experimentais, com núcleo e trava 64-bit',
      () {
    for (final id in ['3ds', 'ps2', 'gcn', 'wii']) {
      final s = kConsoleCatalog.firstWhere((e) => e.id == id);
      expect(s.status, ConsoleStatus.experimental, reason: id);
      expect(s.coreId, isNotNull, reason: id);
      expect(s.hwRender, isTrue, reason: id);
      expect(s.arm64Only, isTrue, reason: id);
      expect(s.imageAsset.endsWith('$id.jpg'), isTrue, reason: id);
    }
    // .iso fica ambíguo de propósito: o app pergunta qual console
    expect(systemsForExtension('iso').map((s) => s.id),
        containsAll(['ps1', 'psp', 'ps2', 'gcn', 'wii']));
    // padrão da varredura de pastas continua PS1 (catálogo na frente)
    expect(kExtensionToSystem['iso'], 'ps1');
  });
}
