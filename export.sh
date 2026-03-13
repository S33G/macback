#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

step() { green "==> $1"; }
warn() { yellow "  ! $1"; }
fail() { red "  ✗ $1"; }

is_running() { pgrep -x "$1" &>/dev/null; }

mkdir -p "$DATA"

# ── Homebrew ────────────────────────────────────────────────────────
step "Exporting Homebrew Brewfile"
if command -v brew &>/dev/null; then
    brew bundle dump --file="$DATA/Brewfile" --force 2>/dev/null
    green "  Brewfile written ($(wc -l < "$DATA/Brewfile") entries)"
else
    fail "Homebrew not found, skipping Brewfile"
fi

# ── NVM / Pyenv version lists ──────────────────────────────────────
step "Exporting runtime version lists"
if [[ -d "$HOME/.nvm/versions/node" ]]; then
    ls "$HOME/.nvm/versions/node/" > "$DATA/nvm-versions.txt"
    green "  NVM versions: $(wc -l < "$DATA/nvm-versions.txt")"
fi
if [[ -d "$HOME/.pyenv/versions" ]]; then
    ls "$HOME/.pyenv/versions/" > "$DATA/pyenv-versions.txt"
    green "  Pyenv versions: $(wc -l < "$DATA/pyenv-versions.txt")"
fi

# ── Shell Configs ───────────────────────────────────────────────────
step "Exporting shell configuration files"
mkdir -p "$DATA/shell"
for f in .zshrc .zprofile .bash_profile .bashrc .gitconfig .npmrc; do
    if [[ -f "$HOME/$f" ]]; then
        cp "$HOME/$f" "$DATA/shell/$f"
        green "  Copied $f"
    else
        warn "$f not found, skipping"
    fi
done

# ── SSH ─────────────────────────────────────────────────────────────
step "Exporting SSH keys and config"
mkdir -p "$DATA/ssh"
for f in config id_ed25519 id_ed25519.pub id_rsa id_rsa.pub ai_cluster_key ai_cluster_key.pub known_hosts; do
    if [[ -f "$HOME/.ssh/$f" ]]; then
        cp -p "$HOME/.ssh/$f" "$DATA/ssh/$f"
        green "  Copied .ssh/$f"
    else
        warn ".ssh/$f not found, skipping"
    fi
done

# ── Firefox (full profile) ─────────────────────────────────────────
step "Exporting Firefox profile (full backup)"
FF_BASE="$HOME/Library/Application Support/Firefox"

# Auto-detect profile: use FIREFOX_PROFILE env var, or find the default-release profile
if [[ -n "${FIREFOX_PROFILE:-}" ]]; then
    FF_PROFILE_NAME="$FIREFOX_PROFILE"
elif [[ -d "$FF_BASE/Profiles" ]]; then
    FF_PROFILE_NAME=$(ls "$FF_BASE/Profiles/" 2>/dev/null | grep '\.default-release$' | head -1 || true)
fi

if [[ -z "${FF_PROFILE_NAME:-}" ]]; then
    fail "No Firefox profile found. Set FIREFOX_PROFILE=<profile-dir-name> to specify one."
elif is_running "firefox"; then
    red "  Firefox is running! Close it first for a clean profile copy."
    red "  Skipping Firefox export."
else
    FF_PROFILE="$FF_BASE/Profiles/$FF_PROFILE_NAME"
    if [[ -d "$FF_PROFILE" ]]; then
        mkdir -p "$DATA/firefox"
        green "  Using profile: $FF_PROFILE_NAME"
        green "  Copying profile (this may take a while)..."
        rsync -a --delete "$FF_PROFILE/" "$DATA/firefox/$FF_PROFILE_NAME/"
        # Save the profile name for the restore script
        echo "$FF_PROFILE_NAME" > "$DATA/firefox/.profile-name"
        green "  Profile copied"
        if [[ -f "$FF_BASE/profiles.ini" ]]; then
            cp "$FF_BASE/profiles.ini" "$DATA/firefox/profiles.ini"
            green "  Copied profiles.ini"
        fi
    else
        fail "Firefox profile not found at $FF_PROFILE"
    fi
fi

# ── Chrome (bookmarks only) ────────────────────────────────────────
step "Exporting Chrome bookmarks"
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
CHROME_BM=""
for profile in "Default" "Profile 1" "Profile 2" "Profile 3"; do
    if [[ -f "$CHROME_DIR/$profile/Bookmarks" ]]; then
        CHROME_BM="$CHROME_DIR/$profile/Bookmarks"
        break
    fi
done
if [[ -n "$CHROME_BM" ]]; then
    mkdir -p "$DATA/chrome"
    cp "$CHROME_BM" "$DATA/chrome/Bookmarks"
    green "  Chrome bookmarks copied from $(dirname "$CHROME_BM" | xargs basename)"
else
    warn "No Chrome bookmarks found in any profile"
fi

# ── Safari (bookmarks) ─────────────────────────────────────────────
step "Exporting Safari bookmarks"
SAFARI_BM="$HOME/Library/Safari/Bookmarks.plist"
if [[ -f "$SAFARI_BM" ]]; then
    mkdir -p "$DATA/safari"
    if cp "$SAFARI_BM" "$DATA/safari/Bookmarks.plist" 2>/dev/null; then
        green "  Safari bookmarks copied"
    else
        warn "Safari bookmarks copy failed (Full Disk Access required)."
        warn "Grant Terminal/shell Full Disk Access in:"
        warn "  System Settings → Privacy & Security → Full Disk Access"
        warn "Then re-run this export."
    fi
else
    warn "Safari bookmarks not found"
fi

# ── VS Code ─────────────────────────────────────────────────────────
step "Exporting VS Code settings and extensions"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
mkdir -p "$DATA/vscode"
if [[ -f "$VSCODE_USER/settings.json" ]]; then
    cp "$VSCODE_USER/settings.json" "$DATA/vscode/settings.json"
    green "  settings.json copied"
fi
if command -v code &>/dev/null; then
    code --list-extensions > "$DATA/vscode/extensions.txt" 2>/dev/null
    green "  Extensions list: $(wc -l < "$DATA/vscode/extensions.txt") extensions"
else
    warn "code CLI not found, skipping extension list"
fi

# ── Cursor ──────────────────────────────────────────────────────────
step "Exporting Cursor settings"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
mkdir -p "$DATA/cursor"
if [[ -f "$CURSOR_USER/settings.json" ]]; then
    cp "$CURSOR_USER/settings.json" "$DATA/cursor/settings.json"
    green "  settings.json copied"
else
    warn "Cursor settings.json not found"
fi

# ── Ghostty ─────────────────────────────────────────────────────────
step "Exporting Ghostty config"
GHOSTTY_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
mkdir -p "$DATA/ghostty"
if [[ -f "$GHOSTTY_CFG" ]]; then
    cp "$GHOSTTY_CFG" "$DATA/ghostty/config"
    green "  Ghostty config copied"
else
    warn "Ghostty config not found"
fi

# ── macOS Preferences ──────────────────────────────────────────────
step "Exporting macOS preferences"
mkdir -p "$DATA/macos"

# Rectangle
if defaults read com.knollsoft.Rectangle &>/dev/null; then
    defaults export com.knollsoft.Rectangle "$DATA/macos/rectangle.plist"
    green "  Rectangle preferences exported"
else
    warn "Rectangle preferences not found"
fi

# AltTab
if defaults read com.lwouis.alt-tab-macos &>/dev/null; then
    defaults export com.lwouis.alt-tab-macos "$DATA/macos/alttab.plist"
    green "  AltTab preferences exported"
else
    warn "AltTab preferences not found"
fi

# Dock defaults → restore script
dock_orient=$(defaults read com.apple.dock orientation 2>/dev/null || echo 'bottom')
dock_autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo '0')
dock_size=$(defaults read com.apple.dock tilesize 2>/dev/null || echo '48')

cat > "$DATA/macos/dock-defaults.sh" <<DOCK
#!/usr/bin/env bash
defaults write com.apple.dock orientation -string "$dock_orient"
defaults write com.apple.dock autohide -bool $( [[ "$dock_autohide" == "1" ]] && echo true || echo false )
defaults write com.apple.dock tilesize -int $dock_size
killall Dock
DOCK
chmod +x "$DATA/macos/dock-defaults.sh"
green "  Dock defaults captured (orientation=$dock_orient, autohide=$dock_autohide, size=$dock_size)"

# Finder defaults → restore script
finder_show_all=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 'false')

cat > "$DATA/macos/finder-defaults.sh" <<FINDER
#!/usr/bin/env bash
defaults write com.apple.finder AppleShowAllFiles -bool $( [[ "$finder_show_all" == "true" || "$finder_show_all" == "1" ]] && echo true || echo false )
killall Finder
FINDER
chmod +x "$DATA/macos/finder-defaults.sh"
green "  Finder defaults captured (ShowAllFiles=$finder_show_all)"

# ── SwiftBar Plugins ───────────────────────────────────────────────
step "Exporting SwiftBar plugins"
SWIFTBAR_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
if [[ -d "$SWIFTBAR_DIR" ]]; then
    mkdir -p "$DATA/swiftbar"
    copied=0
    for f in "$SWIFTBAR_DIR/"*; do
        [[ -e "$f" ]] || continue
        bname=$(basename "$f")
        [[ "$bname" == ".DS_Store" || "$bname" == ".cache" ]] && continue
        cp -L -p "$f" "$DATA/swiftbar/$bname" 2>/dev/null && {
            green "  Copied $bname"
            copied=$((copied + 1))
        }
    done
    [[ $copied -eq 0 ]] && warn "No SwiftBar plugins to copy"
else
    warn "SwiftBar plugins directory not found"
fi

# ── LaunchAgents ────────────────────────────────────────────────────
step "Exporting user LaunchAgents"
LA_DIR="$HOME/Library/LaunchAgents"
if [[ -d "$LA_DIR" ]]; then
    mkdir -p "$DATA/launchagents"
    for f in "$LA_DIR/"*.plist; do
        [[ -f "$f" ]] || continue
        cp "$f" "$DATA/launchagents/"
        green "  Copied $(basename "$f")"
    done
else
    warn "No LaunchAgents directory found"
fi

# ── Summary ─────────────────────────────────────────────────────────
echo ""
green "========================================="
green "  Export complete!"
green "  Data directory: $DATA"
green "========================================="
echo ""
du -sh "$DATA" 2>/dev/null || true
echo ""
echo "Transfer this folder to your new machine and run:"
echo "  ./install.sh"
