#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

GHOSTTY_DATA="$DATA/ghostty/config"
GHOSTTY_DEST="$HOME/Library/Application Support/com.mitchellh.ghostty"

if [[ ! -f "$GHOSTTY_DATA" ]]; then
    echo "No Ghostty config data found. Skipping."
    exit 0
fi

mkdir -p "$GHOSTTY_DEST"

if [[ -f "$GHOSTTY_DEST/config" ]]; then
    if cmp -s "$GHOSTTY_DATA" "$GHOSTTY_DEST/config"; then
        green "Ghostty config already matches, skipping."
        exit 0
    fi
    cp "$GHOSTTY_DEST/config" "$GHOSTTY_DEST/config.bak.$(date +%Y%m%d%H%M%S)"
    yellow "Backed up existing Ghostty config"
fi

cp "$GHOSTTY_DATA" "$GHOSTTY_DEST/config"
green "Ghostty config restored."
yellow "Reload Ghostty config with Cmd+Shift+, or restart the app."
