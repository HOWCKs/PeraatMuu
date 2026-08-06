/// Catálogo de arquivos de BIOS reconhecidos pelo PeraatMuu.
///
/// O PeraatMuu NÃO distribui BIOS — o usuário deve extrair do próprio
/// console. Os arquivos ficam na pasta interna `system/` (a mesma que os
/// núcleos libretro consultam via RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY).
library;

/// Consoles -> nomes canônicos de BIOS aceitos.
const Map<String, List<String>> kBiosFilesBySystem = {
  'ps1': ['scph5501.bin', 'scph7001.bin', 'scph1001.bin'],
  'nds': ['bios7.bin', 'bios9.bin', 'firmware.bin'],
};

/// Tamanhos esperados (em KB) só para exibição/ajuda ao usuário.
const Map<String, int> kBiosExpectedKb = {
  'bios7.bin': 16,
  'bios9.bin': 4,
  'firmware.bin': 256,
  'scph5501.bin': 512,
  'scph7001.bin': 512,
  'scph1001.bin': 512,
};

/// Apelidos comuns encontrados em dumps da internet -> nome canônico.
/// Dumps de DS, por exemplo, costumam vir como `biosnds9.bin`.
const Map<String, String> kBiosAliases = {
  'biosnds7.bin': 'bios7.bin',
  'biosnds9.bin': 'bios9.bin',
  'dsfirmware.bin': 'firmware.bin',
  'ds_firmware.bin': 'firmware.bin',
};

/// BIOS requeridas por um console (lista vazia = não exige).
List<String> requiredBiosFilesFor(String systemId) =>
    kBiosFilesBySystem[systemId] ?? const [];

/// Nome canônico de um arquivo de BIOS importado: minúsculas e com
/// apelidos conhecidos normalizados. Retorna null se não reconhecemos.
String? canonicalBiosName(String fileName) {
  final lower = fileName.toLowerCase();
  final alias = kBiosAliases[lower];
  if (alias != null) return alias;
  for (final files in kBiosFilesBySystem.values) {
    if (files.contains(lower)) return lower;
  }
  return null;
}

/// Todos os nomes canônicos (para a tela de Ajustes listar status).
List<String> get allBiosNames => [
      ...kBiosFilesBySystem['ps1']!,
      ...kBiosFilesBySystem['nds']!,
    ];
