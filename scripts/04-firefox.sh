#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/../data"

green()  { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red()    { printf '\033[31m%s\033[0m\n' "$1"; }

FF_DATA="$DATA/firefox"

# Read profile name saved during export, or use env var override
if [[ -n "${FIREFOX_PROFILE:-}" ]]; then
    PROFILE_NAME="$FIREFOX_PROFILE"
elif [[ -f "$FF_DATA/.profile-name" ]]; then
    PROFILE_NAME=$(cat "$FF_DATA/.profile-name")
else
    # Fall back to the first directory found in the export
    PROFILE_NAME=$(ls "$FF_DATA/" 2>/dev/null | head -1 || true)
fi

if [[ -z "${PROFILE_NAME:-}" ]] || [[ ! -d "$FF_DATA/$PROFILE_NAME" ]]; then
    echo "No Firefox profile data found. Skipping."
    exit 0
fi

# Firefox must be closed for a clean restore
if pgrep -x "firefox" &>/dev/null; then
    red "Firefox is running. Please close it and re-run this script."
    exit 1
fi

FF_BASE="$HOME/Library/Application Support/Firefox"
FF_PROFILES="$FF_BASE/Profiles"

# Ensure Firefox has been launched at least once to create the base dir.
# If not, create the structure ourselves.
mkdir -p "$FF_PROFILES"

DEST="$FF_PROFILES/$PROFILE_NAME"

if [[ -d "$DEST" ]]; then
    yellow "Existing profile found at $DEST"
    backup="${DEST}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$DEST" "$backup"
    yellow "Backed up to $(basename "$backup")"
fi

green "Restoring Firefox profile (this may take a while)..."
rsync -a "$FF_DATA/$PROFILE_NAME/" "$DEST/"
green "Profile restored."

# Restore profiles.ini
if [[ -f "$FF_DATA/profiles.ini" ]]; then
    if [[ -f "$FF_BASE/profiles.ini" ]]; then
        cp "$FF_BASE/profiles.ini" "$FF_BASE/profiles.ini.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$FF_DATA/profiles.ini" "$FF_BASE/profiles.ini"
    green "profiles.ini restored."
fi

green "Firefox profile restore complete."
yellow "If Firefox shows the profile picker on first launch, select '$PROFILE_NAME'."
