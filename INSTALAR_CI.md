# Como ativar o GitHub Actions (CI) manualmente

O arquivo `.github/workflows/build-apk.yml` está no disco local, mas o GitHub App que gerencia este repo não tem o escopo `workflows` para criar/atualizar arquivos de workflow via push/API.

## Opção 1 — Ativar pelo site (rápido)
1. Acesse `https://github.com/HOWCKs/PeraatMuu` → **Settings → Actions → General**
2. Confirme que está em **Read and write permissions** (já está, conforme print que você enviou)
3. Vá em **Settings → Applications → GitHub Apps** (ou **Third-party Access** no repo)
4. Encontre o app usado pelo Arena → edite permissões → marque **Workflows** / **Contents**
5. Volte ao repo → **Actions** tab → deve aparecer o workflow "Build Android APK"
6. Copie `.github/workflows/build-apk.yml` para o repo pelo site (Add file → Create new file → cole conteúdo) — ou me avise que eu faço via outro método

## Opção 2 — Termux (build local agora)
```bash
bash termux/build-apk.sh
# Requer: pkg install git unzip openjdk-21 + Flutter instalado
```

## Opção 3 — Build local no PC
Se tiver Flutter instalado:
```bash
git checkout arena/019fcf51-peraatmuu
git checkout .github/workflows/build-apk.yml  # restaura do disco
flutter build apk --release
```

Depois que o CI estiver ativo, o `termux/update.sh` passará a baixar o APK automaticamente.
