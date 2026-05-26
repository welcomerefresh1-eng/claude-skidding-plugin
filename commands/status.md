---
description: Check whether the Roblox executor gateway is connected to the bridge
---

Call the `get_status` tool from the `roblox-bridge` MCP server and report the result.

If `connected` is `true`, briefly confirm and show `lastSeenAt`.

If `connected` is `false`, tell the user to:
1. Open their Roblox executor.
2. Load `lua/gateway.lua` from this plugin and execute it inside the running game.
3. Run `/roblox-bridge:status` again to confirm.
