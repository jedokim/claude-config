# claude-config

Shared [Claude Code](https://claude.ai/code) configuration across my machines — a custom status
line plus my global settings. Works on macOS, Linux, and Windows (via Git Bash).

## What the status line shows

```
[Opus 5] 📁 my-project | 🌿 main | 🧠 Context-used: 12% (120k) | Context-left: 88% (880k)
```

Model name (yellow) · working directory · git branch · context used and remaining, as both a
percentage and a token count. Past 70% usage it appends `⚠️ use compact`.

## Setup on a new machine

**1. Install prerequisites**

| Platform | Command |
|---|---|
| macOS | `brew install jq gh` |
| Windows | `winget install jqlang.jq GitHub.cli` |
| Linux | `sudo apt install jq gh` |

Claude Code on Windows already requires Git Bash, so the shell script runs as-is — `jq` is the
only extra piece.

**2. Clone to the expected path**

The path matters: `settings.json` points at `~/.claude-config/statusline.sh`.

```bash
gh auth login              # once per machine
git clone https://github.com/jedokim/claude-config.git ~/.claude-config
```

**3. Run the installer**

```bash
bash ~/.claude-config/install.sh
```

On Windows, either run that same command from Git Bash, or from PowerShell:

```powershell
& "$HOME\.claude-config\install.ps1"
```

Then restart Claude Code.

## How updates work

The two files sync differently, on purpose:

- **`statusline.sh` is referenced in place.** `settings.json` points directly at this repo, so
  `git pull` is all it takes — no reinstall.
- **`settings.json` is copied into `~/.claude/`.** Claude Code writes to that file itself
  (`/model`, plugin toggles), so it can't safely live in the repo. Re-run `install.sh` after
  pulling settings changes.

```bash
cd ~/.claude-config && git pull      # status line updates immediately
bash install.sh                      # only needed if settings.json changed
```

To push a settings change *up* from a machine:

```bash
cp ~/.claude/settings.json ~/.claude-config/settings.json
cd ~/.claude-config
# check the diff first - strip anything machine-specific
git diff
git commit -am "update settings" && git push
```

## Safety notes

- `install.sh` **merges** rather than overwrites: shared values win, machine-only keys survive.
- Your previous `settings.json` is backed up to `settings.json.backup.<timestamp>` on every run.
- Backups are gitignored.

## Machine-specific config

Keep anything that shouldn't sync out of this repo. Claude Code reads settings in precedence
order, so per-machine overrides belong in:

- `~/.claude/settings.local.json` — user-level, not synced here
- `<project>/.claude/settings.json` — per-project

The `swift-lsp` plugin is deliberately **not** in the shared `settings.json`, since it's only
useful on the Macs. Enable it locally where you want it.

## Files

| File | Purpose |
|---|---|
| `statusline.sh` | The status line script. Reads session JSON on stdin, prints one line. |
| `settings.json` | Shared global settings — model, effort level, TUI mode, plugins. |
| `install.sh` | Installer for macOS / Linux / Git Bash. |
| `install.ps1` | Installer for Windows PowerShell. |
