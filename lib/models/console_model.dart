class ConsoleModel {
  final String id;
  final String name;
  final String fullName;
  final String manufacturer;
  final String description;
  final String imageAsset;
  final bool isAvailable;
  final int maxControllers;
  final String nativeLibName; // libnes.so, libmgba.so, etc.

  const ConsoleModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.manufacturer,
    required this.description,
    required this.imageAsset,
    this.isAvailable = true,
    this.maxControllers = 4,
    required this.nativeLibName,
  });

  static final List<ConsoleModel> consoles = [
    ConsoleModel(
      id: 'nes',
      name: 'NES',
      fullName: 'Nintendo Entertainment System',
      manufacturer: 'Nintendo',
      description: '8-bit clássicos. Super Mario, The Legend of Zelda.',
      imageAsset: 'assets/images/nes.png',
      nativeLibName: 'libnes.so',
    ),
    ConsoleModel(
      id: 'snes',
      name: 'SNES',
      fullName: 'Super Nintendo',
      manufacturer: 'Nintendo',
      description: '16-bit. Donkey Kong Country, Chrono Trigger.',
      imageAsset: 'assets/images/snes.png',
      nativeLibName: 'libsnes.so',
    ),
    ConsoleModel(
      id: 'gba',
      name: 'GBA',
      fullName: 'Game Boy Advance',
      manufacturer: 'Nintendo',
      description: '32-bit portátil. Pokémon, Metroid Fusion.',
      imageAsset: 'assets/images/gba.png',
      nativeLibName: 'libmgba.so',
    ),
    ConsoleModel(
      id: 'ps1',
      name: 'PS1',
      fullName: 'PlayStation 1',
      manufacturer: 'Sony',
      description: '32-bit. Final Fantasy VII, Crash Bandicoot.',
      imageAsset: 'assets/images/ps1.png',
      nativeLibName: 'libpcsx_rearmed.so',
    ),
    ConsoleModel(
      id: 'md',
      name: 'Mega Drive',
      fullName: 'Sega Genesis',
      manufacturer: 'Sega',
      description: '16-bit. Sonic, Streets of Rage.',
      imageAsset: 'assets/images/md.png',
      nativeLibName: 'libgenplus.so',
    ),
  ];
}
