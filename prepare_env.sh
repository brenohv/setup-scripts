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
GIT_USER_NAME="brenohv"
GIT_USER_EMAIL="brenohenriquev8@gmail.com"

# ===== 1. CORRIGIR DNS E TESTAR CONEXÃO =====
echo "🔧 Verificando conectividade de rede..."
if ! ping -c1 1.1.1.1 &>/dev/null; then
  echo "⚠️  Sem acesso à internet. Tentando novamente em 5s..."
  sleep 5
fi

if ! ping -c1 1.1.1.1 &>/dev/null; then
  echo "❌ Sem conexão com a internet. Verifique a rede do container."
  exit 1
fi

if ! nslookup github.com &>/dev/null; then
  echo "⚠️  Corrigindo DNS..."
  rm -f /etc/resolv.conf
  echo "nameserver 1.1.1.1" > /etc/resolv.conf
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

# ===== 2. ATUALIZAR E INSTALAR PACOTES =====
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y build-essential cmake git wget unzip python3.11 python3.11-dev python3-pip ca-certificates rsync dnsutils

# ===== 3. DEFINIR PYTHON 3.11 COMO PADRÃO =====
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 || true
python3 -m pip install --upgrade pip

# ===== 4. INSTALAR DEPENDÊNCIAS PYTHON =====
python3 -m pip install --upgrade wandb pydantic --target=/usr/local/lib/python3.11/dist-packages

# ===== 5. CONFIGURAR GIT =====
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

# ===== 6. VERIFICAR TOKEN =====
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "❌ ERRO: GITHUB_TOKEN não definido. Configure-o nas variáveis de ambiente do Vast.ai."
    exit 1
fi

# ===== 7. CLONAR OU ATUALIZAR REPOSITÓRIO =====
mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

if [ -d "$REPO_DIR/.git" ]; then
    echo "📦 Repositório já existe, atualizando..."
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR"
    git pull --rebase origin main || true
    git submodule update --init --recursive || true
else
    echo "⬇️  Clonando repositório privado..."
    git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/${REPO}.git" "$REPO_DIR"
    cd "$REPO_DIR"
    git submodule update --init --recursive || true
fi

git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPO}.git"

# ===== 8. BAIXAR LIBTORCH =====
mkdir -p "$GIGA_DIR"
cd "$GIGA_DIR"
echo "⬇️  Baixando libtorch..."
wget -q -O "$LIBTORCH_TMP" "$LIBTORCH_URL"
rm -rf "$GIGA_DIR/libtorch"
unzip -q "$LIBTORCH_TMP" -d "$GIGA_DIR"
rm -f "$LIBTORCH_TMP"

# ===== 9. FINAL =====
echo "✅ Setup completo!"
echo "📁 Repositório: $REPO_DIR"
echo "⚙️  libtorch: $GIGA_DIR/libtorch"
echo "🐍 Python versão: $(python3 --version)"
echo "🌐 GitHub Token autenticado para: $REPO"
