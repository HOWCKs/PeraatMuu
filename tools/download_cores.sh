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
# ps2/gcn/wii/3ds: só existem (ou só fazem sentido) em 64-bit — o script tolera
# 404 por ABI e o app esconde o console quando o núcleo não existe no APK.
CORES="${CORES:-stella nestopia genesis_plus_gx mednafen_pce_fast gambatte snes9x mednafen_lynx mednafen_ngp mednafen_wswan mgba fbneo pcsx_rearmed melonds desmume ppsspp parallel_n64 citra play dolphin}"

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

# ---------------------------------------------------------------------------
# Dados do Dolphin (GCN/Wii): o núcleo libretro EXIGE a pasta Sys em
# <system>/dolphin-emu/. Baixamos Data/Sys do repo oficial e embutimos nos
# assets do APK; o app extrai para filesDir/system na primeira execução.
# ---------------------------------------------------------------------------
SYSDATA_DIR="$(dirname "$0")/../android/app/src/main/assets/sysdata/dolphin-emu"
DOLPHIN_TARBALL="${DOLPHIN_TARBALL:-https://codeload.github.com/libretro/dolphin/tar.gz/refs/heads/master}"
if [ -d "$SYSDATA_DIR/Sys" ]; then
  echo "== [cache] dados do Dolphin já embutidos =="
else
  echo "== Baixando Data/Sys do Dolphin =="
  if curl -fSL --retry 3 --connect-timeout 20 -o "$TMP_DIR/dolphin.tar.gz" "$DOLPHIN_TARBALL"; then
    mkdir -p "$TMP_DIR/dolphin" "$SYSDATA_DIR"
    tar -xzf "$TMP_DIR/dolphin.tar.gz" -C "$TMP_DIR/dolphin" --wildcards 'dolphin-*/Data/Sys'
    mv "$TMP_DIR"/dolphin/dolphin-*/Data/Sys "$SYSDATA_DIR/Sys"
    # Higiene: nada de fotos gigantes/acessórios desnecessários no APK.
    rm -rf "$SYSDATA_DIR/Sys/Resources" "$SYSDATA_DIR/Sys/Themes" 2>/dev/null || true
    echo "== Sys do Dolphin embutido: $(du -sh "$SYSDATA_DIR" | cut -f1) =="
  else
    echo "[AVISO] não foi possível baixar o Sys do Dolphin (GCN/Wii ficam sem dados)" >&2
  fi
fi
