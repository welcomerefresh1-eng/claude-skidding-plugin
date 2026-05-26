---
description: Grep across all decompiled scripts in the connected Roblox game
argument-hint: "<pattern> [--lua-pattern] [--max-files N]"
---

Call the `find_in_source` tool from `roblox-bridge` MCP with the pattern from `$ARGUMENTS`.

Default to `literal=true` (substring match). If the user passed `--lua-pattern`, set `literal=false`. If they passed `--max-files N`, use that as `max_files` (otherwise default to 30 to keep it fast).

For each matching file, list the path and the first 3-5 hit lines with line numbers. Do not paste whole scripts.

If 0 matches, suggest broadening: try a shorter substring, the singular form, or `--lua-pattern` with a regex like `[Cc]ontract`.
