# Comandos para o Termux (copie e cole)

# Verificar se está no branch certo
cd ~/PeraatMuu && git branch --show-current

# Confirmar que o arquivo CI existe (se você já colou pelo site)
ls .github/workflows/build-apk.yml

# DISPARAR CI (depois que o arquivo está confirmado)
bash ~/PeraatMuu/termux/trigger.sh

# BAIXAR APK quando o CI terminar (aguarde ~3 min após trigger)
bash ~/PeraatMuu/termux/download.sh

# INSTALAR + PROGRESSO
bash ~/PeraatMuu/termux/apply.sh

# LOGAR PROGRESSO MANUAL
bash ~/PeraatMuu/termux/progress.sh log NES "Super Mario" 1800

# STATUS
bash ~/PeraatMuu/termux/progress.sh status
