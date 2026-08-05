# PeraatMuu — Lan House de Emuladores Mobile

## O que é
App Flutter multi-emulador funcionando como uma **lan house digital**. Implementa consoles clássicos (NES, SNES, GBA, PS1, Mega Drive) via integração nativa FFI + CI automatizado.

## Estrutura do projeto
- `lib/` — UI/UX Flutter (Dashboard, Cards, Progresso Global, Tela de Emulador)
- `android/app/` — Configuração Android (manifesto, MainActivity Kotlin, build.gradle)
- `.github/workflows/build-apk.yml` — CI que compila APK release automaticamente
- `termux/` — Scripts para atualizar APK e gerenciar progresso no dispositivo Android
- `assets/images/` — Logos e ícones dos consoles (gerados por IA)
- `docs/ARCHITECTURE.md` — Como integrar libs nativas `.so`

## Como usar

### No PC / CI
```bash
git push origin arena/019fcf51-peraatmuu
# O GitHub Actions gera o APK e faz upload para artifacts
```

### No Android (Termux)
```bash
pkg install bash curl python3
bash termux/update.sh           # Baixa APK do CI
bash termux/progress.sh status  # Ver progresso
bash termux/progress.sh log GBA "Pokémon" 1200
```

### Rodar o app (Flutter local)
```bash
flutter pub get
flutter run
```

## Emuladores nativos
As libraries (`libnes.so`, `libmgba.so`, etc.) devem ser compiladas via **Android NDK** e colocadas em `android/app/src/main/jniLibs/armeabi-v7a/`. O `FfiBridge` carrega dinamicamente.

## Status atual
- [x] Projeto Flutter estruturado
- [x] UI/UX Dashboard gaming criado
- [x] GitHub Actions para build APK
- [x] Scripts Termux (atualizar + progresso)
- [x] Arquitetura FFI documentada
- [ ] Compilar `.so` reais dos núcleos de emulação
- [ ] Integrar renderização via Texture/PlatformView
- [ ] Endpoint de sync Termux ↔ App
