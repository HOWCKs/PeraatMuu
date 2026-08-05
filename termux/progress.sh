#!/data/data/com.termux/files/usr/bin/bash
# PeraatMuu - Gerenciador de progresso do jogador via Termux
# Uso: bash termux/progress.sh <acao> [parametros...]
# Ações: log, status, reset, sync

PROGRESS_FILE="$HOME/.peraatmuu/progress.json"
mkdir -p "$HOME/.peraatmuu"
[ -f "$PROGRESS_FILE" ] || echo '{"user":"lan_user","sessions":[],"consoles":{},"total_time_sec":0}' > "$PROGRESS_FILE"

ACTION="${1:-status}"
case "$ACTION" in
  log)
    CONSOLE="${2:-NES}"
    GAME="${3:-Unknown}"
    TIME_SEC="${4:-3600}"
    # Atualiza JSON simples com python3 (geralmente disponível no Termux)
    python3 - <<PY
import json, sys, datetime
with open("$PROGRESS_FILE") as f: data=json.load(f)
data["sessions"].append({
  "console": "$CONSOLE",
  "game": "$GAME",
  "time_sec": int("$TIME_SEC"),
  "timestamp": datetime.datetime.now().isoformat()
})
data["total_time_sec"] = data.get("total_time_sec",0)+int("$TIME_SEC")
data["consoles"]["$CONSOLE"] = data["consoles"].get("$CONSOLE",0)+int("$TIME_SEC")
with open("$PROGRESS_FILE","w") as f: json.dump(data,f,indent=2)
print(f"[PeraatMuu] Progresso registrado: {data['total_time_sec']}s total")
PY
    ;;
  status)
    python3 - <<PY
import json
with open("$PROGRESS_FILE") as f: d=json.load(f)
print("=== PeraatMuu Progresso ===")
print(f"Usuário: {d.get('user')}")
print(f"Tempo total: {d.get('total_time_sec')}s ({d.get('total_time_sec',0)//60} min)")
print("Consoles usados:")
for k,v in d.get("consoles",{}).items():
    print(f"  {k}: {v}s")
print("Últimas sessões:")
for s in d.get("sessions",[])[-3:]:
    print(f"  {s['timestamp']} | {s['console']} / {s['game']} | {s['time_sec']}s")
PY
    ;;
  reset)
    echo '{"user":"lan_user","sessions":[],"consoles":{},"total_time_sec":0}' > "$PROGRESS_FILE"
    echo "[PeraatMuu] Progresso resetado."
    ;;
  sync)
    echo "[PeraatMuu] Syncronizando com API... (implementar endpoint futuro)"
    ;;
  *)
    echo "Uso: $0 {log|status|reset|sync} [console] [game] [time_sec]"
    exit 1
esac
