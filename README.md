# claude-skidding-plugin

Claude Code plugin that hooks your AI up to your Roblox executor. You ask Claude to find, read, or fire stuff in a game — it does it for you. Comes with ~97 tools covering instance walking, decompiling, source grep, remote firing, GC scanning, drawing, input sim, crypto, file I/O, etc.

## What you need

- **Claude Code** installed (the AI CLI app)
- **Node.js** installed — https://nodejs.org → click the big green "LTS" button → next next next finish
- **A Roblox executor that's 100% sUNC compliant** (Volt, Potassium, or anything at that compliance level). Lower-tier executors are missing functions a lot of the tools need.

If your executor can't even run `request({...})`, get a better one before going further.

## Install (do this once)

### Step 1 — Add the marketplace

Open Claude Code. In the chat, paste this and hit enter:

```
/plugin marketplace add welcomerefresh1-eng/claude-skidding-plugin
```

Wait for it to say it added the marketplace.

### Step 2 — Install the plugin

Open **Manage Plugins** (in the UI). Switch to the **Plugins** tab. Find `roblox-bridge`. Click **Install**.

### Step 3 — Install the Node dependencies

The MCP server is Node.js — needs its deps installed once. Open a terminal (Win+R → `cmd` → enter) and run:

```
cd %USERPROFILE%\.claude\plugins\marketplaces\welcomerefresh1-eng_claude-skidding-plugin\roblox-bridge\mcp-server
npm install
```

If `npm install` errors with "npm is not recognized", you didn't install Node.js properly. Go back and do that first.

### Step 4 — Restart Claude Code

Fully close it and reopen. The MCP server only spawns on startup, so changes don't take effect until you restart.

### Step 5 — Verify

In Claude Code chat:

```
/roblox-bridge:status
```

You should see `connected: false` (we haven't run the gateway yet). If you get an error about no MCP server, the install didn't work — go back to Step 2 and check the plugin is enabled.

## How to use it (every session)

1. **Open Claude Code first.** It launches the MCP server in the background.
2. **Open Roblox, join a game.**
3. **In your executor, paste the contents of `lua/gateway.lua` and execute.**
   - File path on disk: `%USERPROFILE%\.claude\plugins\marketplaces\welcomerefresh1-eng_claude-skidding-plugin\roblox-bridge\lua\gateway.lua`
   - Or grab it from GitHub: https://github.com/welcomerefresh1-eng/claude-skidding-plugin/blob/main/lua/gateway.lua
4. **In your executor console** you should see:
   ```
   [Claude Gateway] 97 tools loaded
   [Claude Gateway] connecting to http://127.0.0.1:7474
   [Claude Gateway] connected, awaiting commands...
   ```
5. **Confirm in Claude Code** with `/roblox-bridge:status` — should say `connected: true` now.
6. **Ask Claude things.** Examples:
   - "find the kill / damage remote in this game and tell me what args it takes"
   - "decompile every script in ReplicatedStorage and find anything that touches DataStore"
   - "is there an anticheat? what does it check?"
   - "list every RemoteEvent and tell me which ones the client calls"
   - "fire the BuyItem remote with id 5"
   - "trace what happens when a player dies"
   - "find the shop module and explain how purchases work"

The Lua gateway dies on **teleport, rejoin, or leaving the game**. Just paste and execute it again.

## Slash commands

| Command | What it does |
|---|---|
| `/roblox-bridge:status` | Is the gateway connected? |
| `/roblox-bridge:explore <path>` | Inspect an instance (e.g. `game.Workspace.Lobby`) |
| `/roblox-bridge:find <pattern>` | Grep every script for a string |
| `/roblox-bridge:profile <player>` | Public stats of any player in the server |
| `/roblox-bridge:remotes` | List every remote in the game |

You can also just talk to Claude in plain English. It picks the right tool automatically.

## Subagent

There's a `roblox-explorer` agent built in. For open-ended digs ("figure out how the shop works", "find the admin commands", "is there an anticheat") just say:

```
use roblox-explorer to figure out how X works in this game
```

It'll do the full orient → grep → read → confirm flow on its own and report back.

## Common problems

**"No Roblox executor connected"**
Your gateway is dead. Re-run `gateway.lua` in your executor.

**`executor missing required function X`**
Your executor doesn't expose that function. The other 96 tools still work. Get a better executor if you need that one specific feature.

**Connection won't establish at all**
- Make sure Claude Code is running BEFORE you execute the gateway.
- Allow Node.js through Windows Firewall if it prompts.
- Test your executor's HTTP: paste `print(request({Url="http://127.0.0.1:7474/health", Method="GET"}).Body)` — should print `{"connected":...}`. If it errors, your executor's HTTP function is broken or your firewall is killing it.

**`/roblox-bridge:status` says `MCP server isn't loaded`**
Plugin isn't installed or wasn't picked up. Restart Claude Code. If still broken, go to Manage Plugins → toggle the plugin off and back on.

**Gateway keeps spamming "poll failed"**
Either Claude Code is closed (start it), or the broker port (7474) is taken by another process. Close any other instances.

## What this CAN'T do

- **Read other players' private data** (their inventory, stats, contracts). The server enforces privacy on every game. The only cross-player data exposed is whatever the game itself shows publicly.
- **Read ServerScriptService scripts.** Those live on the server only; the client never receives them. You can decompile every client script but server scripts are gone.
- **Bypass Byfron / Hyperion.** This plugin assumes you already have a working executor. It doesn't crack anything.
- **Anything your executor can't do.** It's a wrapper, not magic.

## How it works (if you care)

```
Claude Code  ⇄  MCP server (Node, on your PC)  ⇄  HTTP broker on 127.0.0.1:7474  ⇄  gateway.lua (in your executor)
```

When you ask Claude to do something, the MCP server queues a command. The gateway long-polls the broker, picks up the command, runs it with `loadstring`, sends the result back. Nothing leaves your machine.

## Updates

I push updates to GitHub. To pull them:

1. **Manage Plugins → Marketplaces tab → click the refresh icon** next to `welcomerefresh1-eng/claude-skidding-plugin`.
2. Restart Claude Code.

If the gateway changed too (you'll see a new `lua/gateway.lua`), re-paste it in your executor.

## License

Do whatever you want with it. Skid responsibly — don't attack people's stuff that isn't yours, don't grief people who didn't ask for it, don't sell this as your own work.
