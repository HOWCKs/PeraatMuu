# 🏗️ Build, assinatura e releases

## Build automático (padrão)

O build oficial acontece no **GitHub Actions** (`.github/workflows/build.yml`):

| Gatilho | Resultado |
|---|---|
| Push em `main` / `arena/**` | Build + artefato `peraatmuu-apk` na aba Actions |
| Pull request | Build de validação (analyze + test + APK) |
| Tag `vX.Y.Z` | Tudo isso + **Release** pública com os APKs |
| Manual (`workflow_dispatch`) | Build com opção de sobrescrever a versão |

Etapa a etapa: Java 17 → Flutter stable → licenças SDK → download dos núcleos
libretro (com cache) → `flutter pub get` → `flutter analyze` → `flutter test` →
`flutter build apk --release --split-per-abi` → upload dos artefatos.

## Sobre os núcleos libretro

Os núcleos `.so` **não são versionados no Git** (binários grandes). O script
`tools/download_cores.sh` baixa as versões oficiais do
[buildbot do libretro](https://buildbot.libretro.com/nightly/android/latest/)
para `android/app/src/main/jniLibs/<abi>/` antes da compilação.

Ao adicionar um console novo:

1. Cadastre o `coreId` em `lib/models/console_system.dart`;
2. Acrescente o mesmo nome à variável `CORES` em `tools/download_cores.sh`;
3. Commit — o workflow cuida do resto (inclusive invalidar o cache).

## Build manual (PC)

Pré-requisitos: Flutter SDK stable, Android SDK (platform 34, build-tools),
NDK `26.1.10909125`, CMake 3.22.1.

```bash
git clone https://github.com/HOWCKs/PeraatMuu.git && cd PeraatMuu
bash tools/download_cores.sh      # baixa os núcleos para jniLibs/
flutter pub get
flutter build apk --release --split-per-abi
```

APKs em `build/app/outputs/flutter-apk/`.

> No Termux NÃO é possível compil Flutter nativamente de forma confiável —
> o fluxo oficial é editar/empurrar pelo Termux e compilar no GitHub.

## Assinatura do APK

Os builds de CI usam a **keystore de debug** (instala fácil, mas não serve
para atualizações entre chaves diferentes nem para lojas). Para assinar de
verdade:

```bash
keytool -genkey -v -keystore peraatmuu.keystore \
  -alias peraatmuu -keyalg RSA -keysize 2048 -validity 10000
```

Crie `android/key.properties` (git-ignored):

```properties
storeFile=../peraatmuu.keystore
storePassword=SENHA
keyAlias=peraatmuu
keyPassword=SENHA
```

E no CI, armazene a keystore em base64 como secret (`KEYSTORE_BASE64`),
decodifique em um step e alimente o `key.properties` antes do build.
Detalhe: mantenha **a mesma chave** para sempre — ela define a identidade do app.

## Convenção de versões

- `MAJOR.MINOR.PATCH+build` em `pubspec.yaml` (semver);
- CI: `--build-name` = versão do pubspec (ou override manual),
  `--build-number` = número da execução (versionCode crescente);
- Nome dos artefatos: `peraatmuu-<versao>+<build>-<abi>-release.apk`.

## Troubleshooting do CI

| Erro | Causa provável / solução |
|---|---|
| `NDK not found` | O AGP baixa automaticamente; cheque o log — se falhar, ajuste `ndkVersion` em `android/app/build.gradle` para uma versão presente no runner |
| `núcleo indisponível` | O buildbot removeu/renomeou o `.so` daquele ABI — atualize `CORES` no script |
| `licenses not accepted` | O step `sdkmanager --licenses` resolve; confirme que rodou antes do build |
| CMake/Kotlin mismatch | Alinhe `kotlin` (settings.gradle) e `compileOptions` (Java 17) |
