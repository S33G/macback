#!/usr/bin/env bash
set -euo pipefail

# Generic macOS machine auditor.
# Scans common config locations and produces a markdown report.
# Safe to run on any Mac — read-only, no modifications.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORT="${1:-$SCRIPT_DIR/report.md}"

section() { printf '\n## %s\n\n' "$1" >> "$REPORT"; }
item()    { printf -- '- %s\n' "$1" >> "$REPORT"; }
code_block() { printf '```\n%s\n```\n' "$1" >> "$REPORT"; }
check_file() {
    if [[ -f "$1" ]]; then item "**Found**: \`$1\`"
    else item "_Missing_: \`$1\`"; fi
}
check_dir() {
    if [[ -d "$1" ]]; then item "**Found**: \`$1/\`"
    else item "_Missing_: \`$1/\`"; fi
}

: > "$REPORT"

cat >> "$REPORT" <<'HEADER'
# macOS Machine Audit Report
HEADER
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT"

# ── System ──────────────────────────────────────────────────────────
section "System Info"
item "**Hostname**: $(scutil --get ComputerName 2>/dev/null || hostname)"
item "**macOS**: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
item "**Chip**: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')"
item "**Serial**: $(ioreg -l | grep IOPlatformSerialNumber | awk -F'"' '{print $4}' 2>/dev/null || echo 'unknown')"
item "**Shell**: $SHELL"

# ── Applications ────────────────────────────────────────────────────
section "Installed Applications"

printf '### /Applications\n\n' >> "$REPORT"
if [[ -d /Applications ]]; then
    code_block "$(ls /Applications/ 2>/dev/null | sed 's/\.app$//')"
fi

printf '\n### ~/Applications\n\n' >> "$REPORT"
if [[ -d "$HOME/Applications" ]]; then
    code_block "$(ls "$HOME/Applications/" 2>/dev/null | sed 's/\.app$//')"
else
    item "_None found_"
fi

printf '\n### Homebrew\n\n' >> "$REPORT"
if command -v brew &>/dev/null; then
    item "**Homebrew installed**: $(brew --version | head -1)"
    formulae=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    casks=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    item "**Formulae**: $formulae"
    item "**Casks**: $casks"
    printf '\nFormulae:\n' >> "$REPORT"
    code_block "$(brew list --formula 2>/dev/null)"
    printf '\nCasks:\n' >> "$REPORT"
    code_block "$(brew list --cask 2>/dev/null)"
    printf '\nTaps:\n' >> "$REPORT"
    code_block "$(brew tap 2>/dev/null)"
else
    item "_Homebrew not installed_"
fi

# ── Browsers ────────────────────────────────────────────────────────
section "Browsers"

printf '### Firefox\n\n' >> "$REPORT"
FF_DIR="$HOME/Library/Application Support/Firefox"
if [[ -d "$FF_DIR/Profiles" ]]; then
    item "**Profiles directory**: \`$FF_DIR/Profiles/\`"
    for profile_dir in "$FF_DIR/Profiles/"*/; do
        [[ -d "$profile_dir" ]] || continue
        pname=$(basename "$profile_dir")
        item "  Profile: \`$pname\`"
        if [[ -d "$profile_dir/extensions" ]]; then
            ext_count=$(ls "$profile_dir/extensions/" 2>/dev/null | wc -l | tr -d ' ')
            item "    Extensions: $ext_count"
        fi
        if [[ -f "$profile_dir/places.sqlite" ]]; then
            item "    Has bookmarks/history (places.sqlite)"
        fi
    done
else
    item "_Firefox not found or no profiles_"
fi

printf '\n### Google Chrome\n\n' >> "$REPORT"
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
if [[ -d "$CHROME_DIR" ]]; then
    item "**Chrome data dir**: \`$CHROME_DIR/\`"
    for d in "$CHROME_DIR"/*/; do
        bname=$(basename "$d")
        if [[ -f "$d/Bookmarks" ]]; then
            item "  Profile: \`$bname\` (has Bookmarks)"
        fi
    done
else
    item "_Chrome not found_"
fi

printf '\n### Safari\n\n' >> "$REPORT"
if [[ -f "$HOME/Library/Safari/Bookmarks.plist" ]]; then
    item "**Bookmarks.plist found**"
else
    item "_No Safari bookmarks found_"
fi

for browser in "Arc" "BraveSoftware/Brave-Browser" "Microsoft Edge"; do
    bdir="$HOME/Library/Application Support/$browser"
    short=$(basename "$browser")
    printf '\n### %s\n\n' "$short" >> "$REPORT"
    if [[ -d "$bdir" ]]; then
        item "**Data dir found**: \`$bdir/\`"
    else
        item "_Not installed_"
    fi
done

# ── Shell Configs ───────────────────────────────────────────────────
section "Shell Configuration"

for f in .zshrc .zprofile .zshenv .bashrc .bash_profile .profile .mkshrc; do
    check_file "$HOME/$f"
done

printf '\n### Oh My Zsh\n\n' >> "$REPORT"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    item "**Installed**: \`$HOME/.oh-my-zsh/\`"
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
        customs=$(ls "$HOME/.oh-my-zsh/custom/plugins/" 2>/dev/null | grep -v '^example$' || true)
        if [[ -n "$customs" ]]; then
            item "Custom plugins: $customs"
        else
            item "No custom plugins"
        fi
    fi
    if [[ -d "$HOME/.oh-my-zsh/custom/themes" ]]; then
        themes=$(ls "$HOME/.oh-my-zsh/custom/themes/" 2>/dev/null | grep -v '^example' || true)
        if [[ -n "$themes" ]]; then
            item "Custom themes: $themes"
        else
            item "No custom themes"
        fi
    fi
else
    item "_Oh My Zsh not installed_"
fi

# ── Git ─────────────────────────────────────────────────────────────
section "Git"
check_file "$HOME/.gitconfig"
if [[ -f "$HOME/.gitconfig" ]]; then
    code_block "$(cat "$HOME/.gitconfig")"
fi

# ── SSH ─────────────────────────────────────────────────────────────
section "SSH"
if [[ -d "$HOME/.ssh" ]]; then
    item "**\`~/.ssh/\` contents**:"
    for f in "$HOME/.ssh/"*; do
        [[ -f "$f" ]] || continue
        bname=$(basename "$f")
        perms=$(stat -f '%Lp' "$f" 2>/dev/null || stat -c '%a' "$f" 2>/dev/null || echo '???')
        item "  \`$bname\` (mode $perms)"
    done
    if [[ -f "$HOME/.ssh/config" ]]; then
        printf '\nSSH config hosts:\n' >> "$REPORT"
        code_block "$(grep -E '^Host ' "$HOME/.ssh/config" 2>/dev/null || echo '(none)')"
    fi
else
    item "_No ~/.ssh directory_"
fi

# ── GPG ─────────────────────────────────────────────────────────────
section "GPG Keys"
if command -v gpg &>/dev/null; then
    keys=$(gpg --list-keys 2>/dev/null)
    if [[ -n "$keys" ]]; then
        code_block "$keys"
    else
        item "_No GPG keys found_"
    fi
else
    item "_gpg not installed_"
fi

# ── Dev Tool Runtimes ───────────────────────────────────────────────
section "Development Runtimes"

printf '### Node.js / NVM\n\n' >> "$REPORT"
if [[ -d "$HOME/.nvm/versions/node" ]]; then
    item "**NVM installed**"
    item "Versions:"
    code_block "$(ls "$HOME/.nvm/versions/node/" 2>/dev/null)"
else
    item "_NVM not found_"
fi

printf '\n### Python / Pyenv\n\n' >> "$REPORT"
if [[ -d "$HOME/.pyenv/versions" ]]; then
    item "**Pyenv installed**"
    item "Versions:"
    code_block "$(ls "$HOME/.pyenv/versions/" 2>/dev/null)"
else
    item "_Pyenv not found_"
fi

printf '\n### Rust / Cargo\n\n' >> "$REPORT"
check_dir "$HOME/.cargo"

printf '\n### Go\n\n' >> "$REPORT"
if command -v go &>/dev/null; then
    item "**Go**: $(go version 2>/dev/null)"
else
    item "_Go not installed_"
fi

printf '\n### Bun\n\n' >> "$REPORT"
check_dir "$HOME/.bun"

printf '\n### Deno\n\n' >> "$REPORT"
check_dir "$HOME/.deno"

printf '\n### Docker\n\n' >> "$REPORT"
check_dir "$HOME/.docker"

printf '\n### Kubernetes\n\n' >> "$REPORT"
check_dir "$HOME/.kube"

# ── IDE Configs ─────────────────────────────────────────────────────
section "IDE & Editor Configurations"

printf '### VS Code\n\n' >> "$REPORT"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_USER" ]]; then
    item "**Settings dir**: \`$VSCODE_USER/\`"
    check_file "$VSCODE_USER/settings.json"
    check_file "$VSCODE_USER/keybindings.json"
    if command -v code &>/dev/null; then
        ext_count=$(code --list-extensions 2>/dev/null | wc -l | tr -d ' ')
        item "**Extensions installed**: $ext_count"
    fi
else
    item "_VS Code user dir not found_"
fi

printf '\n### Cursor\n\n' >> "$REPORT"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_USER" ]]; then
    item "**Settings dir**: \`$CURSOR_USER/\`"
    check_file "$CURSOR_USER/settings.json"
else
    item "_Cursor user dir not found_"
fi

printf '\n### Xcode\n\n' >> "$REPORT"
if [[ -d "/Applications/Xcode.app" ]]; then
    item "**Xcode installed**"
else
    item "_Xcode not installed_"
fi

printf '\n### Ghostty\n\n' >> "$REPORT"
GHOSTTY_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -f "$GHOSTTY_CFG" ]]; then
    item "**Config found**: \`$GHOSTTY_CFG\`"
else
    item "_No Ghostty config_"
fi

printf '\n### kitty\n\n' >> "$REPORT"
check_file "$HOME/.config/kitty/kitty.conf"

printf '\n### iTerm2\n\n' >> "$REPORT"
check_file "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

printf '\n### Warp\n\n' >> "$REPORT"
check_dir "$HOME/.warp"

# ── macOS Preferences ──────────────────────────────────────────────
section "macOS Preferences"

printf '### Dock\n\n' >> "$REPORT"
dock_orient=$(defaults read com.apple.dock orientation 2>/dev/null || echo 'bottom')
dock_autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo '0')
dock_size=$(defaults read com.apple.dock tilesize 2>/dev/null || echo 'default')
item "**Orientation**: $dock_orient"
item "**Autohide**: $dock_autohide"
item "**Tile size**: $dock_size"
printf '\nDock apps:\n' >> "$REPORT"
dock_apps=$(defaults read com.apple.dock persistent-apps 2>/dev/null | grep '"file-label"' | sed 's/.*= "\(.*\)";/\1/' || echo '(could not read)')
code_block "$dock_apps"

printf '\n### Finder\n\n' >> "$REPORT"
show_all=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 'not set')
item "**Show all files**: $show_all"

printf '\n### Keyboard\n\n' >> "$REPORT"
key_repeat=$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null || echo 'default')
initial_repeat=$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null || echo 'default')
item "**Key repeat**: $key_repeat"
item "**Initial key repeat**: $initial_repeat"

printf '\n### Screenshots\n\n' >> "$REPORT"
ss_location=$(defaults read com.apple.screencapture location 2>/dev/null || echo 'default (Desktop)')
ss_type=$(defaults read com.apple.screencapture type 2>/dev/null || echo 'default (png)')
item "**Location**: $ss_location"
item "**Format**: $ss_type"

# ── Utility Apps ────────────────────────────────────────────────────
section "Utility App Configurations"

for app_info in \
    "Rectangle:com.knollsoft.Rectangle" \
    "AltTab:com.lwouis.alt-tab-macos" \
    "Karabiner:$HOME/.config/karabiner/karabiner.json" \
    "Hammerspoon:$HOME/.hammerspoon/init.lua" \
    "BetterDisplay:pro.betterdisplay.BetterDisplay"; do

    app_name="${app_info%%:*}"
    app_id="${app_info#*:}"
    printf '\n### %s\n\n' "$app_name" >> "$REPORT"

    if [[ "$app_id" == */* ]]; then
        if [[ -f "$app_id" ]]; then
            item "**Config found**: \`$app_id\`"
        else
            item "_Config not found_"
        fi
    else
        if defaults read "$app_id" &>/dev/null; then
            item "**Preferences domain found**: \`$app_id\`"
        else
            item "_No preferences found_"
        fi
    fi
done

# ── Login Items & LaunchAgents ──────────────────────────────────────
section "Login Items & LaunchAgents"

printf '### Login Items\n\n' >> "$REPORT"
login_items=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo '(could not read)')
item "$login_items"

printf '\n### User LaunchAgents\n\n' >> "$REPORT"
if [[ -d "$HOME/Library/LaunchAgents" ]]; then
    for f in "$HOME/Library/LaunchAgents/"*; do
        [[ -f "$f" ]] && item "\`$(basename "$f")\`"
    done
else
    item "_No LaunchAgents directory_"
fi

# ── Custom Fonts ────────────────────────────────────────────────────
section "Custom Fonts"
if [[ -d "$HOME/Library/Fonts" ]]; then
    font_count=$(ls "$HOME/Library/Fonts/" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$font_count" -gt 0 ]]; then
        item "**$font_count font(s)** in \`~/Library/Fonts/\`"
        code_block "$(ls "$HOME/Library/Fonts/")"
    else
        item "_No custom fonts_"
    fi
else
    item "_No custom fonts directory_"
fi

# ── SwiftBar ────────────────────────────────────────────────────────
section "SwiftBar Plugins"
SWIFTBAR_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
if [[ -d "$SWIFTBAR_DIR" ]]; then
    for f in "$SWIFTBAR_DIR/"*; do
        [[ -f "$f" ]] && item "\`$(basename "$f")\`"
    done
else
    item "_No SwiftBar plugins found_"
fi

printf '\n---\n_End of audit._\n' >> "$REPORT"

echo "Audit complete: $REPORT"
