#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

CURSOR_DATA="$DATA/cursor"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"

if [[ ! -f "$CURSOR_DATA/settings.json" ]]; then
    echo "No Cursor settings data found. Skipping."
    exit 0
fi

mkdir -p "$CURSOR_USER"

if [[ -f "$CURSOR_USER/settings.json" ]]; then
    if cmp -s "$CURSOR_DATA/settings.json" "$CURSOR_USER/settings.json"; then
        green "Cursor settings.json already matches, skipping."
        exit 0
    fi
    cp "$CURSOR_USER/settings.json" "$CURSOR_USER/settings.json.bak.$(date +%Y%m%d%H%M%S)"
    yellow "Backed up existing Cursor settings.json"
fi

cp "$CURSOR_DATA/settings.json" "$CURSOR_USER/settings.json"
green "Cursor settings.json restored."
