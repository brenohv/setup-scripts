#!/bin/bash
set -euo pipefail

echo "=== 🚀 PREPARANDO AMBIENTE GigaLearnCPP (Python 3.11 + CUDA 12.8) ==="

# ==============================
# VARIÁVEIS DE AMBIENTE
# ==============================
REPO="brenohv/GigaLearnCPP-Leak"
APP_ROOT="/app"
REPO_DIR="$APP_ROOT/GigaLearnCPP-Leak"
GIGA_DIR="$REPO_DIR/GigaLearnCPP"
LIBTORCH_URL="https://download.pytorch.org/libtorch/cu128/libtorch-shared-with-deps-2.9.0%2Bcu128.zip"
LIBTORCH_TMP="/tmp/libtorch.zip"
GIT_USER_NAME="brenohv"
GIT_USER_EMAIL="brenohenriquev8@gmail.com"

# ==============================
# 1️⃣ ATUALIZAR PACOTES DO SISTEMA
# ==============================
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    ca-certificates \
    rsync \
    curl

# ==============================
# 2️⃣ INSTALAR PYTHON 3.11 E DEFINIR COMO PADRÃO
# ==============================
echo "➡️ Instalando Python 3.11..."
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update -y && apt-get install -y python3.11 python3.11-dev python3.11-distutils python3-pip

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 || true
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2
update-alternatives --set python3 /usr/bin/python3.11

python3 --version
python3 -m pip install --upgrade pip setuptools wheel

# ==============================
# 3️⃣ INSTALAR DEPENDÊNCIAS PYTHON
# ==============================
echo "➡️ Instalando dependências Python..."
python3 -m pip install --upgrade wandb pydantic pydantic_core

# ==============================
# 4️⃣ CONFIGURAÇÃO GIT
# ==============================
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

# ==============================
# 5️⃣ CLONAR OU ATUALIZAR REPOSITÓRIO PRIVADO
# ==============================
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "❌ ERRO: GITHUB_TOKEN não definido. Configure em Environment Variables."
    exit 1
fi

if [ -d "$REPO_DIR/.git" ]; then
    echo "🔁 Repositório já existe, atualizando..."
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR"
    git pull --rebase origin main || true
    git submodule update --init --recursive || true
else
    echo "📥 Clonando repositório..."
    git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/${REPO}.git" "$REPO_DIR"
    cd "$REPO_DIR"
    git submodule update --init --recursive || true
fi

git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPO}.git"

# ==============================
# 6️⃣ BAIXAR E CONFIGURAR LIBTORCH
# ==============================
mkdir -p "$GIGA_DIR"
cd "$GIGA_DIR"

echo "⬇️ Baixando LibTorch..."
wget -q -O "$LIBTORCH_TMP" "$LIBTORCH_URL"

rm -rf "$GIGA_DIR/libtorch"
unzip -q "$LIBTORCH_TMP" -d "$GIGA_DIR"
rm -f "$LIBTORCH_TMP"

# ==============================
# 7️⃣ FINALIZAÇÃO
# ==============================
echo "✅ Setup completo!"
echo "Versão Python ativa: $(python3 --version)"
echo "Pacotes instalados:"
python3 -m pip list | grep -E "wandb|pydantic"

echo "=== 🚀 Ambiente pronto para compilar o GigaLearnCPP ==="
