#!/bin/bash
set -euo pipefail

echo "=== 🚀 INICIANDO PREPARAÇÃO DO AMBIENTE GigaLearnCPP ==="

# ===== VARIÁVEIS =====
REPO="brenohv/GigaLearnCPP-Leak"
APP_ROOT="/app"
REPO_DIR="$APP_ROOT/GigaLearnCPP-Leak"
GIGA_DIR="$REPO_DIR/GigaLearnCPP"
LIBTORCH_URL="https://download.pytorch.org/libtorch/cu128/libtorch-shared-with-deps-2.9.0%2Bcu128.zip"
LIBTORCH_TMP="/tmp/libtorch.zip"

# ===== 1. TESTAR CONEXÃO COM CURL =====
echo "🔧 Verificando conectividade de rede..."
if ! curl -s --head https://github.com | grep "200 OK" >/dev/null; then
    echo "⚠️  Github inacessível, ajustando DNS..."
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    sleep 3
fi

if ! curl -s --head https://github.com | grep "200 OK" >/dev/null; then
    echo "❌ Ainda sem acesso à internet. Abortando setup."
    exit 1
fi
echo "🌐 Conexão com internet OK!"

# ===== 2. INSTALAR PACOTES DO SISTEMA =====
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    build-essential cmake git wget unzip python3.11 python3.11-dev python3-pip ca-certificates rsync

# ===== 3. DEFINIR PYTHON 3.11 COMO PADRÃO =====
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 || true
python3 -m pip install --upgrade pip

# ===== 4. INSTALAR PACOTES PYTHON =====
python3 -m pip install --upgrade pip
python3 -m pip install wandb pydantic-core

# ===== 5. CONFIGURAR REPOSITÓRIO =====
mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

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

git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPO}.git"

# ===== 6. BAIXAR E CONFIGURAR LIBTORCH =====
mkdir -p "$GIGA_DIR"
cd "$GIGA_DIR"
wget -q -O "$LIBTORCH_TMP" "$LIBTORCH_URL"
rm -rf "$GIGA_DIR/libtorch"
unzip -q "$LIBTORCH_TMP" -d "$GIGA_DIR"
rm -f "$LIBTORCH_TMP"

echo "✅ Setup completo!"
echo "Repositório: $REPO_DIR"
echo "libtorch: $GIGA_DIR/libtorch"
echo "Python usado: $(python3 --version)"
