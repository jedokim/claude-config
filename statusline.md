Set up my Claude Code status line at the USER (personal) level, exactly matching my other Mac. Do not touch any project-level settings. Steps:

1. Create `~/.claude/statusline.sh` with EXACTLY the content below (byte-for-byte, including the emojis 📁 🌿 🧠 ⚠️ and the `\033[33m` ANSI escapes). If the file already exists, back it up to `~/.claude/statusline.sh.bak` first. Write it with a quoted heredoc (`<<'EOF'`) so nothing gets expanded. The original file has NO trailing newline after the final `"$warn"` line, but a heredoc adds one, so strip it afterwards: `printf '%s' "$(cat ~/.claude/statusline.sh)" > /tmp/sl && mv /tmp/sl ~/.claude/statusline.sh`. Then `chmod +x ~/.claude/statusline.sh`.

```bash
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

# Use parameter expansion instead of basename (avoids a fork)
dir=${current_dir##*/}

# Calculate human-readable token counts (in thousands)
used_raw=$((window_size * used_pct / 100))
used_display="$((used_raw / 1000))k"
left_raw=$((window_size * remaining_pct / 100))
left_display="$((left_raw / 1000))k"

# Get current git branch via .git/HEAD (avoids spawning full git runtime)
branch_segment=""
if [ -f .git/HEAD ]; then
    read -r ref < .git/HEAD
    branch=${ref##*/}
    branch_segment=" | 🌿 $branch"
fi

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
```

2. Verify the file is identical to the original: `shasum -a 256 ~/.claude/statusline.sh` must print
   `dbb8c940c8887d786494441c38a798a8572173f24f6c33370117c27a19168568`
   If it doesn't match, the prompt was probably mangled when I copied it over (e.g. an emoji or a line got altered). Don't try to "fix" the script by guessing. Stop, tell me the hash didn't match, and point out anything in the code block above that looks truncated or garbled.

3. Make sure `jq` is available (`which jq`). Recent macOS ships it at `/usr/bin/jq`; if it's missing, install it with `brew install jq`.

4. In `~/.claude/settings.json` (user-level), add or replace ONLY the `statusLine` key, preserving every other existing setting (create the file as `{}` first if it doesn't exist; back it up before editing):

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline.sh"
}
```

   Validate the result with `jq . ~/.claude/settings.json`.

5. Test it by running:
   `echo '{"model":{"display_name":"Opus 5.5"},"workspace":{"current_dir":"/Users/me/proj"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000}}' | bash ~/.claude/statusline.sh`
   Expected output (model name in yellow):
   `[Opus 5.5] 📁 proj | 🧠 Context-used: 12% (120k) | Context-left: 88% (880k)`

6. Tell me what you changed and the test output. The status line should show up right away; if not, I'll restart Claude Code.
