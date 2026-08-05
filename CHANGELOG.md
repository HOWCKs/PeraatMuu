# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

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

[1.0.0]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.0.0
