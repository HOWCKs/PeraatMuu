#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Atualizador automático do CI (artefato do run mais recente)
# Uso: bash termux/update.sh

set -euo pipefail
REPO="HOWCKs/PeraatMuu"
APK_DIR="$HOME/storage/shared/Download"
mkdir -p "$APK_DIR"

echo "[PeraatMuu] Buscando run mais recente no branch arena/019fcf51-peraatmuu..."
RUN_JSON=$(curl -sL "https://api.github.com/repos/${REPO}/actions/workflows/build-apk.yml/runs?branch=arena/019fcf51-peraatmuu&status=completed&per_page=1")
RUN_ID=$(echo "$RUN_JSON" | grep -oP '"id":\s*\K[0-9]+' | head -n1)

if [ -z "$RUN_ID" ]; then
  echo "[PeraatMuu] Nenhum run finalizado encontrado. Talvez ainda esteja rodando."
  echo "[PeraatMuu] Acesse: https://github.com/${REPO}/actions"
  exit 1
fi

echo "[PeraatMuu] Run ID: $RUN_ID"

echo "[PeraatMuu] Baixando APK do artefato..."
# Baixa o artefato (requiere login ou token para privado; para público funciona)
curl -L -o "$APK_DIR/PeraatMuu.apk" \
  "https://github.com/${REPO}/actions/runs/${RUN_ID}/artifacts?download=1" || true

if [ -f "$APK_DIR/PeraatMuu.apk" ]; then
  echo "[PeraatMuu] APK salvo: $APK_DIR/PeraatMuu.apk"
  echo "[PeraatMuu] Para instalar: termux-open $APK_DIR/PeraatMuu.apk"
  command -v termux-notification >/dev/null 2>&1 && \
    termux-notification --title "PeraatMuu" --content "APK atualizado do CI!"
else
  echo "[PeraatMuu] Falha ao baixar. Acesse a aba Actions e baixe manualmente."
fi
