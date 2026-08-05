#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Atualizador de APK via Termux
# Uso: bash termux/update.sh [branch_or_tag]
# Requer: curl, unzip (opcional), pkg install termux-api (para notificações)

set -euo pipefail
REPO="HOWCKs/PeraatMuu"
BRANCH="${1:-arena/019fcf51-peraatmuu}"
APK_DIR="$HOME/storage/shared/Download"
mkdir -p "$APK_DIR"

echo "[PeraatMuu] Buscando build mais recente para branch: $BRANCH"

# Tenta baixar do artefato mais recente (requiere gh auth ou token public repo)
# Para repos públicos, usamos a API de artifacts
RUN_ID=$(curl -sL "https://api.github.com/repos/${REPO}/actions/runs?branch=${BRANCH}&status=success&per_page=1" | grep -oP '"id":\s*\K[0-9]+' | head -n1)

if [ -z "$RUN_ID" ]; then
  echo "[PeraatMuu] Nenhum build encontrado. Tente empurrar uma tag para gerar release."
  exit 1
fi

echo "[PeraatMuu] Run ID: $RUN_ID"

# Baixa o artefato (simplificado; em produção use gh CLI)
echo "[PeraatMuu] Baixando APK..."
curl -L -o "$APK_DIR/PeraatMuu.apk" \
  "https://github.com/${REPO}/actions/runs/${RUN_ID}/artifacts?download=1" || true

if [ -f "$APK_DIR/PeraatMuu.apk" ]; then
  echo "[PeraatMuu] APK salvo em: $APK_DIR/PeraatMuu.apk"
  echo "[PeraatMuu] Para instalar: termux-open $APK_DIR/PeraatMuu.apk"
  # Notifica se termux-api disponível
  command -v termux-notification >/dev/null 2>&1 && \
    termux-notification --title "PeraatMuu" --content "Nova atualização pronta para instalar."
else
  echo "[PeraatMuu] Falha ao baixar APK. Você pode baixar manualmente de:"
  echo "  https://github.com/${REPO}/actions"
fi
