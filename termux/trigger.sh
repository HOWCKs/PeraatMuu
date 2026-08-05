#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Disparar o Build Android APK via GitHub Actions (gh)
# Uso: bash termux/trigger.sh
set -euo pipefail

echo "[PeraatMuu] Disparando workflow 'Build Android APK' no branch arena/019fcf51-peraatmuu..."
gh workflow run "Build Android APK" --repo HOWCKs/PeraatMuu --ref arena/019fcf51-peraatmuu

echo "[PeraatMuu] Workflow disparado. Acesse: https://github.com/HOWCKS/PeraatMuu/actions"
echo "[PeraatMuu] Toque em 'Run workflow' se ainda não apareceu automático (se você já clicou antes)."
