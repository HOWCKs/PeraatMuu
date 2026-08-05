# PeraatMuu Termux Scripts

## Requisitos
- Termux (Android)
- `pkg install bash curl python3 unzip`
- Opcional: `pkg install termux-api` para notificações

## Uso

### Atualizar APK
```bash
bash termux/update.sh [branch]
# Baixa o APK do GitHub Actions; instale com termux-open
```

### Gerenciar Progresso
```bash
bash termux/progress.sh status
bash termux/progress.sh log NES "Super Mario Bros" 1800
bash termux/progress.sh reset
```

O progresso é salvo em `~/ .peraatmuu/progress.json` e pode ser sincronizado futuramente com a API do app.
