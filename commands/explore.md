---
description: Inspect an Instance by dot-path in the connected Roblox game (path required)
argument-hint: "<dot.path> [max_depth]"
---

Call the `explore` tool from `roblox-bridge` MCP with the path the user provided in `$ARGUMENTS`.

If no path was given, ask the user for one (suggest examples like `game.Workspace`, `game.ReplicatedStorage`, `game.Players.LocalPlayer`).

If the path resolves, summarize: class, name, full path, key properties, child names with classes. Note any `truncated_children` count.

If the path returns "not found", remind the user that service names in some games have trailing whitespace (anti-tamper) — try the exact name from `search_instances` output instead.
