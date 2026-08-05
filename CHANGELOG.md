# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [1.0.1] - 2026-08-05

### Corrigido
- **Núcleos invisíveis no app (crítico):** os arquivos `.so` dos núcleos iam
  para o APK com o nome do buildbot (`snes9x_libretro_android.so`), mas o
  Android só extrai libs com prefixo `lib` de `lib/<abi>/` para
  `nativeLibraryDir`. Resultado: todos os núcleos apareciam como "ausente"
  em Ajustes e nenhum jogo iniciava. Agora o download renomeia para
  `lib<snes9x>_libretro_android.so` (`tools/download_cores.sh`) e o app
  procura pelo novo nome.

### Adicionado
- **ROMs em .zip:** a varredura abre cada `.zip` e detecta o console pela
  extensão da ROM interna (ex.: "pokemon.zip" com ".gb" dentro → Game Boy).
  `.bin`/`.iso` acima de 32 MB é tratado como imagem de PS1; romsets de
  arcade (chunks sem extensão conhecida) viram ARCADE. Na primeira jogada a
  ROM é extraída automaticamente para o cache (pares `.cue`/`.bin` vão
  juntos) e reutilizada nas próximas.
- **Atualização automática da biblioteca:** baixou uma ROM nova pelo
  navegador ou moveu arquivos no gerenciador? Ao voltar para o app a
  biblioteca varre as pastas monitoradas sozinha — sem tocar em reescanear.
- Seletor de pastas agora converte URIs `content://` do SAF em caminhos
  reais (ex.: "Download" → `/storage/emulated/0/Download`).
- Limpeza automática do cache de extrações com mais de 7 dias.
- Testes unitários da detecção/extração de zips (test/zip_rom_test.dart).

## [1.0.0] - 2026-08-05

### Adicionado
- App Flutter com tema gamer/neon (cards 3D com tilt, grid synthwave animado,
  fontes Audiowide + Rajdhani sob OFL).
- Agregador com 17 consoles no catálogo (12 prontos, 2 experimentais, 3 "em breve").
- Emulação real via núcleos libretro oficiais embutidos no APK (ponte JNI/C++
  própria: vídeo RGBA, áudio PCM, entrada joypad, save states e SRAM).
- Controles virtuais multitoque na tela + gamepads físicos Bluetooth/USB.
- Biblioteca de ROMs: pastas monitoradas, varredura automática, busca e filtros.
- Importação de BIOS (PlayStation) para a pasta do sistema.
- Build no GitHub Actions com APK release por ABI como artefato baixável;
  releases automáticas em tags `v*`.
- Guia completo de uso via Termux (docs/TERMUX.md).

[1.0.1]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.0.1
[1.0.0]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.0.0
