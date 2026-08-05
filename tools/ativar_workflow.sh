#!/usr/bin/env bash
#
# Ativa o workflow de build no GitHub (executar UMA VEZ com a SUA conta).
#
# Por quê? Serviços/bots não podem versionar arquivos em .github/workflows/
# (restrição do GitHub). A sua conta pode — por isso o arquivo oficial fica
# em ci/build.yml e você o ativa copiando para o lugar certo:
#
#   bash tools/ativar_workflow.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .github/workflows
cp ci/build.yml .github/workflows/build.yml
git add .github/workflows/build.yml
if git diff --cached --quiet; then
  echo "Workflow já estava ativado (sem mudanças para commit)."
else
  git commit -m "ci: ativa workflow de build do APK"
fi
echo "Enviando para o GitHub..."
git push origin "$(git branch --show-current)"
echo "Pronto! Acompanhe em: gh run list && gh run watch"
