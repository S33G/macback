# macback

Bash scripts for migrating a macOS workstation to a new machine. Exports your apps, configs, keys, browser data, and preferences from a source Mac and restores them interactively on the target.

## What gets migrated

| Category | Export | Restore |
|---|---|---|
| Homebrew packages | Brewfile dump | `brew bundle` install |
| NVM / Pyenv versions | Version lists | Manual install commands printed |
| Shell configs | `.zshrc`, `.gitconfig`, `.npmrc`, etc. | Copy with backup |
| SSH keys & config | Full `~/.ssh/` | Copy with permissions |
| Firefox | Full profile | rsync restore |
| Chrome | Bookmarks | Copy to Default profile |
| Safari | Bookmarks.plist | Copy with backup |
| VS Code | settings.json + extensions list | Restore + bulk install |
| Cursor | settings.json | Copy with backup |
| Ghostty | Terminal config | Copy with backup |
| macOS preferences | Dock, Finder, Rectangle, AltTab | `defaults write` |
| SwiftBar plugins | Plugin scripts | Copy with +x |
| LaunchAgents | User plist files | Copy + load instructions |

## Quick start

### 1. Export (source machine)

```bash
./export.sh
```

This creates a `data/` directory containing everything listed above. The script is safe to re-run -- it overwrites previous exports.

### 2. Transfer

Copy the entire project directory (including `data/`) to the new machine. Use AirDrop, an external drive, `rsync`, or whatever you prefer:

```bash
rsync -avz ~/Desktop/macback user@new-mac:~/Desktop/
```

### 3. Install (target machine)

```bash
./install.sh
```

Walks through each restore step interactively. You're prompted before each one and can skip anything.

### Standalone audit

```bash
./audit.sh
```

Generates a read-only Markdown report (`report.md`) of everything installed and configured on the current machine. Makes no changes. Useful for inventory or pre-migration review.

## Configuration

Some scripts reference values specific to your machine. Set these environment variables before running if the defaults don't match your setup:

| Variable | Used by | Default | Description |
|---|---|---|---|
| `FIREFOX_PROFILE` | `export.sh`, `scripts/04-firefox.sh` | Auto-detected | Firefox profile directory name |

### Firefox profile

The export and restore scripts auto-detect your Firefox profile. If you have multiple profiles and want to target a specific one, set `FIREFOX_PROFILE`:

```bash
FIREFOX_PROFILE="abc123.default-release" ./export.sh
```

### Login items

The restore script (`scripts/10-login-items.sh`) prints a list of apps to re-enable as login items. Edit the list at the bottom of that script to match your setup.

## Project structure

```
macback/
  export.sh           # Run on source machine
  install.sh          # Run on target machine (interactive)
  audit.sh            # Standalone machine audit (read-only)
  scripts/            # Individual restore scripts called by install.sh
    01-homebrew.sh
    02-shell-configs.sh
    03-ssh.sh
    04-firefox.sh
    05-browsers.sh
    06-vscode.sh
    07-cursor.sh
    08-ghostty.sh
    09-macos-prefs.sh
    10-login-items.sh
  data/               # Created by export.sh (gitignored)
```

## Security

The `data/` directory is gitignored and **must never be committed**. It contains:

- SSH private keys
- Browser profiles (cookies, saved passwords, history)
- Shell configs (may contain tokens or API keys)
- App preferences

Review your exported `data/` before transferring it to another machine.

## Requirements

- macOS (tested on Sonoma / Sequoia)
- Bash 3.2+ (ships with macOS)
- Full Disk Access may be required for Safari bookmark export (System Settings > Privacy & Security > Full Disk Access)

## License

[MIT](LICENSE)
