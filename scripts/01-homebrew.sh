#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

if [[ ! -f "$DATA/Brewfile" ]]; then
    red "No Brewfile found in data/. Run export.sh first."
    exit 1
fi

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    green "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    green "Homebrew already installed: $(brew --version | head -1)"
fi

green "Installing packages from Brewfile..."
brew bundle --file="$DATA/Brewfile" --no-lock 2>&1 || {
    yellow "Some packages may have failed — check output above."
}

green "Homebrew restore complete."

# Reference info for manual runtime installs
if [[ -f "$DATA/nvm-versions.txt" ]]; then
    echo ""
    yellow "NVM Node versions to install manually (after NVM is available):"
    cat "$DATA/nvm-versions.txt" | sed 's/^/  nvm install /'
fi

if [[ -f "$DATA/pyenv-versions.txt" ]]; then
    echo ""
    yellow "Pyenv Python versions to install manually (after Pyenv is available):"
    cat "$DATA/pyenv-versions.txt" | sed 's/^/  pyenv install /'
fi
