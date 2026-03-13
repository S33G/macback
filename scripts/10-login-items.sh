#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }

# ── SwiftBar Plugins ───────────────────────────────────────────────
SWIFTBAR_DATA="$DATA/swiftbar"
SWIFTBAR_DEST="$HOME/Library/Application Support/SwiftBar/Plugins"

if [[ -d "$SWIFTBAR_DATA" ]] && ls "$SWIFTBAR_DATA/"* &>/dev/null; then
    green "Restoring SwiftBar plugins..."
    mkdir -p "$SWIFTBAR_DEST"
    for f in "$SWIFTBAR_DATA/"*; do
        [[ -f "$f" ]] || continue
        cp -p "$f" "$SWIFTBAR_DEST/"
        chmod +x "$SWIFTBAR_DEST/$(basename "$f")"
        green "  Installed $(basename "$f")"
    done
else
    yellow "No SwiftBar plugin data found, skipping."
fi

# ── LaunchAgents ────────────────────────────────────────────────────
LA_DATA="$DATA/launchagents"
LA_DEST="$HOME/Library/LaunchAgents"

if [[ -d "$LA_DATA" ]] && ls "$LA_DATA/"*.plist &>/dev/null; then
    green "Restoring user LaunchAgents..."
    mkdir -p "$LA_DEST"
    for f in "$LA_DATA/"*.plist; do
        [[ -f "$f" ]] || continue
        bname=$(basename "$f")
        if [[ -f "$LA_DEST/$bname" ]]; then
            cp "$LA_DEST/$bname" "$LA_DEST/${bname}.bak.$(date +%Y%m%d%H%M%S)"
            yellow "  Backed up existing $bname"
        fi
        cp "$f" "$LA_DEST/$bname"
        green "  Installed $bname"
    done
    echo ""
    yellow "To load LaunchAgents now:"
    for f in "$LA_DATA/"*.plist; do
        bname=$(basename "$f")
        echo "  launchctl load ~/Library/LaunchAgents/$bname"
    done
else
    yellow "No LaunchAgent data found, skipping."
fi

echo ""
green "Login items restore complete."
echo ""
yellow "═══════════════════════════════════════════════════════"
yellow "  MANUAL: Re-enable login items in System Settings"
yellow "═══════════════════════════════════════════════════════"
echo ""
echo "After installing your login item apps, enable them in:"
echo "  System Settings → General → Login Items"
echo ""
echo "Common login items (edit this list in scripts/10-login-items.sh):"
echo ""
# ── Customize this list to match your setup ──
LOGIN_ITEMS=(
    "Rectangle"
    "SwiftBar"
    "Stats"
)
for app in "${LOGIN_ITEMS[@]}"; do
    echo "  - $app"
done
