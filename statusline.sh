#!/bin/bash

# Claude Code reads JSON state from stdin
input=$(cat)

# Extract all fields in a single jq call (avoids 5 separate process forks)
IFS=$'\t' read -r model current_dir used_pct remaining_pct window_size <<< "$(jq -r '[
  (.model.display_name // "unknown"),
  (.workspace.current_dir // "."),
  (.context_window.used_percentage // 0),
  (.context_window.remaining_percentage // 100),
  (.context_window.context_window_size // 200000)
] | @tsv' <<< "$input")"

# Floor any fractional percentages so the arithmetic below can't fail
used_pct=${used_pct%%.*}
remaining_pct=${remaining_pct%%.*}
window_size=${window_size%%.*}

# Use parameter expansion instead of basename (avoids a fork)
dir=${current_dir##*/}
[ -z "$dir" ] && dir="/"

# Calculate human-readable token counts (in thousands)
used_raw=$((window_size * used_pct / 100))
used_display="$((used_raw / 1000))k"
left_raw=$((window_size * remaining_pct / 100))
left_display="$((left_raw / 1000))k"

# Get current git branch by walking up from the workspace dir.
# Reads .git/HEAD directly rather than spawning the full git runtime.
branch_segment=""
git_dir="$current_dir"
while [ -n "$git_dir" ] && [ "$git_dir" != "/" ]; do
    if [ -f "$git_dir/.git/HEAD" ]; then
        read -r ref < "$git_dir/.git/HEAD"
        branch_segment=" | 🌿 ${ref##*/}"
        break
    elif [ -f "$git_dir/.git" ]; then
        # Worktree or submodule: .git is a file containing "gitdir: <path>"
        read -r gitfile < "$git_dir/.git"
        real_git=${gitfile#gitdir: }
        if [ -f "$real_git/HEAD" ]; then
            read -r ref < "$real_git/HEAD"
            branch_segment=" | 🌿 ${ref##*/}"
        fi
        break
    fi
    git_dir=${git_dir%/*}
done

# Warn when context usage is high
warn=""
if [ "$used_pct" -ge 70 ]; then
    warn=" ⚠️ use compact"
fi

# Output the status line (yellow model name via ANSI escape)
printf "[\033[33m%s\033[0m] 📁 %s%s | 🧠 Context-used: %s%% (%s) | Context-left: %s%% (%s)%s\n" \
  "$model" \
  "$dir" \
  "$branch_segment" \
  "$used_pct" \
  "$used_display" \
  "$remaining_pct" \
  "$left_display" \
  "$warn"
