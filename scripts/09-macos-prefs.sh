#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

MACOS_DATA="$DATA/macos"

if [[ ! -d "$MACOS_DATA" ]]; then
    echo "No macOS preferences data found. Skipping."
    exit 0
fi

# ── Dock ────────────────────────────────────────────────────────────
if [[ -f "$MACOS_DATA/dock-defaults.sh" ]]; then
    green "Applying Dock preferences..."
    bash "$MACOS_DATA/dock-defaults.sh"
    green "Dock preferences applied."
else
    yellow "No Dock defaults found, skipping."
fi

# ── Finder ──────────────────────────────────────────────────────────
if [[ -f "$MACOS_DATA/finder-defaults.sh" ]]; then
    green "Applying Finder preferences..."
    bash "$MACOS_DATA/finder-defaults.sh"
    green "Finder preferences applied."
else
    yellow "No Finder defaults found, skipping."
fi

# ── Rectangle ───────────────────────────────────────────────────────
if [[ -f "$MACOS_DATA/rectangle.plist" ]]; then
    green "Importing Rectangle preferences..."
    defaults import com.knollsoft.Rectangle "$MACOS_DATA/rectangle.plist"
    green "Rectangle preferences imported."
    yellow "Restart Rectangle for changes to take effect."
else
    yellow "No Rectangle preferences found, skipping."
fi

# ── AltTab ──────────────────────────────────────────────────────────
if [[ -f "$MACOS_DATA/alttab.plist" ]]; then
    green "Importing AltTab preferences..."
    defaults import com.lwouis.alt-tab-macos "$MACOS_DATA/alttab.plist"
    green "AltTab preferences imported."
    yellow "Restart AltTab for changes to take effect."
else
    yellow "No AltTab preferences found, skipping."
fi

green "macOS preferences restore complete."
