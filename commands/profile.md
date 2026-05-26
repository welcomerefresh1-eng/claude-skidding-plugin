---
description: Look up everything you can legally see about another player in the connected Roblox game
argument-hint: "<player-name>"
---

The user wants the public profile of the player named in `$ARGUMENTS`.

Use `execute_lua` with this code (substitute the name):

```lua
local Players = game:GetService("Players")
local target = Players:FindFirstChild("PLAYER_NAME_HERE")
if not target then return "no such player in this server" end

local out = { name = target.Name, displayName = target.DisplayName, userId = target.UserId }

local attrs = {}
for k, v in pairs(target:GetAttributes()) do attrs[k] = tostring(v) end
out.attributes = attrs

local cls = target:FindFirstChild("CustomLeaderstats")
if cls then
    local ls = {}
    for _, c in ipairs(cls:GetChildren()) do
        if c:IsA("ValueBase") then ls[c.Name] = c.Value end
    end
    out.leaderstats = ls
end

local RS = game:GetService("ReplicatedStorage")
local profileRem = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Misc") and RS.Remotes.Misc:FindFirstChild("RequestProfile")
if profileRem then
    local ok, res = pcall(function() return profileRem:InvokeServer(target) end)
    if ok then out.requestProfile = res end
end

return out
```

Then report: name, level, win counts, win streak, ELO if present, favorites. Note explicitly what is NOT visible: per-weapon contracts, per-map stats, daily-task progress (privacy boundary on most games).

If the game does not have a `Remotes.Misc.RequestProfile`, the script just returns attributes + leaderstats; report those.
