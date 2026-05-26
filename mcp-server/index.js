import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import http from "node:http";
import crypto from "node:crypto";

const PORT = Number(process.env.ROBLOX_BRIDGE_PORT ?? 7474);
const HOST = "127.0.0.1";
const POLL_TIMEOUT_MS = 2_000;
const RESULT_TIMEOUT_MS = 30_000;
const STALE_AFTER_MS = 10_000;

const TOOL_TIMEOUTS_MS = {
  decompile_all_in: 300_000,
  save_instance: 300_000,
  save_place: 600_000,
  find_in_source: 120_000,
  get_all_instances: 60_000,
  get_tree: 60_000,
  list_scripts: 60_000,
  gc_search: 60_000,
  filter_gc: 60_000,
};

const commandQueue = [];
const pendingResults = new Map();
const pollWaiters = [];
let lastSeenAt = 0;
let wasConnected = false;

function isConnected() {
  return lastSeenAt > 0 && Date.now() - lastSeenAt < STALE_AFTER_MS;
}

function drainOnDisconnect() {
  const reason = "Executor gateway disconnected mid-call";
  for (const [id, pending] of pendingResults) {
    clearTimeout(pending.timeout);
    pending.reject(new Error(reason));
  }
  pendingResults.clear();
  commandQueue.length = 0;
}

setInterval(() => {
  const live = isConnected();
  if (wasConnected && !live) {
    drainOnDisconnect();
    console.error("[roblox-bridge] gateway disconnected — drained queue and pending results");
  } else if (!wasConnected && live) {
    console.error("[roblox-bridge] gateway connected");
  }
  wasConnected = live;
}, 1000);

function deliverTo(waiter, cmd) {
  clearTimeout(waiter.timeout);
  waiter.res.writeHead(200, { "Content-Type": "application/json" });
  waiter.res.end(JSON.stringify(cmd));
}

function enqueueCommand(method, params) {
  return new Promise((resolve, reject) => {
    const id = crypto.randomUUID();
    const cmd = { id, method, params: params || {} };
    const timeoutMs = TOOL_TIMEOUTS_MS[method] ?? RESULT_TIMEOUT_MS;
    const timeout = setTimeout(() => {
      if (pendingResults.has(id)) {
        pendingResults.delete(id);
        reject(new Error(`Executor did not respond within ${timeoutMs / 1000}s. Is gateway.lua running?`));
      }
    }, timeoutMs);
    pendingResults.set(id, { resolve, reject, timeout });

    const waiter = pollWaiters.shift();
    if (waiter) {
      deliverTo(waiter, cmd);
    } else {
      commandQueue.push(cmd);
    }
  });
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (c) => {
      body += c;
      if (body.length > 50_000_000) {
        req.destroy();
        reject(new Error("payload too large"));
      }
    });
    req.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on("error", reject);
  });
}

const httpServer = http.createServer(async (req, res) => {
  try {
    if (req.method === "POST" && req.url === "/poll") {
      lastSeenAt = Date.now();
      const cmd = commandQueue.shift();
      if (cmd) {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(cmd));
        return;
      }
      const waiter = { res, timeout: null };
      waiter.timeout = setTimeout(() => {
        const idx = pollWaiters.indexOf(waiter);
        if (idx !== -1) pollWaiters.splice(idx, 1);
        res.writeHead(204);
        res.end();
      }, POLL_TIMEOUT_MS);
      pollWaiters.push(waiter);
      req.on("close", () => {
        clearTimeout(waiter.timeout);
        const idx = pollWaiters.indexOf(waiter);
        if (idx !== -1) pollWaiters.splice(idx, 1);
      });
      return;
    }

    if (req.method === "POST" && req.url === "/result") {
      lastSeenAt = Date.now();
      const body = await readJsonBody(req);
      const pending = pendingResults.get(body.id);
      if (pending) {
        pendingResults.delete(body.id);
        clearTimeout(pending.timeout);
        if (body.ok) pending.resolve(body.result ?? "");
        else pending.reject(new Error(body.error ?? "unknown executor error"));
      }
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.method === "GET" && req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ connected: isConnected(), lastSeenAt }));
      return;
    }

    res.writeHead(404);
    res.end();
  } catch (err) {
    res.writeHead(500, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: String(err?.message ?? err) }));
  }
});

httpServer.listen(PORT, HOST, () => {
  console.error(`[roblox-bridge] broker listening on http://${HOST}:${PORT}`);
});

const INSTRUCTIONS = `
You have direct access to a live Roblox game through the Potassium executor via this plugin's gateway. ~100 tools let you walk the DataModel, decompile every client script, grep their source, fire remotes, hook signals, capture network traffic, and run arbitrary Luau.

# Workflow (cheap → expensive)

1. Orient: get_status, get_player, list_players, get_tree path="game" max_depth=2.
2. Locate: search_instances (by name/class), list_scripts, list_remotes.
3. Read: get_source on specific scripts, get_tree on a subtree.
4. Grep: find_in_source — ALWAYS pass \`scope\` to limit it to a subtree (e.g. "ReplicatedStorage .Modules"). Without scope it walks Roblox CorePackages which is huge and slow.
5. Deep dive: get_script_closure, get_script_env, get_callback, inspect_function, gc_search / filter_gc when source is obfuscated.
6. Confirm at runtime: start_remote_log → user triggers the action in-game → get_remote_log to see exactly what fired and with what args.

# Efficiency

- find_in_source with \`scope\` is the #1 perf win. The non-scoped version frequently times out on commercial games.
- Prefer search_instances over get_all_instances (which can return many MB).
- get_tree max_depth=2 before max_depth=5.
- Use named tools over execute_lua — they're typed, structured, and cheaper on tokens. Only fall back to execute_lua when no dedicated tool fits, and always \`return\` the value you want back.
- Grep before read: find_in_source returns line-level hits; get_source returns the whole file. Use both in order.

# Roblox / Potassium gotchas

- Many games obfuscate service names with TRAILING SPACES — "ReplicatedStorage ", "Players ", "Workspace ". Use exact paths from search_instances output; do not strip the whitespace. Inside execute_lua, prefer game:GetService("X") over dot-paths.
- ServerScriptService scripts are NOT present on the client. You can decompile every client script but server-only code is unreachable from any executor.
- Cross-player privacy: most games only expose Level / wins / favorites of OTHER players (via RequestProfile-style remotes) plus a few replicated attributes / leaderstats. Per-statistic, per-inventory, per-contract data of OTHER players is almost always server-locked behind moderator perms — manage user expectations accordingly.

# Safety

- Do NOT fire remotes with destructive side effects (purchases, kicks, bans, account-affecting actions, item burning, etc.) without explicit user confirmation.
- raknet_send and raknet_start_log are ban-risk per Potassium's own docs AND require the UI toggle to actually do anything.
- set_property / set_scriptable / fire_signal / replicate_signal can desync state or trigger anti-cheat. Flag side effects before invoking.

# When to delegate

For multi-step investigations ("how does the shop work", "find the anti-cheat", "trace what happens on death", "find every script that touches DataStore"), delegate to the \`roblox-explorer\` subagent — it has a more thorough playbook loaded and keeps the main thread's context clean.
`.trim();

const server = new McpServer(
  { name: "roblox-bridge", version: "0.1.0" },
  { instructions: INSTRUCTIONS }
);

function formatResult(result) {
  if (typeof result === "string") return { content: [{ type: "text", text: result }] };
  return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
}

function tool(name, description, schema) {
  server.tool(name, description, schema ?? {}, async (params) => {
    if (!isConnected()) {
      return {
        isError: true,
        content: [{ type: "text", text: "No Roblox executor connected. Run lua/gateway.lua in your executor." }],
      };
    }
    try {
      const result = await enqueueCommand(name, params ?? {});
      return formatResult(result);
    } catch (err) {
      return { isError: true, content: [{ type: "text", text: String(err?.message ?? err) }] };
    }
  });
}

server.tool(
  "get_status",
  "Report whether the Roblox executor gateway is currently connected to the bridge.",
  {},
  async () => ({
    content: [{
      type: "text",
      text: JSON.stringify({
        connected: isConnected(),
        lastSeenAt: lastSeenAt ? new Date(lastSeenAt).toISOString() : null,
        queuedCommands: commandQueue.length,
        pendingResults: pendingResults.size,
      }, null, 2),
    }],
  })
);

const vec3 = z.object({ x: z.number(), y: z.number(), z: z.number() });
const anyArr = z.array(z.any());
const anyObj = z.record(z.any());

tool("execute_lua",
  "Execute arbitrary Luau in the running Roblox client. Use `return <expr>` to get a value back. Universal escape hatch. Optional `identity` raises thread identity (1-8) before running.",
  { code: z.string().describe("Luau source. Ex: `return #workspace:GetChildren()`"),
    identity: z.number().int().optional().describe("Optional thread identity 1-8") });

tool("explore",
  "Inspect an Instance at a dot-path. Returns class, common properties, and child names. Ex: 'game.Workspace.Baseplate'.",
  { path: z.string().describe("Dot-path") });

tool("get_tree",
  "Recursive tree of an Instance and its descendants (class + name). Truncates at max_depth.",
  { path: z.string().optional().describe("Defaults to game.Workspace"),
    max_depth: z.number().int().optional().describe("Default 3") });

tool("search_instances",
  "Find Instances by name substring and/or class. Useful when you don't know the path.",
  { query: z.string().optional().describe("Case-insensitive name substring"),
    class: z.string().optional().describe("Class filter, e.g. 'RemoteEvent'"),
    max_results: z.number().int().optional().describe("Default 100") });

tool("get_nil_instances",
  "List all Instances whose Parent is nil (often hidden GUIs, queued objects). Requires getnilinstances.",
  {});

tool("get_all_instances",
  "Every Instance in the game, optionally filtered by class. Capped by max_results to avoid floods.",
  { class: z.string().optional().describe("Optional class filter"),
    max_results: z.number().int().optional().describe("Default 5000") });

tool("get_hui",
  "Return the hidden UI container (gethui) and its top-level children.",
  {});

tool("get_property",
  "Read a single property from an Instance. Falls back to gethiddenproperty if available.",
  { path: z.string(), name: z.string() });

tool("set_property",
  "Write a single property. Falls back to sethiddenproperty if needed.",
  { path: z.string(), name: z.string(), value: z.any().describe("New value") });

tool("get_all_properties",
  "Dump every visible + hidden property of an Instance via getproperties.",
  { path: z.string() });

tool("get_hidden_properties",
  "Dump only the hidden (non-scriptable) properties of an Instance via gethiddenproperties.",
  { path: z.string() });

tool("is_scriptable",
  "Check whether a property is normally accessible via scripting.",
  { path: z.string(), name: z.string() });

tool("set_scriptable",
  "Toggle a property's scriptability (so you can read/write hidden ones normally).",
  { path: z.string(), name: z.string(), scriptable: z.boolean() });

tool("get_source",
  "Decompile a LocalScript / ModuleScript / Script at the given path.",
  { path: z.string() });

tool("get_bytecode",
  "Get raw bytecode info for a script (size + hex sample). Uses getscriptbytecode.",
  { path: z.string() });

tool("get_script_hash",
  "Hash of a script's compiled bytecode. Stable across identical sources.",
  { path: z.string() });

tool("get_script_env",
  "Return key→type map of a script's _ENV via getsenv.",
  { path: z.string() });

tool("get_script_closure",
  "Reconstruct the script's main closure and dump its constants/upvalues/proto count.",
  { path: z.string() });

tool("list_scripts",
  "List every LocalScript, ModuleScript, and Script in the place.",
  {});

tool("find_in_source",
  "Grep across decompiled scripts. Returns per-file line hits. Pass `scope` to limit the search to a subtree (huge speedup on games with Roblox CorePackages). Pass `context` for N before+after lines.",
  { pattern: z.string().describe("Substring (default) or Lua pattern"),
    literal: z.boolean().optional().describe("If false, pattern is a Lua pattern. Default true."),
    max_files: z.number().int().optional().describe("Default 50"),
    scope: z.string().optional().describe("Dot-path root to limit the search (e.g. 'ReplicatedStorage .Modules'). Default: whole game."),
    context: z.number().int().optional().describe("Lines of context before/after each hit. Default 0.") });

tool("decompile_all_in",
  "Bulk decompile every script under a subtree. Capped by max_files.",
  { path: z.string().optional().describe("Root. Defaults to game"),
    max_files: z.number().int().optional().describe("Default 25") });

tool("find_remote_callers",
  "Find every script that mentions a remote name. Each hit flags whether it looks like a caller (.FireServer / .InvokeServer / .OnClientEvent / .OnClientInvoke).",
  { name: z.string().describe("Remote name, e.g. 'BuyItem'"),
    scope: z.string().optional().describe("Dot-path root to limit search"),
    max_files: z.number().int().optional().describe("Default 50") });

tool("list_remotes",
  "List every RemoteEvent / RemoteFunction / UnreliableRemoteEvent / BindableEvent / BindableFunction.",
  {});

tool("fire_remote",
  "FireServer on a RemoteEvent with the given args array.",
  { path: z.string(), args: anyArr.optional().describe("Positional arguments") });

tool("invoke_remote",
  "InvokeServer on a RemoteFunction with the given args array. Returns the server's reply.",
  { path: z.string(), args: anyArr.optional().describe("Positional arguments") });

tool("start_remote_log",
  "Begin logging all outbound FireServer / InvokeServer calls via a namecall hook. Pair with get_remote_log.",
  { cap: z.number().int().optional().describe("Max retained entries (default 1000)") });

tool("stop_remote_log",
  "Stop logging (the hook stays installed but goes idle).",
  {});

tool("get_remote_log",
  "Return logged remote calls. Pass since_index to only get new entries.",
  { since_index: z.number().int().optional().describe("Return entries after this index. Default 0.") });

tool("clear_remote_log",
  "Drop the in-memory remote log.",
  {});

tool("raknet_status",
  "Report whether Potassium's RakNet API is exposed and whether packet logging is currently active. Note: even if `available` is true, you must enable RakNet in Potassium's UI settings for hooks/sends to actually do anything.",
  {});

tool("raknet_start_log",
  "Start logging every outbound RakNet packet via a send-hook. Pair with raknet_get_log. Ban risk per Potassium docs.",
  { cap: z.number().int().optional().describe("Max retained entries (default 1000)") });

tool("raknet_stop_log",
  "Stop the RakNet send-hook logger.",
  {});

tool("raknet_get_log",
  "Return logged RakNet packets. Pass since_index to only get new entries.",
  { since_index: z.number().int().optional().describe("Return entries after this index. Default 0.") });

tool("raknet_clear_log",
  "Drop the in-memory RakNet packet log.",
  {});

tool("raknet_send",
  "Send a raw RakNet packet. Ban risk per Potassium docs. Requires RakNet enabled in Potassium UI settings.",
  { data: z.string().describe("Packet bytes (raw string, or base64 if base64=true)"),
    base64: z.boolean().optional().describe("Set true if `data` is base64-encoded"),
    priority: z.number().int().optional().describe("Default 1"),
    reliability: z.number().int().optional().describe("Default 0"),
    ordering_channel: z.number().int().optional().describe("Default 0") });

tool("get_signal_connections",
  "List handlers attached to an RBXScriptSignal. Format: 'path::SignalName' (e.g. 'game.ReplicatedStorage.RemoteEvent::OnClientEvent').",
  { signal: z.string().describe("'path::SignalName'") });

tool("fire_signal",
  "Fire all local handlers of a signal (no replication). Format: 'path::SignalName'.",
  { signal: z.string(), args: anyArr.optional().describe("Args passed to handlers") });

tool("replicate_signal",
  "Fire a signal in a way that replicates to the server (unlike fire_signal). Subject to the signal whitelist.",
  { signal: z.string(), args: anyArr.optional() });

tool("get_callback",
  "Inspect a callback property (e.g. RemoteFunction.OnClientInvoke). Dumps source location + upvalues.",
  { path: z.string(), name: z.string().describe("e.g. 'OnClientInvoke'") });

tool("fire_proximity_prompt",
  "Trigger a ProximityPrompt without holding / standing near it.",
  { path: z.string() });

tool("fire_click_detector",
  "Trigger a ClickDetector. Events: 'MouseClick' (default), 'RightMouseClick', 'MouseHoverEnter', 'MouseHoverLeave'.",
  { path: z.string(),
    distance: z.number().optional().describe("Default 0"),
    event: z.string().optional() });

tool("fire_touch_interest",
  "Simulate a touch between two BaseParts. toggle: 1 = Touched, 0 = TouchEnded.",
  { part: z.string(), target: z.string(), toggle: z.number().int().describe("0 or 1") });

tool("get_loaded_modules",
  "List ModuleScripts that have been require()'d (via getloadedmodules).",
  {});

tool("get_running_scripts",
  "List currently-running scripts (via getrunningscripts).",
  {});

tool("gc_search",
  "Walk Luau's GC for tables/functions. Coarse — prefer filter_gc when you have specific criteria.",
  { kind: z.string().optional().describe("'function' | 'table' | 'all' (default)"),
    query: z.string().optional().describe("Substring filter"),
    max_results: z.number().int().optional().describe("Default 50"),
    include_non_objects: z.boolean().optional().describe("getgc(true). Default false.") });

tool("filter_gc",
  "Volt's targeted GC search. Functions: filter by Name/Constants/Upvalues. Tables: by Keys/Values/KeyValuePairs/Metatable.",
  { kind: z.string().optional().describe("'function' (default) or 'table'"),
    options: anyObj.optional(),
    max_results: z.number().int().optional().describe("Default 50") });

tool("get_globals",
  "Dump keys + types of a global table.",
  { kind: z.string().optional().describe("'_G' (default) | 'shared' | 'genv' | 'renv' | 'fenv' | 'reg'") });

tool("inspect_function",
  "Given a Lua expression that returns a function, dump debug info: source, line, upvalues, constants, proto count, hash.",
  { code: z.string().describe("Ex: 'return game.HttpService.GetAsync'") });

tool("get_thread_identity",
  "Current thread identity (1-8). Higher identity = more privileges.",
  {});

tool("set_thread_identity",
  "Set thread identity (1-8) — useful for bypassing CoreScript / hidden-property restrictions.",
  { identity: z.number().int().describe("1-8") });

tool("get_metatable",
  "Raw metatable of any value. Provide a Luau expression that returns the object.",
  { code: z.string().describe("Ex: 'return game'") });

tool("list_players",
  "All players currently in the server.",
  {});

tool("get_player",
  "Info on a player (name, userId, team, character path, position). Defaults to LocalPlayer.",
  { name: z.string().optional().describe("Player name. Omit for LocalPlayer.") });

tool("teleport",
  "Move the LocalPlayer's HumanoidRootPart to the given position.",
  { position: vec3 });

tool("read_file",
  "Read a file from the executor's workspace folder.",
  { path: z.string() });

tool("write_file",
  "Write a file to the executor's workspace folder (overwrites).",
  { path: z.string(), content: z.string() });

tool("append_file",
  "Append data to a file in the executor's workspace.",
  { path: z.string(), content: z.string() });

tool("delete_file",
  "Delete a file from the executor's workspace (irreversible).",
  { path: z.string() });

tool("list_files",
  "List files in a folder of the executor's workspace.",
  { folder: z.string().optional().describe("Default: workspace root") });

tool("make_folder",
  "Create a folder in the executor's workspace.",
  { path: z.string() });

tool("delete_folder",
  "Delete a folder and all its contents (irreversible).",
  { path: z.string() });

tool("save_instance",
  "Save an Instance to an RBXM/RBXL via Potassium's saveinstance. Omit `path` to save the whole game.",
  { path: z.string().optional().describe("Root instance to save (omit for whole game)"),
    file_name: z.string().optional().describe("Output filename"),
    decompile: z.boolean().optional().describe("Decompile scripts during save"),
    nil_instances: z.boolean().optional().describe("Include instances parented to nil"),
    remove_player_chars: z.boolean().optional().describe("Skip player characters"),
    save_players: z.boolean().optional().describe("Include player Instances"),
    decompile_timeout: z.number().int().optional().describe("Decompile per-script timeout in seconds (default 10)"),
    max_threads: z.number().int().optional().describe("Decompile threads (default 3)"),
    decompile_ignore: z.array(z.string()).optional().describe("Services to skip when decompiling"),
    show_status: z.boolean().optional(),
    ignore_default_props: z.boolean().optional(),
    isolate_starter_player: z.boolean().optional() });

tool("crypt_hash",
  "Hash data. Algorithms: MD5, SHA1, SHA256 (default), SHA384, SHA512.",
  { data: z.string(), algorithm: z.string().optional() });

tool("crypt_hmac",
  "HMAC of data with key. Same algorithms as crypt_hash.",
  { key: z.string(), data: z.string(), algorithm: z.string().optional() });

tool("crypt_generatekey",
  "Generate a random base64-encoded key. Pair with crypt_encrypt.",
  { length: z.number().int().optional().describe("Key length in bytes (default 32)") });

tool("crypt_encrypt",
  "Encrypt data. Algorithms: AES-CBC (default), AES-GCM, AES-CTR.",
  { data: z.string(), key: z.string(), iv: z.string().optional(), algorithm: z.string().optional() });

tool("crypt_decrypt",
  "Decrypt data produced by crypt_encrypt.",
  { data: z.string(), key: z.string(), iv: z.string().optional(), algorithm: z.string().optional() });

tool("crypt_random",
  "Cryptographically secure random bytes, returned base64-encoded.",
  { length: z.number().int().optional().describe("Default 32") });

tool("base64_encode",
  "Base64-encode a string.",
  { data: z.string() });

tool("base64_decode",
  "Base64-decode a string.",
  { data: z.string() });

tool("lz4_compress",
  "LZ4-compress a string. Returns size + base64-encoded compressed data.",
  { data: z.string() });

tool("lz4_decompress",
  "LZ4-decompress. Set base64=true if data is base64-encoded.",
  { data: z.string(), size: z.number().int().describe("Original uncompressed size"), base64: z.boolean().optional() });

tool("http_request",
  "Make an outbound HTTP request via Potassium's `request`.",
  { url: z.string(), method: z.string().optional().describe("Default GET"), headers: anyObj.optional(), body: z.string().optional(), cookies: anyObj.optional() });

tool("http_get",
  "Simpler outbound HTTP GET via Potassium's `httpget`. Returns body as string.",
  { url: z.string() });

tool("is_window_active",
  "Is the Roblox window currently focused?",
  {});

tool("key_click",
  "Press+release a key. Windows virtual key code (e.g. 0x20 = Space, 0x41 = A).",
  { keycode: z.number().int() });

tool("key_press",
  "Press a key down (without releasing).",
  { keycode: z.number().int() });

tool("key_release",
  "Release a key.",
  { keycode: z.number().int() });

tool("mouse_click",
  "Click a mouse button. 'left' (default) or 'right'.",
  { button: z.string().optional() });

tool("mouse_move",
  "Move the mouse cursor. relative=true uses delta; otherwise absolute screen coords.",
  { x: z.number(), y: z.number(), relative: z.boolean().optional() });

tool("mouse_scroll",
  "Scroll wheel. Positive = up, negative = down.",
  { delta: z.number().int() });

tool("console_show",
  "Open the executor's separate console window.",
  {});

tool("console_hide",
  "Close the executor's console window.",
  {});

tool("console_print",
  "Write to the executor's console. level: 'info' | 'warn' | 'error' (omit for plain print).",
  { text: z.string(), level: z.string().optional() });

tool("console_clear",
  "Clear the executor's console.",
  {});

tool("console_title",
  "Set the console window title.",
  { title: z.string() });

tool("identify_executor",
  "Return the executor's name + version.",
  {});

tool("get_hwid",
  "Get the machine's hardware ID.",
  {});

tool("get_fps_cap",
  "Current FPS cap.",
  {});

tool("set_fps_cap",
  "Set FPS cap (0 = uncapped).",
  { fps: z.number().int() });

tool("set_clipboard",
  "Copy text to the system clipboard.",
  { text: z.string() });

tool("get_fflag",
  "Read a Roblox Fast Flag.",
  { name: z.string() });

tool("set_fflag",
  "Write a Roblox Fast Flag (string value).",
  { name: z.string(), value: z.string() });

tool("message_box",
  "Show a Windows MessageBox. Flags: 0 OK, 1 OK+Cancel, 4 Yes+No, 16 Error, 32 Question, 48 Warning, 64 Info.",
  { text: z.string(), caption: z.string().optional(), flags: z.number().int().optional() });

tool("queue_on_teleport",
  "Queue Luau code to run on the next teleport.",
  { code: z.string() });

tool("clear_teleport_queue",
  "Clear any code queued via queue_on_teleport.",
  {});

tool("draw_create",
  "Create a Drawing overlay. Types: Line, Circle, Square, Triangle, Text, Image, Quad. Returns an id used by draw_set / draw_remove.",
  { type: z.string().describe("Line/Circle/Square/Triangle/Text/Image/Quad"), properties: anyObj.optional() });

tool("draw_set",
  "Mutate a Drawing's properties.",
  { id: z.number().int(), properties: anyObj });

tool("draw_remove",
  "Remove a single Drawing by id.",
  { id: z.number().int() });

tool("draw_clear",
  "Remove every Drawing currently on screen.",
  {});

tool("get_bsp_val",
  "Read a BinaryString property (e.g. Terrain.SmoothGrid, BinaryStringValue.Value, PartOperation.PhysicsData). Set base64=true if you want the value base64-encoded.",
  { path: z.string(), name: z.string(), base64: z.boolean().optional() });

tool("get_proximity_prompt_duration",
  "Return a ProximityPrompt's HoldDuration via Potassium's getproximitypromptduration.",
  { path: z.string() });

tool("set_proximity_prompt_duration",
  "Set a ProximityPrompt's HoldDuration via Potassium's setproximitypromptduration.",
  { path: z.string(), duration: z.number() });

tool("get_simulation_radius",
  "Return the LocalPlayer's network simulation radius.",
  {});

tool("set_simulation_radius",
  "Set the LocalPlayer's network simulation radius.",
  { radius: z.number() });

tool("is_network_owner",
  "Is the LocalPlayer the network owner of the given instance?",
  { path: z.string() });

tool("get_signal_whitelist",
  "Return Roblox's signal replication whitelist — list of {Parent, Event} entries that replicatesignal accepts.",
  {});

tool("get_custom_asset",
  "Turn a file in the executor workspace into an `rbxasset://` content id (for Sound.SoundId, ImageLabel.Image, etc.).",
  { path: z.string().describe("Relative path under workspace, e.g. 'sounds/mysound.mp3'") });

tool("get_objects",
  "Fetch a Roblox asset by rbxassetid:// URL and return its top-level instances.",
  { asset: z.string().describe("e.g. 'rbxassetid://1818'") });

await server.connect(new StdioServerTransport());
