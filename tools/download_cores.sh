#!/usr/bin/env bash
#
# Baixa os núcleos libretro oficiais (buildbot.libretro.com) para
# android/app/src/main/jniLibs/<abi>/ — eles são embutidos no APK durante o build.
#
# Uso:  bash tools/download_cores.sh
# Funciona no CI (ubuntu) e localmente (Linux/macOS/Termux com curl+unzip).
#
set -euo pipefail

# ABIs geradas pelo `flutter build apk --split-per-abi` (ver abiFilters no app/build.gradle)
ABIS="${ABIS:-arm64-v8a armeabi-v7a x86_64}"

# Núcleos — MANTER EM SINCRONIA com lib/models/console_system.dart (campo coreId)
CORES="${CORES:-stella nestopia genesis_plus_gx mednafen_pce_fast gambatte snes9x mednafen_lynx mednafen_ngp mednafen_wswan mgba fbneo pcsx_rearmed melonds ppsspp mupen64plus_next}"

# Permite override para testes locais (ex.: BASE_URL=file:///tmp/cores_fixture)
BASE_URL="${BASE_URL:-https://buildbot.libretro.com/nightly/android/latest}"
OUT_DIR="$(dirname "$0")/../android/app/src/main/jniLibs"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "== PeraatMuu: download de núcleos libretro =="
for abi in $ABIS; do
  mkdir -p "$OUT_DIR/$abi"
  for core in $CORES; do
    file="${core}_libretro_android.so"
    # IMPORTANTE: o Android só extrai libs com prefixo "lib" de lib/<abi>/ para
    # nativeLibraryDir. Sem isso o núcleo vai no APK mas some no dispositivo.
    out="lib${core}_libretro_android.so"
    dest="$OUT_DIR/$abi/$out"
    if [ -f "$dest" ]; then
      echo "  [cache] $abi/$out"
      continue
    fi
    url="$BASE_URL/$abi/$file.zip"
    echo "  [baixando] $url"
    if curl -fSL --retry 3 --connect-timeout 20 -o "$TMP_DIR/$file.zip" "$url"; then
      unzip -o -j "$TMP_DIR/$file.zip" "$file" -d "$TMP_DIR" >/dev/null
      mv "$TMP_DIR/$file" "$dest"
      rm -f "$TMP_DIR/$file.zip"
    else
      # Núcleo indisponível para esta ABI — apenas avisa; o app marca o console como indisponível.
      echo "  [AVISO] núcleo indisponível para $abi: $core" >&2
    fi
  done
done

echo "== Núcleos instalados em $OUT_DIR =="
find "$OUT_DIR" -name '*.so' | sort
