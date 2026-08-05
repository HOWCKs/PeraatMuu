#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Build local via Termux (se Flutter estiver instalado no Termux)
# Uso: bash termux/build-apk.sh

set -euo pipefail

echo "[PeraatMuu] Verificando ambiente..."

if ! command -v flutter >/dev/null 2>&1; then
  echo "[PeraatMuu] Flutter não encontrado. Instale com:"
  echo "  pkg install git unzip openjdk-21"
  echo "  git clone https://github.com/flutter/flutter.git /data/data/com.termux/files/home/flutter"
  echo "  export PATH=\"\$HOME/flutter/bin:\$PATH\""
  exit 1
fi

echo "[PeraatMuu] Baixando repo atual..."
REPO_URL="https://github.com/HOWCKs/PeraatMuu.git"
BUILD_DIR="$HOME/PeraatMuu-build"

rm -rf "$BUILD_DIR"
git clone --branch arena/019fcf51-peraatmuu --depth 1 "$REPO_URL" "$BUILD_DIR" 2>/dev/null || git clone --branch main --depth 1 "$REPO_URL" "$BUILD_DIR"

cd "$BUILD_DIR"

echo "[PeraatMuu] Instalando dependências..."
flutter pub get

echo "[PeraatMuu] Compilando APK release..."
flutter build apk --release --shrink

echo "[PeraatMuu] APK gerado:"
ls -la build/app/outputs/flutter-apk/app-release.apk
echo "[PeraatMuu] Para instalar: termux-open build/app/outputs/flutter-apk/app-release.apk"
