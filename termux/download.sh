#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Baixar APK do CI via gh (artefato do run mais recente)
# Uso: bash termux/download.sh
set -euo pipefail
REPO="HOWCKs/PeraatMuu"
OUT_DIR="$HOME/storage/shared/Download"
mkdir -p "$OUT_DIR"

echo "[PeraatMuu] Buscando run do workflow 'Build Android APK'..."
RUN_ID=$(gh run list --repo "$REPO" --workflow="Build Android APK" --branch=arena/019fcf51-peraatmuu --limit 1 --json databaseId,status --jq '.[0].databaseId' 2>/dev/null || true)

if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
  echo "[PeraatMuu] Nenhum run encontrado. Talvez ainda não tenha rodado."
  echo "[PeraatMuu] Rode primeiro: bash termux/trigger.sh"
  exit 1
fi

echo "[PeraatMuu] Run ID: $RUN_ID"
echo "[PeraatMuu] Baixando artefato PeraatMuu-APK..."
gh run download "$RUN_ID" --repo "$REPO" --name "PeraatMuu-APK" --dir "$OUT_DIR" || true

if [ -f "$OUT_DIR/app-release.apk" ]; then
  mv "$OUT_DIR/app-release.apk" "$OUT_DIR/PeraatMuu.apk"
  echo "[PeraatMuu] APK baixado: $OUT_DIR/PeraatMuu.apk"
else
  echo "[PeraatMuu] Artefato não baixado automaticamente. Acesse: https://github.com/$REPO/actions"
fi
