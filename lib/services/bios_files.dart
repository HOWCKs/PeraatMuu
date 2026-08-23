/// Catálogo de arquivos de BIOS reconhecidos pelo PeraatMuu.
///
/// O PeraatMuu NÃO distribui BIOS — o usuário deve extrair do próprio
/// console. Os arquivos ficam na pasta interna `system/` (a mesma que os
/// núcleos libretro consultam via RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY).
library;

/// Consoles -> nomes canônicos de BIOS aceitos.
/// NDS usa DeSmuME (não precisa de BIOS) e PS2 usa Play! (também sem BIOS).
const Map<String, List<String>> kBiosFilesBySystem = {
  'ps1': ['scph5501.bin', 'scph7001.bin', 'scph1001.bin'],
};

/// Tamanhos esperados (em KB) só para exibição/ajuda ao usuário.
const Map<String, int> kBiosExpectedKb = {
  'scph5501.bin': 512,
  'scph7001.bin': 512,
  'scph1001.bin': 512,
};

/// Apelidos comuns encontrados em dumps da internet -> nome canônico.
const Map<String, String> kBiosAliases = {};

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
  // BIOS de DS de versões antigas (DeSmuME atual não usa — aceitamos e
  // guardamos; algum núcleo futuro pode aproveitar).
  const legacyDs = {'bios7.bin', 'bios9.bin', 'firmware.bin'};
  if (legacyDs.contains(lower)) return lower;
  return null;
}

/// Todos os nomes canônicos (para a tela de Ajustes listar status).
List<String> get allBiosNames => [...kBiosFilesBySystem['ps1']!];
