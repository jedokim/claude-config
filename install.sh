#!/bin/bash
# Install shared Claude Code config on macOS / Linux / Git Bash on Windows.
# Safe to re-run. Merges into any existing settings.json rather than clobbering it.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq is required but not installed." >&2
    echo "  macOS:   brew install jq" >&2
    echo "  Windows: winget install jqlang.jq" >&2
    echo "  Linux:   sudo apt install jq" >&2
    exit 1
fi

mkdir -p "$CLAUDE_DIR"
chmod +x "$REPO_DIR/statusline.sh"

if [ -f "$TARGET" ]; then
    backup="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    cp "$TARGET" "$backup"
    echo "backed up existing settings -> $backup"

    # Merge: shared repo values win, but any machine-only keys are preserved.
    tmp="$(mktemp)"
    jq -s '.[0] * .[1]' "$TARGET" "$REPO_DIR/settings.json" > "$tmp"
    mv "$tmp" "$TARGET"
    echo "merged shared settings into $TARGET"
else
    cp "$REPO_DIR/settings.json" "$TARGET"
    echo "installed settings -> $TARGET"
fi

echo
echo "Done. Status line runs from: $REPO_DIR/statusline.sh"
echo "Restart Claude Code (or run /config) to pick it up."
