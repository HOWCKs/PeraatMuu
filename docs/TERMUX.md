# 📱 PeraatMuu no Termux

Guia completo para trabalhar no projeto **direto do celular** com o Termux:
clonar o repo, subir alterações, disparar builds no GitHub e baixar o APK pronto
— tudo sem PC.

---

## 1. Preparar o Termux

```bash
pkg update -y && pkg upgrade -y
pkg install -y git gh termux-api
```

> Dica: instale também o app **Termux:API** (F-Droid/Play) para abrir o APK
> baixado direto pelo comando `termux-open`.

## 2. Autenticar no GitHub (uma vez só)

```bash
gh auth login
```

Escolha: `GitHub.com` → `HTTPS` → `Yes` (git com credenciais do gh) →
`Login with a web browser` → anote o código, abra o link no navegador e autorize.

## 3. Clonar o projeto

```bash
git clone https://github.com/HOWCKs/PeraatMuu.git
cd PeraatMuu
```

> ⚡ **Ative o CI uma única vez** (bots não podem criar arquivos em
> `.github/workflows/`; a sua conta pode):
>
> ```bash
> git pull && bash tools/ativar_workflow.sh
> ```
>
> Pronto — daqui em diante, **todo push compila e gera APK baixável**.

## 4. Fluxo de trabalho (editar → commit → build)

```bash
# crie/troque para sua branch de trabalho
git checkout -b minha-feature

# edite arquivos (use nano ou o editor de sua preferência)
nano pubspec.yaml

# confira o que mudou
git status && git diff

# commit + push → dispara o build automaticamente no GitHub Actions
git add -A
git commit -m "feat: descreva a mudança"
git push origin minha-feature
```

> O workflow também roda na branch `main` e nas branches `arena/**`.

## 5. Acompanhar o build e baixar o APK

```bash
# lista as execuções mais recentes
gh run list --limit 5

# acompanha a execução mais recente em tempo real
gh run watch

# baixa o artefato "peraatmuu-apk" da execução mais recente
gh run download --name peraatmuu-apk

# abre o APK para instalar (precisa do Termux:API instalado)
ls peraatmuu-*-arm64-v8a-release.apk
termux-open peraatmuu-*-arm64-v8a-release.apk
```

> Se o download vier como `.zip`, descompacte antes:
> `pkg install -y unzip && unzip peraatmuu-apk.zip`

## 6. Lançar uma versão nova (Release com APK)

1. Edite o `pubspec.yaml`:
   ```yaml
   version: 1.1.0+1
   ```
2. Commit, tag e push:
   ```bash
   git add pubspec.yaml
   git commit -m "release: v1.1.0"
   git push origin minha-feature  # ou main, após merge
   git tag v1.1.0
   git push origin v1.1.0
   ```
3. O GitHub Actions compila e publica a **Release `v1.1.0`** com os APKs anexados:
   ```bash
   gh release view v1.1.0
   gh release download v1.1.0 --pattern "*arm64-v8a*"
   ```

## 7. Disparar build manualmente (sem commit)

```bash
gh workflow run build.yml --ref minha-feature -f version_name=1.1.0-beta
gh run watch
```

> ⚠️ Só funciona depois que o workflow estiver ativado
> (`bash tools/ativar_workflow.sh` uma única vez — ver passo 3).

---

### ❓ Perguntas frequentes

**Onde ficam as ROMs?**
Onde você quiser — o recomendado é criar `~/storage/shared/ROMs/<console>/`
no armazenamento compartilhado e apontar essa pasta no app
(*Início → ROMS* ou *Ajustes → Pastas de ROMs*).

**Preciso de BIOS?**
Só para PlayStation: `cp scph5501.bin ...` via *Ajustes → BIOS → Importar BIOS*
no próprio app.

**O APK não instala ("app não instalado")?**
Desinstale a versão antiga primeiro — builds de CI usam a chave de debug.
`pm uninstall com.peraatmuu.app` (com root) ou desinstale manualmente.
