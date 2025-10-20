#!/bin/bash
set -euo pipefail

echo "=== 🚀 INICIANDO PREPARAÇÃO DO AMBIENTE GigaLearnCPP ==="

# ===== VARIÁVEIS =====
REPO="brenohv/GigaLearnCPP-Leak"
APP_ROOT="/app"
REPO_DIR="$APP_ROOT/GigaLearnCPP-Leak"
GIGA_DIR="$REPO_DIR/GigaLearnCPP"
LIBTORCH_URL="https://download.pytorch.org/libtorch/cu130/libtorch-shared-with-deps-2.9.0%2Bcu130.zip"
LIBTORCH_TMP="/tmp/libtorch.zip"

# ===== 1. PACOTES DO SISTEMA =====
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    build-essential cmake git wget unzip python3.11 python3.11-dev python3-pip ca-certificates rsync

# ===== 2. DEFINIR PYTHON 3.11 COMO PADRÃO =====
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 || true
python3 -m pip install --upgrade pip

# ===== 3. INSTALAR PACOTES PYTHON =====
python3 -m pip install wandb pydantic-core

# ===== 4. CRIAR DIRETÓRIO BASE =====
mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

# ===== 5. CLONAR OU ATUALIZAR REPOSITÓRIO =====
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "❌ ERRO: GITHUB_TOKEN não definido. Configure em Environment Variables."
    exit 1
fi

if [ -d "$REPO_DIR/.git" ]; then
    echo "📦 Repositório já existe, atualizando..."
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR"
    git pull --rebase origin main || true
    git submodule update --init --recursive || true
else
    echo "📦 Clonando repositório privado..."
    git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/${REPO}.git" "$REPO_DIR"
    cd "$REPO_DIR"
    git submodule update --init --recursive || true
fi

# ===== 6. BAIXAR E CONFIGURAR LIBTORCH =====
mkdir -p "$GIGA_DIR"
cd "$GIGA_DIR"
wget -q -O "$LIBTORCH_TMP" "$LIBTORCH_URL"
rm -rf "$GIGA_DIR/libtorch"
unzip -q "$LIBTORCH_TMP" -d "$GIGA_DIR"
rm -f "$LIBTORCH_TMP"

# ===== 7. VERIFICAR SE REPOSITÓRIO FOI CLONADO =====
if [ -f "$REPO_DIR/README.md" ]; then
    echo "✅ Repositório clonado com sucesso!"
else
    echo "❌ Falha: Repositório não encontrado em $REPO_DIR"
    exit 1
fi

echo "✅ Setup completo!"
echo "Repositório: $REPO_DIR"
echo "libtorch: $GIGA_DIR/libtorch"
echo "Python usado: $(python3 --version)"
