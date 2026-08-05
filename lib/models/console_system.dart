import 'package:flutter/material.dart';

/// Situação de suporte de um console no app.
enum ConsoleStatus {
  /// Núcleo embutido e jogável (renderização por software).
  ready,

  /// Funciona, mas pode exigir BIOS/romsets específicos ou ter falhas.
  experimental,

  /// Planejado para a fase 2 (exigem renderização por hardware/OpenGL).
  soon,
}

/// Descreve um console/plataforma suportado pelo PeraatMuu.
class ConsoleSystem {
  final String id;
  final String name;
  final String shortName;
  final String maker;
  final int year;
  final List<String> extensions;

  /// Nome base do núcleo no buildbot libretro (ex.: `snes9x`).
  /// O arquivo final é `lib<coreId>_libretro_android.so` (ver [coreFileName]).
  /// IMPORTANTE: manter em sincronia com tools/download_cores.sh.
  final String? coreId;

  /// Nome de exibição do emulador (ex.: "Snes9x").
  final String? coreName;

  final List<Color> gradient;
  final IconData icon;
  final ConsoleStatus status;
  final bool requiresBios;
  final String notes;

  const ConsoleSystem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.maker,
    required this.year,
    required this.extensions,
    required this.gradient,
    required this.icon,
    required this.status,
    this.coreId,
    this.coreName,
    this.requiresBios = false,
    this.notes = '',
  });

  String get coreFile => coreId == null ? '' : coreFileName(coreId!);

  bool get playable => status != ConsoleStatus.soon && coreId != null;
}

/// Nome do arquivo do núcleo embutido no APK.
///
/// O prefixo `lib` é OBRIGATÓRIO: o gerenciador de pacotes do Android só
/// extrai arquivos `lib*.so` de `lib/<abi>/` para `nativeLibraryDir`
/// (usado pelo dlopen da ponte nativa).
String coreFileName(String coreId) => 'lib${coreId}_libretro_android.so';

/// Catálogo oficial de consoles do PeraatMuu.
const kConsoleCatalog = <ConsoleSystem>[
  ConsoleSystem(
    id: 'a26',
    name: 'Atari 2600',
    shortName: '2600',
    maker: 'Atari',
    year: 1977,
    extensions: ['a26'],
    coreId: 'stella',
    coreName: 'Stella',
    gradient: [Color(0xFFB34900), Color(0xFF3E1300)],
    icon: Icons.tv_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'nes',
    name: 'Nintendo Entertainment System',
    shortName: 'NES',
    maker: 'Nintendo',
    year: 1983,
    extensions: ['nes'],
    coreId: 'nestopia',
    coreName: 'Nestopia UE',
    gradient: [Color(0xFFD32F2F), Color(0xFF4A0E0E)],
    icon: Icons.gamepad_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'sms',
    name: 'Master System',
    shortName: 'SMS',
    maker: 'Sega',
    year: 1985,
    extensions: ['sms'],
    coreId: 'genesis_plus_gx',
    coreName: 'Genesis Plus GX',
    gradient: [Color(0xFF1565C0), Color(0xFF0A2040)],
    icon: Icons.sports_esports_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'pce',
    name: 'PC Engine',
    shortName: 'PCE',
    maker: 'NEC / Hudson',
    year: 1987,
    extensions: ['pce'],
    coreId: 'mednafen_pce_fast',
    coreName: 'Beetle PCE Fast',
    gradient: [Color(0xFFF57C00), Color(0xFF4A2400)],
    icon: Icons.sim_card_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'md',
    name: 'Mega Drive / Genesis',
    shortName: 'MD',
    maker: 'Sega',
    year: 1988,
    extensions: ['md', 'gen', 'smd', 'bin'],
    coreId: 'genesis_plus_gx',
    coreName: 'Genesis Plus GX',
    gradient: [Color(0xFF283593), Color(0xFF070B26)],
    icon: Icons.bolt_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'gb',
    name: 'Game Boy / Color',
    shortName: 'GB',
    maker: 'Nintendo',
    year: 1989,
    extensions: ['gb', 'gbc'],
    coreId: 'gambatte',
    coreName: 'Gambatte',
    gradient: [Color(0xFF2E7D32), Color(0xFF0C2A10)],
    icon: Icons.videogame_asset_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'lynx',
    name: 'Atari Lynx',
    shortName: 'LYNX',
    maker: 'Atari',
    year: 1989,
    extensions: ['lnx'],
    coreId: 'mednafen_lynx',
    coreName: 'Beetle Lynx',
    gradient: [Color(0xFFEF6C00), Color(0xFF331500)],
    icon: Icons.pets_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'snes',
    name: 'Super Nintendo',
    shortName: 'SNES',
    maker: 'Nintendo',
    year: 1990,
    extensions: ['smc', 'sfc', 'fig'],
    coreId: 'snes9x',
    coreName: 'Snes9x',
    gradient: [Color(0xFF6A1B9A), Color(0xFF1E062E)],
    icon: Icons.gamepad_outlined,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'gg',
    name: 'Game Gear',
    shortName: 'GG',
    maker: 'Sega',
    year: 1990,
    extensions: ['gg'],
    coreId: 'genesis_plus_gx',
    coreName: 'Genesis Plus GX',
    gradient: [Color(0xFF00838F), Color(0xFF052A30)],
    icon: Icons.phonelink_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'ngp',
    name: 'Neo Geo Pocket',
    shortName: 'NGP',
    maker: 'SNK',
    year: 1998,
    extensions: ['ngp', 'ngc'],
    coreId: 'mednafen_ngp',
    coreName: 'Beetle NeoPop',
    gradient: [Color(0xFFFBC02D), Color(0xFF3E2F04)],
    icon: Icons.casino_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'ws',
    name: 'WonderSwan',
    shortName: 'WS',
    maker: 'Bandai',
    year: 1999,
    extensions: ['ws', 'wsc'],
    coreId: 'mednafen_wswan',
    coreName: 'Beetle WonderSwan',
    gradient: [Color(0xFF90A4AE), Color(0xFF263238)],
    icon: Icons.auto_awesome_rounded,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'gba',
    name: 'Game Boy Advance',
    shortName: 'GBA',
    maker: 'Nintendo',
    year: 2001,
    extensions: ['gba', 'agb'],
    coreId: 'mgba',
    coreName: 'mGBA',
    gradient: [Color(0xFF3D5AFE), Color(0xFF0A1252)],
    icon: Icons.sports_esports_outlined,
    status: ConsoleStatus.ready,
  ),
  ConsoleSystem(
    id: 'arcade',
    name: 'Arcade (FinalBurn Neo)',
    shortName: 'ARCADE',
    maker: 'Vários',
    year: 1990,
    extensions: ['zip'],
    coreId: 'fbneo',
    coreName: 'FinalBurn Neo',
    gradient: [Color(0xFFFF5722), Color(0xFF3D0E00)],
    icon: Icons.local_fire_department_rounded,
    status: ConsoleStatus.experimental,
    notes:
        'Use romsets no formato do FinalBurn Neo (.zip). Nem todos os jogos rodam.',
  ),
  ConsoleSystem(
    id: 'ps1',
    name: 'PlayStation',
    shortName: 'PS1',
    maker: 'Sony',
    year: 1994,
    extensions: ['cue', 'chd', 'pbp', 'iso', 'img'],
    coreId: 'pcsx_rearmed',
    coreName: 'PCSX ReARMed',
    gradient: [Color(0xFF546E7A), Color(0xFF101C22)],
    icon: Icons.album_rounded,
    status: ConsoleStatus.experimental,
    requiresBios: true,
    notes:
        'Requer BIOS (ex.: scph5501.bin). Importe em Ajustes > BIOS. Formatos: .cue/.chd/.pbp.',
  ),
  ConsoleSystem(
    id: 'n64',
    name: 'Nintendo 64',
    shortName: 'N64',
    maker: 'Nintendo',
    year: 1996,
    extensions: ['z64', 'n64', 'v64'],
    coreId: 'mupen64plus_next',
    coreName: 'Mupen64Plus-Next',
    gradient: [Color(0xFF455A64), Color(0xFF11191D)],
    icon: Icons.view_in_ar_rounded,
    status: ConsoleStatus.soon,
    notes: 'Exige renderização por hardware (OpenGL). Chega na fase 2.',
  ),
  ConsoleSystem(
    id: 'psp',
    name: 'PlayStation Portable',
    shortName: 'PSP',
    maker: 'Sony',
    year: 2004,
    extensions: ['cso'],
    coreId: 'ppsspp',
    coreName: 'PPSSPP',
    gradient: [Color(0xFF37474F), Color(0xFF0D1316)],
    icon: Icons.smart_display_rounded,
    status: ConsoleStatus.soon,
    notes: 'Exige renderização por hardware (OpenGL/Vulkan). Chega na fase 2.',
  ),
  ConsoleSystem(
    id: 'nds',
    name: 'Nintendo DS',
    shortName: 'NDS',
    maker: 'Nintendo',
    year: 2004,
    extensions: ['nds'],
    coreId: 'melonds',
    coreName: 'melonDS',
    gradient: [Color(0xFF78909C), Color(0xFF1B252A)],
    icon: Icons.tablet_mac_rounded,
    status: ConsoleStatus.soon,
    notes: 'Suporte a dupla tela chega na fase 2.',
  ),
];

ConsoleSystem? consoleById(String id) {
  for (final system in kConsoleCatalog) {
    if (system.id == id) return system;
  }
  return null;
}

/// Mapa extensão (minúscula, sem ponto) -> id do sistema.
/// Sistemas "em breve" não são mapeados para evitar conflitos (ex.: .iso).
/// ".zip" também não: é um contêiner, inspecionado dinamicamente
/// (ver services/zip_rom.dart — ROM zipada é reconhecida pelo conteúdo).
final Map<String, String> kExtensionToSystem = () {
  final map = <String, String>{};
  for (final system in kConsoleCatalog) {
    if (system.status == ConsoleStatus.soon) continue;
    for (final ext in system.extensions) {
      if (ext.toLowerCase() == 'zip') continue;
      map.putIfAbsent(ext.toLowerCase(), () => system.id);
    }
  }
  return map;
}();

/// Ids de núcleo únicos usados pelo catálogo (consoles jogáveis).
List<String> get kUniqueCoreIds {
  final ids = <String>{};
  for (final system in kConsoleCatalog) {
    if (system.playable && system.coreId != null) ids.add(system.coreId!);
  }
  return ids.toList();
}
