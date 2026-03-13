#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

VSCODE_DATA="$DATA/vscode"
VSCODE_USER="$HOME/Library/Application Support/Code/User"

if [[ ! -d "$VSCODE_DATA" ]]; then
    echo "No VS Code data found. Skipping."
    exit 0
fi

mkdir -p "$VSCODE_USER"

# Restore settings.json
if [[ -f "$VSCODE_DATA/settings.json" ]]; then
    if [[ -f "$VSCODE_USER/settings.json" ]]; then
        if cmp -s "$VSCODE_DATA/settings.json" "$VSCODE_USER/settings.json"; then
            green "settings.json already matches, skipping."
        else
            cp "$VSCODE_USER/settings.json" "$VSCODE_USER/settings.json.bak.$(date +%Y%m%d%H%M%S)"
            yellow "Backed up existing settings.json"
            cp "$VSCODE_DATA/settings.json" "$VSCODE_USER/settings.json"
            green "settings.json restored."
        fi
    else
        cp "$VSCODE_DATA/settings.json" "$VSCODE_USER/settings.json"
        green "settings.json installed."
    fi
fi

# Install extensions
if [[ -f "$VSCODE_DATA/extensions.txt" ]]; then
    if ! command -v code &>/dev/null; then
        yellow "VS Code CLI (code) not found."
        yellow "Install VS Code, then run:"
        echo "  cat $VSCODE_DATA/extensions.txt | xargs -L1 code --install-extension"
    else
        total=$(wc -l < "$VSCODE_DATA/extensions.txt" | tr -d ' ')
        count=0
        green "Installing $total extensions..."
        while IFS= read -r ext; do
            [[ -z "$ext" ]] && continue
            count=$((count + 1))
            printf '  [%d/%d] %s... ' "$count" "$total" "$ext"
            if code --install-extension "$ext" --force &>/dev/null; then
                printf '\033[32mok\033[0m\n'
            else
                printf '\033[33mfailed\033[0m\n'
            fi
        done < "$VSCODE_DATA/extensions.txt"
        green "Extension installation complete."
    fi
fi
