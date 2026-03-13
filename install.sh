#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
LOG_FILE="$SCRIPT_DIR/install.log"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$LOG_FILE"; }

confirm() {
    local msg="$1"
    printf '\033[36m%s [y/N] \033[0m' "$msg"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

cat <<'BANNER'

  ┌──────────────────────────────────────┐
  │     macback                          │
  │     macOS Machine Restore            │
  └──────────────────────────────────────┘

BANNER

if [[ ! -d "$SCRIPT_DIR/data" ]]; then
    red "Error: data/ directory not found."
    red "Run export.sh on the source machine first."
    exit 1
fi

echo "Install log: $LOG_FILE"
: > "$LOG_FILE"
log "Install started"
echo ""

scripts=(
    "01-homebrew.sh:Homebrew packages"
    "02-shell-configs.sh:Shell configuration files"
    "03-ssh.sh:SSH keys and config"
    "04-firefox.sh:Firefox profile"
    "05-browsers.sh:Chrome & Safari bookmarks"
    "06-vscode.sh:VS Code settings & extensions"
    "07-cursor.sh:Cursor settings"
    "08-ghostty.sh:Ghostty config"
    "09-macos-prefs.sh:macOS preferences (Dock, Finder, Rectangle, AltTab)"
    "10-login-items.sh:SwiftBar plugins & LaunchAgents"
)

for entry in "${scripts[@]}"; do
    script_file="${entry%%:*}"
    description="${entry#*:}"
    script_path="$SCRIPTS_DIR/$script_file"

    if [[ ! -f "$script_path" ]]; then
        yellow "Script not found: $script_file — skipping"
        log "SKIP $script_file (not found)"
        continue
    fi

    echo "────────────────────────────────────────"
    if confirm "Install: $description?"; then
        log "RUN $script_file"
        green "Running $script_file..."
        if bash "$script_path" 2>&1 | tee -a "$LOG_FILE"; then
            log "OK $script_file"
            green "Done: $description"
        else
            log "FAIL $script_file"
            red "Failed: $description (check $LOG_FILE)"
        fi
    else
        log "SKIP $script_file (user declined)"
        yellow "Skipped: $description"
    fi
    echo ""
done

echo "════════════════════════════════════════"
green "All steps complete."
echo "Log saved to: $LOG_FILE"
echo ""
yellow "Manual steps remaining:"
echo "  1. Re-add SSH keys to agent:  ssh-add ~/.ssh/id_ed25519"
echo "  2. Re-enable login items in System Settings > General > Login Items"
echo "  3. Select Firefox profile on first launch if prompted"
echo "  4. Install NVM node versions from data/nvm-versions.txt"
echo "  5. Install Pyenv python versions from data/pyenv-versions.txt"
