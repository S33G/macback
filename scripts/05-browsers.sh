#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

# ── Chrome Bookmarks ───────────────────────────────────────────────
if [[ -f "$DATA/chrome/Bookmarks" ]]; then
    green "Restoring Chrome bookmarks..."

    if pgrep -x "Google Chrome" &>/dev/null; then
        red "Chrome is running. Please close it first."
    else
        CHROME_DEFAULT="$HOME/Library/Application Support/Google/Chrome/Default"
        if [[ -d "$CHROME_DEFAULT" ]]; then
            if [[ -f "$CHROME_DEFAULT/Bookmarks" ]]; then
                cp "$CHROME_DEFAULT/Bookmarks" "$CHROME_DEFAULT/Bookmarks.bak.$(date +%Y%m%d%H%M%S)"
                yellow "Backed up existing Chrome bookmarks"
            fi
            cp "$DATA/chrome/Bookmarks" "$CHROME_DEFAULT/Bookmarks"
            green "Chrome bookmarks restored."
        else
            yellow "Chrome Default profile dir not found."
            yellow "Launch Chrome once first, then re-run this script."
            yellow "Alternatively, import manually: chrome://bookmarks → ⋮ → Import bookmarks"
            mkdir -p "$CHROME_DEFAULT"
            cp "$DATA/chrome/Bookmarks" "$CHROME_DEFAULT/Bookmarks"
            green "Chrome bookmarks placed (Chrome may need a restart to pick them up)."
        fi
    fi
else
    yellow "No Chrome bookmarks data found. Skipping."
fi

echo ""

# ── Safari Bookmarks ───────────────────────────────────────────────
if [[ -f "$DATA/safari/Bookmarks.plist" ]]; then
    green "Restoring Safari bookmarks..."

    if pgrep -x "Safari" &>/dev/null; then
        red "Safari is running. Please close it first."
    else
        SAFARI_DIR="$HOME/Library/Safari"
        mkdir -p "$SAFARI_DIR"
        if [[ -f "$SAFARI_DIR/Bookmarks.plist" ]]; then
            cp "$SAFARI_DIR/Bookmarks.plist" "$SAFARI_DIR/Bookmarks.plist.bak.$(date +%Y%m%d%H%M%S)"
            yellow "Backed up existing Safari bookmarks"
        fi
        cp "$DATA/safari/Bookmarks.plist" "$SAFARI_DIR/Bookmarks.plist"
        green "Safari bookmarks restored."
    fi
else
    yellow "No Safari bookmarks data found. Skipping."
fi
