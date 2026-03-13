#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

SSH_DATA="$DATA/ssh"
if [[ ! -d "$SSH_DATA" ]]; then
    echo "No SSH data found. Skipping."
    exit 0
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

PRIVATE_KEYS=(id_ed25519 id_rsa ai_cluster_key)
PUBLIC_KEYS=(id_ed25519.pub id_rsa.pub ai_cluster_key.pub)
OTHER_FILES=(config known_hosts)

for key in "${PRIVATE_KEYS[@]}"; do
    src="$SSH_DATA/$key"
    dest="$HOME/.ssh/$key"
    if [[ ! -f "$src" ]]; then continue; fi

    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            green "$key already matches, skipping."
            continue
        fi
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        cp -p "$dest" "$backup"
        yellow "Backed up existing $key"
    fi

    cp "$src" "$dest"
    chmod 600 "$dest"
    green "Installed $key (mode 600)"
done

for key in "${PUBLIC_KEYS[@]}"; do
    src="$SSH_DATA/$key"
    dest="$HOME/.ssh/$key"
    [[ -f "$src" ]] || continue

    cp "$src" "$dest"
    chmod 644 "$dest"
    green "Installed $key (mode 644)"
done

for f in "${OTHER_FILES[@]}"; do
    src="$SSH_DATA/$f"
    dest="$HOME/.ssh/$f"
    [[ -f "$src" ]] || continue

    if [[ -f "$dest" ]]; then
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        cp -p "$dest" "$backup"
        yellow "Backed up existing $f"
    fi

    cp "$src" "$dest"
    chmod 644 "$dest"
    green "Installed $f"
done

green "SSH keys and config restored."
echo ""
yellow "Manual steps:"
echo "  ssh-add ~/.ssh/id_ed25519"
echo "  ssh-add ~/.ssh/id_rsa"
echo "  ssh-add ~/.ssh/ai_cluster_key"
