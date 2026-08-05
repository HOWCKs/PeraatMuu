# Arquitetura PeraatMuu — Lan House Multi-Emulador

## Stack
- **Frontend/UX**: Flutter (Dart) — UI gaming neon, cards de consoles, progresso global.
- **Back-end/CI**: GitHub Actions (`.github/workflows/build-apk.yml`) compila APK release automaticamente.
- **Gerenciamento de progresso**: Termux (`termux/progress.sh`) registra sessões; sincroniza com `shared_preferences` via script futuro.
- **Emuladores**: Integração nativa via FFI (`lib/services/ffi_bridge.dart`), carregando `.so` compilados via NDK (C/C++).

## Integração FFI (Nativo)
1. Compile `libnes.so`, `libmgba.so`, etc. via Android NDK (CMake/NDK-build) no diretório `android/app/src/main/jniLibs/armeabi-v7a/`.
2. No `ConsoleModel`, defina `nativeLibName`.
3. `FfiBridge.loadLib()` abre `DynamicLibrary.open(libName)`.
4. `initEmulator()` carrega ROM e inicializa o núcleo nativo.
5. `renderFrame()` pode ser chamado em loop pelo Flutter (via `Timer.periodic`) ou via `Texture` nativo (mais performático).

## Termux → App
- `termux/update.sh`: baixa APK do GitHub Actions (artefato/release) e instala.
- `termux/progress.sh`: grava `~/ .peraatmuu/progress.json`; pode ser lido pelo app via `path_provider` + `File.readAsString()`.

## Próximos passos
- [ ] Adicionar ROMs legais (ex: homebrew) em `assets/roms/`.
- [ ] Compilar `.so` reais com os núcleos de emulação.
- [ ] Implementar renderização via Texture/PlatformView para baixa latência.
- [ ] Criar endpoint de sync para Termux.
