#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

SHELL_DATA="$DATA/shell"
if [[ ! -d "$SHELL_DATA" ]]; then
    echo "No shell config data found. Skipping."
    exit 0
fi

# Install Oh My Zsh if not present (the .zshrc references it)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    green "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1
    green "Oh My Zsh installed."
else
    green "Oh My Zsh already installed."
fi

# Copy each dotfile, backing up existing ones
for f in .zshrc .zprofile .bash_profile .bashrc .gitconfig .npmrc; do
    src="$SHELL_DATA/$f"
    dest="$HOME/$f"

    if [[ ! -f "$src" ]]; then
        continue
    fi

    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            green "$f already matches, skipping."
            continue
        fi
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$dest" "$backup"
        yellow "Backed up existing $f → $(basename "$backup")"
    fi

    cp "$src" "$dest"
    green "Installed $f"
done

green "Shell configs restored."
yellow "Restart your shell or run: source ~/.zshrc"
