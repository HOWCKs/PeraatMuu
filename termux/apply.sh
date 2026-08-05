#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Aplicar APK baixado + registrar progresso inicial
# Uso: bash termux/apply.sh [rom_path_opcional]
set -euo pipefail
APK="$HOME/storage/shared/Download/PeraatMuu.apk"

echo "[PeraatMuu] Aplicando APK..."
if [ -f "$APK" ]; then
  termux-open "$APK"
  echo "[PeraatMuu] Instalação iniciada. Confirme no Android."
else
  echo "[PeraatMuu] APK não encontrado em $APK"
  echo "[PeraatMuu] Rode primeiro: bash termux/update.sh"
  exit 1
fi

echo "[PeraatMuu] Registrando sessão inicial..."
bash termux/progress.sh log "PeraatMuu" "Instalação CI" 300

echo "[PeraatMuu] Pronto! Progresso registrado."
