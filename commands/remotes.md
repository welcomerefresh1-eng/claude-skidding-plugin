---
description: List every RemoteEvent / RemoteFunction in the connected Roblox game
---

Call the `list_remotes` tool from `roblox-bridge` MCP.

Group the results by their parent folder (most games organize remotes into folders like `Remotes.Data`, `Remotes.Combat`, `Remotes.Moderator`). Within each folder, sort RemoteFunctions first (they return data — usually safer to probe) then RemoteEvents.

If there are more than ~50 results, summarize the top-level structure and ask which folder the user wants to drill into.
