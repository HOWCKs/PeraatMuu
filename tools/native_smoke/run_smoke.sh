#!/usr/bin/env bash
#
# Smoke test nativo da ponte retrobridge — valida dlopen, vídeo, áudio,
# entrada e save states com um núcleo libretro FAKE, sem precisar de Android.
#
#   bash tools/native_smoke/run_smoke.sh
#
# No Termux:  pkg install -y clang
#
set -euo pipefail
cd "$(dirname "$0")"

CXX="${CXX:-}"
if [ -z "$CXX" ]; then
  if command -v g++ >/dev/null 2>&1; then CXX=g++;
  elif command -v clang++ >/dev/null 2>&1; then CXX=clang++;
  else echo "Instale um compilador C++ (g++ ou clang++). No Termux: pkg install clang"; exit 1; fi
fi

BUILD=.smoke_build
rm -rf "$BUILD" && mkdir -p "$BUILD/sys" "$BUILD/sav"
echo "fake rom" > "$BUILD/rom.bin"

echo "[1/3] Compilando núcleo libretro fake..."
"$CXX" -std=c++17 -fPIC -shared fakecore.cpp -o "$BUILD/fakecore.so" -lm

echo "[2/3] Compilando ponte retrobridge + harness..."
"$CXX" -std=c++17 -Wall -Wextra -Wno-unused-parameter -I stubs \
  ../../android/app/src/main/cpp/retrobridge.cpp harness.cpp \
  -o "$BUILD/harness" -ldl -lpthread

echo "[3/3] Executando..."
"$BUILD/harness" "$PWD/$BUILD" | tee "$BUILD/out.log"

# O modo de entrega depende da extensão: .bin é cartucho → memória.
if grep -q "\[fakecore\] mode=memory" "$BUILD/out.log"; then
  echo "  PASS  conteúdo entregue em memória (data+size)"
else
  echo "  FAIL  esperado modo memória para .bin"
  exit 1
fi
