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

  test('BIOS: catálogo do NDS e normalização de nomes de dumps', () {
    expect(requiredBiosFilesFor('nds'),
        ['bios7.bin', 'bios9.bin', 'firmware.bin']);
    expect(requiredBiosFilesFor('snes'), isEmpty);

    expect(canonicalBiosName('BIOS7.BIN'), 'bios7.bin');
    expect(canonicalBiosName('biosnds9.bin'), 'bios9.bin');
    expect(canonicalBiosName('DSFirmware.bin'), 'firmware.bin');
    expect(canonicalBiosName('scph5501.bin'), 'scph5501.bin');
    expect(canonicalBiosName('qualquercoisa.bin'), isNull);

    // NDS marcado como exigindo BIOS (tela branca sem ela)
    final nds = kConsoleCatalog.firstWhere((s) => s.id == 'nds');
    expect(nds.requiresBios, isTrue);
  });
}
