#!/bin/bash
echo "=== PREPARANDO AMBIENTE GigaLearnCPP ==="

REPO="brenohv/GigaLearnCPP-Leak"
APP_ROOT="/app"
REPO_DIR="$APP_ROOT/GigaLearnCPP-Leak"
GIGA_DIR="$REPO_DIR/GigaLearnCPP"
LIBTORCH_URL="https://download.pytorch.org/libtorch/cu128/libtorch-shared-with-deps-2.9.0%2Bcu128.zip"
LIBTORCH_TMP="/tmp/libtorch.zip"
GIT_USER_NAME="brenohv"
GIT_USER_EMAIL="brenohenriquev8@gmail.com"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y build-essential cmake git wget unzip python3.11 python3.11-dev python3-pip ca-certificates rsync
python3 -m pip install --upgrade pip
python3 -m pip install wandb

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "❌ ERRO: GITHUB_TOKEN não definido. Configure em Environment Variables."
    exit 1
fi

if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR"
    git pull --rebase origin main || true
    git submodule update --init --recursive || true
else
    git clone --recurse-submodules "https://${GITHUB_TOKEN}@github.com/${REPO}.git" "$REPO_DIR"
    cd "$REPO_DIR"
    git submodule update --init --recursive || true
fi

git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPO}.git"

mkdir -p "$GIGA_DIR"
cd "$GIGA_DIR"
wget -q -O "$LIBTORCH_TMP" "$LIBTORCH_URL"
rm -rf "$GIGA_DIR/libtorch"
unzip -q "$LIBTORCH_TMP" -d "$GIGA_DIR"
rm -f "$LIBTORCH_TMP"

echo "✅ Setup completo!"
