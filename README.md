# 🎮 PeraatMuu

> **Todos os consoles. Um só app.**
> Agregador de emuladores retrô para Android, feito em Flutter, com emulação **real** via núcleos libretro embutidos — compilado 100% no GitHub Actions, com APK baixável a cada versão.

![Flutter](https://img.shields.io/badge/Flutter-stable-00F5D4) ![Android](https://img.shields.io/badge/Android-8.0%2B-7B2FFF) ![Núcleos](https://img.shields.io/badge/núcleos-libretro-FF2E88)

---

## ✨ O que é

O PeraatMuu é uma central única de emulação: em vez de instalar um app de emulador para cada console, você instala **um APK** que já traz os emuladores de verdade embutidos (núcleos oficiais do [libretro](https://www.libretro.com/)), com:

- 🕹️ **Emulação real**, não simulada: ponte JNI nativa (`retrobridge`) que carrega os núcleos libretro com `dlopen` e executa `retro_run` em thread dedicada;
- 📺 **Renderização OpenGL ES 2** com correção de proporção (letterbox);
- 🔊 **Áudio PCM** via AudioTrack com buffer que regula o ritmo da emulação;
- 🎯 **Controles virtuais neon** na tela (multitoque: d-pad + A/B/X/Y + L/R + Start/Select) **e suporte a gamepads físicos** Bluetooth/USB, incluindo analógico;
- 💾 **Save states** (salvar/carregar pelo menu ≡) e **SRAM** (save da bateria) salva automaticamente;
- 🗂️ **Biblioteca inteligente**: aponte a pasta das suas ROMs e o app organiza tudo por console automaticamente;
- 🌌 **Interface gamer 3D**: cards com tilt em perspectiva, grid synthwave animado, tema neon (fontes Audiowide + Rajdhani).

## 🎯 Consoles suportados

| Console | Núcleo | Extensões | Status |
|---|---|---|---|
| Atari 2600 | Stella | `.a26` | ✅ Pronto |
| NES | Nestopia UE | `.nes` | ✅ Pronto |
| Master System | Genesis Plus GX | `.sms` | ✅ Pronto |
| PC Engine | Beetle PCE Fast | `.pce` | ✅ Pronto |
| Mega Drive / Genesis | Genesis Plus GX | `.md .gen .smd .bin` | ✅ Pronto |
| Game Boy / Color | Gambatte | `.gb .gbc` | ✅ Pronto |
| Atari Lynx | Beetle Lynx | `.lnx` | ✅ Pronto |
| Super Nintendo | Snes9x | `.smc .sfc .fig` | ✅ Pronto |
| Game Gear | Genesis Plus GX | `.gg` | ✅ Pronto |
| Neo Geo Pocket | Beetle NeoPop | `.ngp .ngc` | ✅ Pronto |
| WonderSwan | Beetle WonderSwan | `.ws .wsc` | ✅ Pronto |
| Game Boy Advance | mGBA | `.gba .agb` | ✅ Pronto |
| Arcade (FinalBurn Neo) | FBNeo | `.zip` | 🧪 Experimental |
| PlayStation | PCSX ReARMed | `.cue .chd .pbp .iso .img` | 🧪 Experimental (requer BIOS¹) |
| Nintendo 64 | Mupen64Plus-Next | — | 🔜 Fase 2 (OpenGL HW) |
| PSP | PPSSPP | — | 🔜 Fase 2 (OpenGL HW) |
| Nintendo DS | melonDS | — | 🔜 Fase 2 |

¹ **BIOS**: para PS1, copie a BIOS do seu console (ex.: `scph5501.bin`) em *Ajustes → BIOS → Importar BIOS*.

> ⚖️ **Aviso legal**: o PeraatMuu **não inclui nem distribui ROMs ou BIOS**. Use apenas backups dos jogos e do hardware que você possui. Cada núcleo segue a licença do seu projeto original (Stella, Nestopia, Snes9x⁽²⁾, Gambatte, mGBA, Genesis Plus GX, Mednafen/Beetle, FinalBurn Neo, PCSX ReARMed). ² Snes9x tem licença de uso não-comercial — o PeraatMuu é um app gratuito.

---

## 🏗️ Arquitetura

```
┌────────────────────────────── APK ──────────────────────────────┐
│                                                                 │
│  Flutter UI (Dart)                                              │
│  ├─ Telas: Início / Consoles / Biblioteca / Ajustes             │
│  ├─ Biblioteca de ROMs (scan, filtros, persistência JSON)       │
│  └─ MethodChannel "peraatmuu/emulator"                          │
│              │ play(corePath, romPath, systemId)                │
│              ▼                                                  │
│  Kotlin (Android)                                               │
│  ├─ MainActivity ──► abre GameActivity                          │
│  └─ GameActivity: GLSurfaceView + AudioTrack + controles        │
│              │ JNI                                              │
│              ▼                                                  │
│  C++ (retrobridge)                                              │
│  ├─ dlopen() do núcleo libretro embutido (.so)                  │
│  ├─ callbacks: vídeo RGBA / áudio PCM / joypad / environment    │
│  └─ thread de emulação com limitador de FPS                     │
│              ▼                                                  │
│  Núcleos libretro (ABI arm64-v8a / armeabi-v7a / x86_64)        │
│  snes9x • mgba • nestopia • stella • gambatte • genesis_plus_gx │
│  mednafen_* • fbneo • pcsx_rearmed                              │
└─────────────────────────────────────────────────────────────────┘
```

Os núcleos **não ficam no Git** (são binários grandes): o script
[`tools/download_cores.sh`](tools/download_cores.sh) baixa os `.so` oficiais do
buildbot do libretro durante o build, para cada ABI. Como usamos
`--split-per-abi`, cada APK carrega só os núcleos da sua arquitetura.

## 🚀 Como funciona o build no GitHub

> ⚡ **Primeira vez? Ative o workflow (uma vez só):**
> o arquivo de CI fica em [`ci/build.yml`](ci/build.yml). Bots não podem
> versionar arquivos dentro de `.github/workflows/` (regra do GitHub), então
> a ativação é feita com a **sua conta**, pelo Termux ou PC:
>
> ```bash
> git pull && bash tools/ativar_workflow.sh
> ```
>
> Depois disso, **todo push já compila e gera APK baixável automaticamente**.

Com o workflow ativo, a cada **push** (branch `main`, `arena/**` ou qualquer PR),
o GitHub Actions:

1. Configura Java 17 + Flutter stable;
2. Baixa os núcleos libretro oficiais (com cache);
3. Roda `flutter analyze` + `flutter test`;
4. Compila os APKs **release** separados por ABI;
5. Publica os APKs como **artefato baixável** `peraatmuu-apk` na aba **Actions**;
6. Se o push foi uma **tag `vX.Y.Z`**, cria uma **Release** no GitHub com os APKs anexados.

### 📥 Baixar o APK

**Pelo navegador:** `Actions` → clique na execução → seção **Artifacts** → baixe `peraatmuu-apk`.
Instale o arquivo `...arm64-v8a-release.apk` (maioria dos celulares) ou o da sua arquitetura.

**Pelo Termux:** veja o guia completo em [docs/TERMUX.md](docs/TERMUX.md).

## 🏷️ Versionamento

- A versão mora em `pubspec.yaml` (`version: 1.0.0+1`);
- O CI usa `--build-number=${{ github.run_number }}` (versionCode sempre crescente);
- **Lançar versão:** suba o número no `pubspec.yaml`, commite e crie a tag:
  ```bash
  git tag v1.1.0 && git push origin v1.1.0
  ```
  → a Release é criada automaticamente com os APKs;
- Ou rode o workflow manualmente em **Actions → Build APK → Run workflow** informando a versão.

Detalhes: [docs/BUILD.md](docs/BUILD.md).

## 📁 Estrutura

```
├── lib/                     # App Flutter (UI, estado, modelos, serviços)
│   ├── models/              # Catálogo de consoles + entrada de jogo
│   ├── services/            # Ponte nativa + fluxo de lançamento
│   ├── state/               # Controllers (biblioteca, núcleos)
│   ├── theme/               # Tema neon
│   └── ui/                  # Telas e widgets (tilt 3D, grid synthwave...)
├── android/
│   ├── app/src/main/cpp/    # retrobridge.cpp (frontend libretro em C++)
│   ├── app/src/main/kotlin/ # MainActivity + GameActivity (GL/áudio/input)
│   └── app/src/main/jniLibs/# (gerado no build) núcleos .so por ABI
├── tools/download_cores.sh  # Download dos núcleos libretro oficiais
├── assets/                  # Logo, banner e fontes (Audiowide/Rajdhani, OFL)
├── docs/TERMUX.md           # Guia passo a passo no Termux
└── docs/BUILD.md            # Build manual, assinatura e releases
```

## 🗺️ Roadmap

- [x] Clássicos 8/16 bits jogáveis
- [x] PS1 + Arcade (experimental)
- [x] Save states + SRAM
- [ ] Renderização por hardware (OpenGL/Vulkan) → N64, PSP, DS
- [ ] Shaders (CRT, scanlines)
- [ ] Capas automáticas dos jogos
- [ ] Detecção de ROMs compactadas (.zip/.7z)

---

Feito com 💜 para a comunidade retrô.
