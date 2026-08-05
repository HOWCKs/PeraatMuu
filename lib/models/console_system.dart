import 'package:flutter/material.dart';

/// Situação de suporte de um console no app.
enum ConsoleStatus {
  /// Núcleo embutido e jogável (renderização por software).
  ready,

  /// Funciona, mas pode exigir BIOS/romsets específicos, GPU por hardware
  /// ou um aparelho mais forte que o mínimo.
  experimental,

  /// Planejado para uma versão futura.
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

  /// Texto amigável explicando o que o console é (mostrado no painel de info).
  final String description;

  /// O console tem tela sensível ao toque (interação direta no jogo).
  final bool touchScreen;

  /// O núcleo precisa de renderização por hardware (GPU/OpenGL).
  final bool hwRender;

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
    this.description = '',
    this.touchScreen = false,
    this.hwRender = false,
  });

  String get coreFile => coreId == null ? '' : coreFileName(coreId!);

  bool get playable => status != ConsoleStatus.soon && coreId != null;

  /// Emblema do console (assets/consoles/<id>.jpg).
  String get imageAsset => 'assets/consoles/$id.jpg';
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
    description:
        'O vovô dos videogames (1977)! Jogos simples e viciantes de '
        'fichinha, com gráficos quadradinhos cheios de charme.',
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
    description:
        'O Nintendinho! Salvou a indústria dos games em 1983. É a casa de '
        'Mario, Zelda e Mega Man clássicos.',
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
    description:
        'O rival do Nintendinho da Sega. Fez muito sucesso no Brasil — '
        'Alex Kidd e Sonic 8-bits marcaram infância por aqui.',
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
    description:
        'Console japonês com jogos em cartão. Famoso pelos jogos de nave '
        '(shoot’em ups) e RPGs coloridos.',
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
    description:
        'O 16-bits da Sega. No Brasil foi febre absoluta: Sonic, Streets '
        'of Rage, Golden Axe e muito mais.',
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
    description:
        'O primeiro portátil campeão de vendas. Telinha verde, pilhas AA '
        'e clássicos como Tetris e Pokémon.',
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
    description:
        'Primeiro portátil do mundo com tela colorida (1989). Era enorme '
        'e bebia pilha — mas era potente pra época.',
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
    description:
        'O 16-bits da Nintendo, com alguns dos melhores jogos já feitos: '
        'Mario World, Donkey Kong Country, Chrono Trigger.',
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
    description:
        'Portátil colorido da Sega de 1990. Rival do Game Boy, com tela '
        'retroiluminada e muitos jogos do Master System.',
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
    description:
        'Portátil da SNK com joguinhos de luta ótimos e o famoso '
        '"micro joystick" clicável.',
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
    description:
        'Portátil japonês da Bandai criado pelo pai do Game Boy. Dá pra '
        'jogar na vertical ou na horizontal.',
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
    description:
        'O portátil 32-bits da Nintendo. Pokémon, Castlevania, Metroid — '
        'biblioteca gigante e amada até hoje.',
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
        'Use romsets no formato do FinalBurn Neo (.zip). Nem todos os '
        'jogos rodam.',
    description:
        'As máquinas de fliperama! Metal Slug, The King of Fighters, '
        'Cadillacs and Dinosaurs. Cada jogo precisa do romset exato.',
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
        'Requer BIOS (ex.: scph5501.bin). Importe em Ajustes > BIOS. '
        'Formatos: .cue/.chd/.pbp.',
    description:
        'O primeiro PlayStation, rei dos CDs nos anos 90: Resident Evil, '
        'Crash Bandicoot, Final Fantasy VII.',
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
    status: ConsoleStatus.experimental,
    touchScreen: true,
    notes:
        'Duas telas empilhadas. Toque na metade de BAIXO da tela para usar '
        'a caneta (touch).',
    description:
        'Duas telas, sendo a de baixo sensível ao toque! Casa de Mario '
        'Kart DS, Pokémon HeartGold e Castlevania. A interação por toque '
        'já funciona no PeraatMuu.',
  ),
  ConsoleSystem(
    id: 'psp',
    name: 'PlayStation Portable',
    shortName: 'PSP',
    maker: 'Sony',
    year: 2004,
    extensions: ['cso', 'iso', 'pbp'],
    coreId: 'ppsspp',
    coreName: 'PPSSPP',
    gradient: [Color(0xFF37474F), Color(0xFF0D1316)],
    icon: Icons.smart_display_rounded,
    status: ConsoleStatus.experimental,
    hwRender: true,
    notes:
        'Exige GPU (OpenGL). No seu aparelho, prefira jogos leves/2D. '
        'Use .cso; para .iso/.pbp, adicione pelo botão ＋ e escolha PSP.',
    description:
        'O portátil parrudo da Sony (2004), quase um PS2 de bolso: God '
        'of War, GTA, Daxter. Roda via GPU — jogos pesados podem ficar '
        'lentos em aparelhos simples.',
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
    status: ConsoleStatus.experimental,
    hwRender: true,
    notes: 'Exige GPU (OpenGL). Pode engasgar em aparelhos de entrada.',
    description:
        'O 64-bits da Nintendo dos cartuchos: Mario 64, Zelda Ocarina of '
        'Time, GoldenEye 007. Roda via GPU — desempenho varia bastante '
        'por aparelho.',
  ),
  ConsoleSystem(
    id: '3ds',
    name: 'Nintendo 3DS',
    shortName: '3DS',
    maker: 'Nintendo',
    year: 2011,
    extensions: ['3ds', 'cci', 'cxi'],
    coreId: 'citra',
    coreName: 'Citra',
    gradient: [Color(0xFF00ACC1), Color(0xFF04333B)],
    icon: Icons.layers_rounded,
    status: ConsoleStatus.soon,
    notes:
        'O núcleo Citra só existe para aparelhos 64-bit com GPU forte. '
        'Chega em versão futura.',
    description:
        'Sucessor do DS com 3D sem óculos. A emulação só roda bem em '
        'celulares 64-bit potentes — por isso ficou para uma próxima fase.',
  ),
  ConsoleSystem(
    id: 'ps2',
    name: 'PlayStation 2',
    shortName: 'PS2',
    maker: 'Sony',
    year: 2000,
    extensions: ['mdf', 'isz'],
    coreId: 'play',
    coreName: 'Play!',
    gradient: [Color(0xFF1A237E), Color(0xFF05061F)],
    icon: Icons.dns_rounded,
    status: ConsoleStatus.soon,
    notes:
        'PS2 exige muito hardware (64-bit + GPU forte). Estamos estudando '
        'a viabilidade — sem previsão.',
    description:
        'O console mais vendido da história! Emular PS2 é pesadíssimo: '
        'só celulares 64-bit parrudos conseguem.',
  ),
  ConsoleSystem(
    id: 'gcn',
    name: 'Nintendo GameCube',
    shortName: 'GCN',
    maker: 'Nintendo',
    year: 2001,
    extensions: ['gcm', 'rvz'],
    coreId: 'dolphin',
    coreName: 'Dolphin',
    gradient: [Color(0xFF6A3FB5), Color(0xFF1C0F38)],
    icon: Icons.deployed_code_rounded,
    status: ConsoleStatus.soon,
    notes:
        'O núcleo Dolphin é 64-bit only e pesado. Chega quando suportarmos '
        'aparelhos 64-bit.',
    description:
        'O cubinho roxo da Nintendo: Mario Sunshine, Smash Bros. Melee. '
        'O núcleo Dolphin precisa de celular 64-bit forte.',
  ),
  ConsoleSystem(
    id: 'wii',
    name: 'Nintendo Wii',
    shortName: 'WII',
    maker: 'Nintendo',
    year: 2006,
    extensions: ['wbfs'],
    coreId: 'dolphin',
    coreName: 'Dolphin',
    gradient: [Color(0xFFB0BEC5), Color(0xFF37474F)],
    icon: Icons.wifi_tethering_rounded,
    status: ConsoleStatus.soon,
    notes:
        'Divide o núcleo Dolphin com o GameCube (64-bit only). '
        'Chega em versão futura.',
    description:
        'O console dos controles de movimento da Nintendo. Usa o mesmo '
        'núcleo do GameCube, que exige aparelho 64-bit parrudo.',
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

/// Extensões com mais de um dono (ex.: .iso = PS1 ou PSP).
/// Usadas para perguntar ao usuário qual console ele quer ao adicionar
/// um arquivo único (ver widgets/library_actions.dart).
List<ConsoleSystem> systemsForExtension(String ext) {
  final e = ext.toLowerCase();
  return kConsoleCatalog
      .where((s) =>
          s.status != ConsoleStatus.soon &&
          s.extensions.map((x) => x.toLowerCase()).contains(e))
      .toList();
}

/// Ids de núcleo únicos usados pelo catálogo (consoles jogáveis).
List<String> get kUniqueCoreIds {
  final ids = <String>{};
  for (final system in kConsoleCatalog) {
    if (system.playable && system.coreId != null) ids.add(system.coreId!);
  }
  return ids.toList();
}

/// Extensões de ROM aceitas no seletor de arquivo único
/// (inclui o contêiner .zip). Usada pelo FilePicker.
List<String> get kRomFileExtensions {
  final exts = <String>{'zip'};
  for (final system in kConsoleCatalog) {
    if (system.status == ConsoleStatus.soon) continue;
    for (final ext in system.extensions) {
      exts.add(ext.toLowerCase());
    }
  }
  return exts.toList()..sort();
}
