do
    if type(identifyexecutor) ~= "function" then
        error("[Claude Gateway] identifyexecutor is missing. This gateway requires the Potassium executor.")
    end
    local name, version = identifyexecutor()
    if name ~= "Potassium" then
        error(string.format(
            "[Claude Gateway] This gateway only runs on the Potassium executor. Detected: %s (%s).",
            tostring(name), tostring(version)
        ))
    end
    print(string.format("[Claude Gateway] Potassium %s detected", tostring(version)))
end

local HOST = "http://127.0.0.1:7474"

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

local lua_load = loadstring

local function jenc(t) return HttpService:JSONEncode(t) end
local function jdec(s) return HttpService:JSONDecode(s) end

local function serialize(v, depth)
    depth = depth or 0
    if depth > 6 then return "<max depth>" end
    local t = typeof(v)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return v
    elseif t == "Instance" then
        return { __type = "Instance", class = v.ClassName, path = v:GetFullName() }
    elseif t == "Vector3" then
        return { __type = "Vector3", x = v.X, y = v.Y, z = v.Z }
    elseif t == "Vector2" then
        return { __type = "Vector2", x = v.X, y = v.Y }
    elseif t == "CFrame" then
        return { __type = "CFrame", components = { v:GetComponents() } }
    elseif t == "Color3" then
        return { __type = "Color3", r = v.R, g = v.G, b = v.B }
    elseif t == "UDim2" then
        return {
            __type = "UDim2",
            x = { scale = v.X.Scale, offset = v.X.Offset },
            y = { scale = v.Y.Scale, offset = v.Y.Offset },
        }
    elseif t == "EnumItem" then
        return { __type = "EnumItem", name = tostring(v) }
    elseif t == "buffer" then
        local ok, len = pcall(buffer.len, v)
        return { __type = "buffer", size = ok and len or "?" }
    elseif t == "table" then
        local out = {}
        for k, val in pairs(v) do out[tostring(k)] = serialize(val, depth + 1) end
        return out
    else
        return { __type = t, value = tostring(v) }
    end
end

local function resolvePath(path)
    if path == nil or path == "" or path == "game" then return game end
    local segments = {}
    for seg in tostring(path):gmatch("[^.]+") do segments[#segments + 1] = seg end
    local current = game
    local startIdx = 1
    if segments[1] == "game" then startIdx = 2 end
    for i = startIdx, #segments do
        local seg = segments[i]
        local nxt = current:FindFirstChild(seg)
        if not nxt then
            return nil, "not found: " .. table.concat(segments, ".", 1, i)
        end
        current = nxt
    end
    return current
end

local COMMON = { "Name", "ClassName", "Archivable" }
local BY_CLASS = {
    BasePart    = { "Position", "Size", "Rotation", "Anchored", "CanCollide", "Material", "Transparency", "Color", "Orientation" },
    Humanoid    = { "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight", "RigType" },
    Player      = { "UserId", "DisplayName", "Team" },
    Script      = { "Disabled", "RunContext" },
    LocalScript = { "Disabled" },
    Camera      = { "CFrame", "FieldOfView", "CameraType" },
    Tool        = { "Grip", "RequiresHandle", "Enabled" },
    Sound       = { "SoundId", "Volume", "Playing", "Looped" },
    GuiObject   = { "Position", "Size", "Visible", "ZIndex", "BackgroundColor3", "BackgroundTransparency" },
    TextLabel   = { "Text", "TextColor3", "TextSize", "Font" },
}

local function collectProperties(inst)
    local props, seen = {}, {}
    local function tryProp(p)
        if seen[p] then return end
        seen[p] = true
        local ok, val = pcall(function() return inst[p] end)
        if ok then props[p] = serialize(val) end
    end
    for _, p in ipairs(COMMON) do tryProp(p) end
    for class, list in pairs(BY_CLASS) do
        if inst:IsA(class) then
            for _, p in ipairs(list) do tryProp(p) end
        end
    end
    return props
end

local state = {
    remote_log = {},
    remote_log_enabled = false,
    remote_log_cap = 1000,
    namecall_installed = false,
    old_namecall = nil,
    drawings = {},
    next_draw_id = 1,
}

local function installNamecallHook()
    if state.namecall_installed then return true end
    state.namecall_installed = true
    state.old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = { ... }
        if state.remote_log_enabled then
            local ok, method = pcall(getnamecallmethod)
            if ok and (method == "FireServer" or method == "InvokeServer") then
                local ok2, isRemote = pcall(function()
                    return self:IsA("RemoteEvent")
                        or self:IsA("RemoteFunction")
                        or self:IsA("UnreliableRemoteEvent")
                end)
                if ok2 and isRemote then
                    table.insert(state.remote_log, {
                        time   = tick(),
                        path   = self:GetFullName(),
                        method = method,
                        args   = serialize(args),
                    })
                    if #state.remote_log > state.remote_log_cap then
                        table.remove(state.remote_log, 1)
                    end
                end
            end
        end
        return state.old_namecall(self, ...)
    end)
    return true
end

local tools = {}

function tools.execute_lua(params)
    local code = params.code
    if type(code) ~= "string" then return nil, "code must be a string" end
    local fn, err = lua_load(code, "execute_lua")
    if not fn then return nil, "compile error: " .. tostring(err) end
    if params.identity ~= nil then
        pcall(setthreadidentity, params.identity)
    end
    local ok, result = xpcall(fn, function(e)
        return tostring(e) .. "\n" .. debug.traceback("", 2)
    end)
    if not ok then return nil, "runtime error: " .. tostring(result) end
    return serialize(result)
end
tools.exec_lua = tools.execute_lua

function tools.explore(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local children = {}
    for _, c in ipairs(inst:GetChildren()) do
        children[#children + 1] = { name = c.Name, class = c.ClassName }
    end
    return {
        class = inst.ClassName,
        name = inst.Name,
        path = inst:GetFullName(),
        properties = collectProperties(inst),
        children = children,
    }
end

function tools.get_tree(params)
    local root = params.path and select(1, resolvePath(params.path)) or workspace
    if not root then return nil, "root not found" end
    local maxDepth = params.max_depth or 3
    local function build(inst, depth)
        local node = { name = inst.Name, class = inst.ClassName }
        local children = inst:GetChildren()
        if depth < maxDepth and #children > 0 then
            node.children = {}
            for _, c in ipairs(children) do
                node.children[#node.children + 1] = build(c, depth + 1)
            end
        elseif #children > 0 then
            node.truncated_children = #children
        end
        return node
    end
    return build(root, 0)
end

function tools.search_instances(params)
    local query = params.query and params.query:lower() or nil
    local class = params.class
    local maxResults = params.max_results or 100
    local matches = {}
    for _, d in ipairs(game:GetDescendants()) do
        local nameOk = not query or d.Name:lower():find(query, 1, true) ~= nil
        local classOk = not class or d:IsA(class)
        if nameOk and classOk then
            matches[#matches + 1] = { path = d:GetFullName(), class = d.ClassName, name = d.Name }
            if #matches >= maxResults then break end
        end
    end
    return matches
end

function tools.get_nil_instances(_)
    local out = {}
    for _, inst in ipairs(getnilinstances()) do
        out[#out + 1] = { class = inst.ClassName, name = inst.Name, path = inst:GetFullName() }
    end
    return out
end

function tools.get_all_instances(params)
    local maxResults = params.max_results or 5000
    local class = params.class
    local out, count = {}, 0
    for _, inst in ipairs(getinstances()) do
        if not class or inst:IsA(class) then
            count = count + 1
            if count <= maxResults then
                out[#out + 1] = { class = inst.ClassName, path = inst:GetFullName() }
            end
        end
    end
    return { instances = out, total = count, truncated = count > maxResults }
end

function tools.get_hui(_)
    local hui = gethui()
    local children = {}
    for _, c in ipairs(hui:GetChildren()) do
        children[#children + 1] = { name = c.Name, class = c.ClassName }
    end
    return { path = hui:GetFullName(), class = hui.ClassName, children = children }
end

function tools.get_property(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, res = pcall(function() return inst[params.name] end)
    if ok then return serialize(res) end
    local ok2, hidden, isHidden = pcall(gethiddenproperty, inst, params.name)
    if ok2 then return { value = serialize(hidden), hidden = isHidden, via = "gethiddenproperty" } end
    return nil, "read failed: " .. tostring(res)
end

function tools.set_property(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, res = pcall(function() inst[params.name] = params.value end)
    if ok then return { status = "set" } end
    local ok2, isHidden = pcall(sethiddenproperty, inst, params.name, params.value)
    if ok2 then return { status = "set via sethiddenproperty", hidden = isHidden } end
    return nil, "set failed: " .. tostring(res)
end

function tools.get_all_properties(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, props = pcall(getproperties, inst)
    if not ok then return nil, tostring(props) end
    return serialize(props)
end

function tools.get_hidden_properties(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, props = pcall(gethiddenproperties, inst)
    if not ok then return nil, tostring(props) end
    return serialize(props)
end

function tools.is_scriptable(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    return { scriptable = isscriptable(inst, params.name) }
end

function tools.set_scriptable(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    setscriptable(inst, params.name, params.scriptable == true)
    return { current = params.scriptable == true }
end

function tools.get_bsp_val(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, res = pcall(getbspval, inst, params.name, params.base64 == true)
    if not ok then return nil, tostring(res) end
    return { value = res, base64 = params.base64 == true }
end

function tools.get_proximity_prompt_duration(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ProximityPrompt") then return nil, "not a ProximityPrompt" end
    return { duration = getproximitypromptduration(inst) }
end

function tools.set_proximity_prompt_duration(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ProximityPrompt") then return nil, "not a ProximityPrompt" end
    setproximitypromptduration(inst, params.duration)
    return { duration = params.duration }
end

function tools.get_simulation_radius(_)
    return { radius = getsimulationradius() }
end

function tools.set_simulation_radius(params)
    setsimulationradius(params.radius)
    return { radius = params.radius }
end

function tools.is_network_owner(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    return { owner = isnetworkowner(inst) }
end

function tools.get_source(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not (inst:IsA("LocalScript") or inst:IsA("ModuleScript") or inst:IsA("Script")) then
        return nil, "not a script (got " .. inst.ClassName .. ")"
    end
    local ok, src = pcall(decompile, inst)
    if not ok then return nil, "decompile failed: " .. tostring(src) end
    return src
end

function tools.get_bytecode(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, bc = pcall(getscriptbytecode, inst)
    if not ok then return nil, tostring(bc) end
    return {
        bytes = #bc,
        sample_hex = bc:sub(1, 64):gsub(".", function(c) return string.format("%02x", string.byte(c)) end),
    }
end

function tools.get_script_hash(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, hash = pcall(getscripthash, inst)
    if not ok then return nil, tostring(hash) end
    return { hash = hash }
end

function tools.get_script_env(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, env = pcall(getsenv, inst)
    if not ok then return nil, tostring(env) end
    local out = {}
    for k, v in pairs(env) do out[tostring(k)] = type(v) end
    return out
end

function tools.get_script_closure(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, closure = pcall(getscriptclosure, inst)
    if not ok then return nil, tostring(closure) end
    local out = { has_closure = closure ~= nil }
    if closure then
        local ok2, cs = pcall(debug.getconstants, closure); if ok2 then out.constants = serialize(cs) end
        local ok3, ups = pcall(debug.getupvalues, closure); if ok3 then out.upvalues = serialize(ups) end
        local ok4, ps = pcall(debug.getprotos, closure);   if ok4 then out.proto_count = #ps end
    end
    return out
end

function tools.list_scripts(_)
    local out = {}
    for _, d in ipairs(getscripts()) do
        out[#out + 1] = { path = d:GetFullName(), class = d.ClassName }
    end
    return out
end

function tools.find_in_source(params)
    local pattern = params.pattern
    if type(pattern) ~= "string" then return nil, "pattern required" end
    local maxFiles = params.max_files or 50
    local literal = params.literal ~= false
    local context = params.context or 0
    local root = game
    if params.scope then
        local r, err = resolvePath(params.scope)
        if not r then return nil, "scope: " .. tostring(err) end
        root = r
    end
    local matches = {}
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Script") then
            local ok, src = pcall(decompile, d)
            if ok and src then
                local found = literal and src:find(pattern, 1, true) or src:find(pattern)
                if found then
                    local lines = {}
                    for line in src:gmatch("[^\r\n]+") do lines[#lines + 1] = line end
                    local lineHits = {}
                    for i = 1, #lines do
                        local hit = literal and lines[i]:find(pattern, 1, true) or lines[i]:find(pattern)
                        if hit then
                            local entry = { line = i, text = lines[i]:sub(1, 240) }
                            if context > 0 then
                                local before, after = {}, {}
                                for j = math.max(1, i - context), i - 1 do before[#before + 1] = lines[j]:sub(1, 240) end
                                for j = i + 1, math.min(#lines, i + context) do after[#after + 1] = lines[j]:sub(1, 240) end
                                entry.before = before
                                entry.after = after
                            end
                            lineHits[#lineHits + 1] = entry
                            if #lineHits >= 20 then break end
                        end
                    end
                    matches[#matches + 1] = { path = d:GetFullName(), hits = lineHits }
                    if #matches >= maxFiles then break end
                end
            end
        end
    end
    return matches
end

function tools.decompile_all_in(params)
    local root = params.path and select(1, resolvePath(params.path)) or game
    if not root then return nil, "root not found" end
    local maxFiles = params.max_files or 25
    local out = {}
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Script") then
            local ok, src = pcall(decompile, d)
            out[#out + 1] = {
                path = d:GetFullName(),
                class = d.ClassName,
                source = ok and src or ("<decompile failed: " .. tostring(src) .. ">"),
            }
            if #out >= maxFiles then break end
        end
    end
    return out
end

function tools.find_remote_callers(params)
    local remoteName = params.name
    if type(remoteName) ~= "string" then return nil, "name required (e.g. 'BuyItem')" end
    local maxFiles = params.max_files or 50
    local root = game
    if params.scope then
        local r, err = resolvePath(params.scope)
        if not r then return nil, "scope: " .. tostring(err) end
        root = r
    end
    local patterns = {
        ('.FireServer'):gsub('.','%%%0'),
        ('.InvokeServer'):gsub('.','%%%0'),
        ('.OnClientEvent'):gsub('.','%%%0'),
        ('.OnClientInvoke'):gsub('.','%%%0'),
    }
    local matches = {}
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Script") then
            local ok, src = pcall(decompile, d)
            if ok and src and src:find(remoteName, 1, true) then
                local capture, lineNum = {}, 1
                for line in src:gmatch("[^\r\n]+") do
                    if line:find(remoteName, 1, true) then
                        local saw_call = false
                        for _, p in ipairs(patterns) do
                            if line:find(p) then saw_call = true; break end
                        end
                        capture[#capture + 1] = { line = lineNum, text = line:sub(1, 240), looks_like_caller = saw_call }
                        if #capture >= 20 then break end
                    end
                    lineNum = lineNum + 1
                end
                if #capture > 0 then
                    matches[#matches + 1] = { path = d:GetFullName(), hits = capture }
                    if #matches >= maxFiles then break end
                end
            end
        end
    end
    return matches
end

function tools.list_remotes(_)
    local kinds = { "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction" }
    local out = {}
    for _, d in ipairs(game:GetDescendants()) do
        for _, k in ipairs(kinds) do
            if d:IsA(k) then
                out[#out + 1] = { path = d:GetFullName(), class = d.ClassName }
                break
            end
        end
    end
    return out
end

function tools.fire_remote(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not (inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent")) then
        return nil, "not a RemoteEvent (got " .. inst.ClassName .. ")"
    end
    local args = params.args or {}
    local ok, errFire = pcall(function() inst:FireServer(table.unpack(args)) end)
    if not ok then return nil, tostring(errFire) end
    return { status = "fired", path = inst:GetFullName(), arg_count = #args }
end

function tools.invoke_remote(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("RemoteFunction") then
        return nil, "not a RemoteFunction (got " .. inst.ClassName .. ")"
    end
    local args = params.args or {}
    local ok, res = pcall(function() return { inst:InvokeServer(table.unpack(args)) } end)
    if not ok then return nil, tostring(res) end
    return serialize(res)
end

function tools.start_remote_log(params)
    local ok, err = installNamecallHook()
    if not ok then return nil, err end
    state.remote_log_enabled = true
    if params and params.cap then state.remote_log_cap = params.cap end
    return { status = "logging started", cap = state.remote_log_cap }
end

function tools.stop_remote_log(_)
    state.remote_log_enabled = false
    return { status = "logging stopped", entries = #state.remote_log }
end

function tools.get_remote_log(params)
    local since = params and params.since_index or 0
    local out = {}
    for i = since + 1, #state.remote_log do out[#out + 1] = state.remote_log[i] end
    return { entries = out, total = #state.remote_log }
end

function tools.clear_remote_log(_)
    state.remote_log = {}
    return { status = "cleared" }
end

local function resolveSignal(spec)
    if type(spec) ~= "string" then return nil, "signal must be 'path::SignalName'" end
    local p, sig = spec:match("^(.-)::(.+)$")
    if not p or not sig then return nil, "expected 'path::SignalName'" end
    local inst, err = resolvePath(p)
    if not inst then return nil, err end
    local ok, val = pcall(function() return inst[sig] end)
    if not ok or typeof(val) ~= "RBXScriptSignal" then
        return nil, "not an RBXScriptSignal: " .. tostring(sig)
    end
    return val
end

function tools.get_signal_connections(params)
    local signal, err = resolveSignal(params.signal)
    if not signal then return nil, err end
    local conns = getconnections(signal)
    local out = {}
    for _, c in ipairs(conns) do
        local entry = {}
        pcall(function() entry.enabled = c.Enabled end)
        pcall(function() entry.foreign_state = c.ForeignState end)
        pcall(function() entry.lua_connection = c.LuaConnection end)
        if c.Function then
            pcall(function() entry.source = debug.info(c.Function, "s") end)
            pcall(function() entry.line = debug.info(c.Function, "l") end)
        end
        if c.Script then
            pcall(function() entry.script_path = c.Script:GetFullName() end)
        end
        out[#out + 1] = entry
    end
    return out
end

function tools.fire_signal(params)
    local signal, err = resolveSignal(params.signal)
    if not signal then return nil, err end
    local args = params.args or {}
    local ok, e = pcall(firesignal, signal, table.unpack(args))
    if not ok then return nil, tostring(e) end
    return { status = "fired", signal = params.signal }
end

function tools.replicate_signal(params)
    local signal, err = resolveSignal(params.signal)
    if not signal then return nil, err end
    local can = false
    pcall(function() can = cansignalreplicate(signal) end)
    if not can then return nil, "signal is not in the replication whitelist" end
    local args = params.args or {}
    local ok, e = pcall(replicatesignal, signal, table.unpack(args))
    if not ok then return nil, tostring(e) end
    return { status = "replicated", signal = params.signal }
end

function tools.get_signal_whitelist(_)
    local list = getsignalwhitelist()
    return list
end

function tools.get_callback(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local cb = getcallbackvalue(inst, params.name)
    if cb == nil then return { has_callback = false } end
    local out = { has_callback = true }
    pcall(function() out.source = debug.info(cb, "s") end)
    pcall(function() out.line = debug.info(cb, "l") end)
    local ok, ups = pcall(debug.getupvalues, cb)
    if ok then out.upvalues = serialize(ups) end
    return out
end

function tools.fire_proximity_prompt(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ProximityPrompt") then
        return nil, "not a ProximityPrompt (got " .. inst.ClassName .. ")"
    end
    fireproximityprompt(inst)
    return { status = "fired", path = inst:GetFullName() }
end

function tools.fire_click_detector(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ClickDetector") then
        return nil, "not a ClickDetector (got " .. inst.ClassName .. ")"
    end
    fireclickdetector(inst, params.distance or 0, params.event or "MouseClick")
    return { status = "fired", path = inst:GetFullName(), event = params.event or "MouseClick" }
end

function tools.fire_touch_interest(params)
    local source, errS = resolvePath(params.part)
    if not source then return nil, "part: " .. tostring(errS) end
    local target, errT = resolvePath(params.target)
    if not target then return nil, "target: " .. tostring(errT) end
    local touch
    if params.toggle == 1 or params.toggle == true then
        touch = true
    elseif params.toggle == 0 or params.toggle == false then
        touch = false
    else
        return nil, "toggle must be boolean or 0/1"
    end
    firetouchinterest(source, target, touch)
    return { status = "fired", touch = touch }
end

function tools.get_loaded_modules(_)
    local out = {}
    for _, m in ipairs(getloadedmodules()) do
        out[#out + 1] = { path = m:GetFullName(), class = m.ClassName }
    end
    return out
end

function tools.get_running_scripts(_)
    local out = {}
    for _, s in ipairs(getrunningscripts()) do
        out[#out + 1] = { path = s:GetFullName(), class = s.ClassName }
    end
    return out
end

function tools.gc_search(params)
    local kind = params.kind or "all"
    local query = params.query
    local maxResults = params.max_results or 50
    local includeNonObjs = params.include_non_objects or false

    local matches = {}
    for _, v in ipairs(getgc(includeNonObjs)) do
        local t = type(v)
        if (kind == "all" or kind == t) then
            if t == "function" then
                local src; pcall(function() src = debug.info(v, "s") end)
                if src and (not query or tostring(src):lower():find(query:lower(), 1, true)) then
                    local line; pcall(function() line = debug.info(v, "l") end)
                    local name; pcall(function() name = debug.info(v, "n") end)
                    matches[#matches + 1] = { type = "function", source = tostring(src), line = line, name = name }
                end
            elseif t == "table" then
                local hasMatch = not query
                if query then
                    for k, _ in pairs(v) do
                        if tostring(k):lower():find(query:lower(), 1, true) then hasMatch = true; break end
                    end
                end
                if hasMatch then
                    local keys, count = {}, 0
                    for k in pairs(v) do
                        keys[#keys + 1] = tostring(k)
                        count = count + 1
                        if count >= 12 then break end
                    end
                    matches[#matches + 1] = { type = "table", keys = keys, size_sample = count }
                end
            end
            if #matches >= maxResults then break end
        end
    end
    return matches
end

function tools.filter_gc(params)
    local kind = params.kind or "function"
    if kind ~= "function" and kind ~= "table" then
        return nil, "kind must be 'function' or 'table'"
    end
    local options = params.options or {}
    local ok, results = pcall(filtergc, kind, options, false)
    if not ok then return nil, tostring(results) end
    local maxResults = params.max_results or 50
    local out = {}
    for i, v in ipairs(results) do
        if i > maxResults then break end
        if kind == "function" then
            local entry = { type = "function" }
            pcall(function() entry.source = debug.info(v, "s") end)
            pcall(function() entry.line = debug.info(v, "l") end)
            pcall(function() entry.name = debug.info(v, "n") end)
            out[#out + 1] = entry
        else
            local keys, count = {}, 0
            for k in pairs(v) do
                keys[#keys + 1] = tostring(k); count = count + 1
                if count >= 12 then break end
            end
            out[#out + 1] = { type = "table", keys = keys }
        end
    end
    return { matches = out, total = #results, truncated = #results > maxResults }
end

function tools.get_globals(params)
    local kind = params and params.kind or "_G"
    local env
    if kind == "_G" then env = _G
    elseif kind == "shared" then env = shared
    elseif kind == "genv" then env = getgenv()
    elseif kind == "renv" then env = getrenv()
    elseif kind == "fenv" then env = getfenv()
    elseif kind == "reg" then env = getreg()
    else return nil, "unknown kind (use _G, shared, genv, renv, fenv, reg)" end
    local out = {}
    for k, v in pairs(env) do out[tostring(k)] = type(v) end
    return out
end

function tools.inspect_function(params)
    local code = params.code
    if type(code) ~= "string" then return nil, "code expr required (must return a function)" end
    local fn, err = lua_load(code, "inspect_function")
    if not fn then return nil, "compile: " .. tostring(err) end
    local ok, target = pcall(fn)
    if not ok then return nil, "runtime: " .. tostring(target) end
    if type(target) ~= "function" then return nil, "not a function (got " .. type(target) .. ")" end
    local out = {}
    pcall(function() out.source = debug.info(target, "s") end)
    pcall(function() out.line = debug.info(target, "l") end)
    pcall(function() out.name = debug.info(target, "n") end)
    pcall(function() out.is_c = iscclosure(target) end)
    pcall(function() out.is_executor = isexecutorclosure(target) end)
    pcall(function() out.is_newcclosure = isnewcclosure(target) end)
    pcall(function() out.is_hooked = isfunctionhooked(target) end)
    local ok2, ups = pcall(debug.getupvalues, target); if ok2 then out.upvalues = serialize(ups) end
    local ok3, cs = pcall(debug.getconstants, target); if ok3 then out.constants = serialize(cs) end
    local ok4, ps = pcall(debug.getprotos, target);   if ok4 then out.proto_count = #ps end
    local ok5, h = pcall(getfunctionhash, target);    if ok5 then out.hash = h end
    return out
end

function tools.get_thread_identity(_)
    return { identity = getthreadidentity() }
end

function tools.set_thread_identity(params)
    local id = tonumber(params.identity)
    if not id then return nil, "identity (1-8) required" end
    setthreadidentity(id)
    return { identity = id }
end

function tools.get_metatable(params)
    local code = params.code
    if type(code) ~= "string" then return nil, "code expr required (must return the object)" end
    local fn, err = lua_load(code, "get_metatable")
    if not fn then return nil, "compile: " .. tostring(err) end
    local ok, obj = pcall(fn)
    if not ok then return nil, "runtime: " .. tostring(obj) end
    local mt = getrawmetatable(obj)
    if not mt then return { has_metatable = false } end
    local keys = {}
    for k, _ in pairs(mt) do keys[#keys + 1] = tostring(k) end
    return { has_metatable = true, keys = keys }
end

function tools.list_players(_)
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        out[#out + 1] = { name = p.Name, displayName = p.DisplayName, userId = p.UserId,
                          team = p.Team and p.Team.Name or nil,
                          hasCharacter = p.Character ~= nil }
    end
    return out
end

function tools.get_player(params)
    local p = params and params.name and Players:FindFirstChild(params.name) or Players.LocalPlayer
    if not p then return nil, "player not found" end
    local char = p.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return {
        name = p.Name, displayName = p.DisplayName, userId = p.UserId,
        team = p.Team and p.Team.Name or nil,
        character = char and char:GetFullName() or nil,
        position = hrp and serialize(hrp.Position) or nil,
    }
end

function tools.teleport(params)
    local char = Players.LocalPlayer.Character
    if not char then return nil, "LocalPlayer has no character" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, "no HumanoidRootPart" end
    local pos = params.position
    if type(pos) ~= "table" or pos.x == nil then
        return nil, "position required: { x = .., y = .., z = .. }"
    end
    hrp.CFrame = CFrame.new(pos.x, pos.y, pos.z)
    return { status = "teleported", new_position = serialize(hrp.Position) }
end

function tools.read_file(params)
    if not isfile(params.path) then return nil, "not a file" end
    local ok, content = pcall(readfile, params.path)
    if not ok then return nil, tostring(content) end
    return content
end

function tools.write_file(params)
    local ok, err = pcall(writefile, params.path, params.content or "")
    if not ok then return nil, tostring(err) end
    return { status = "written", bytes = #(params.content or "") }
end

function tools.append_file(params)
    local ok, err = pcall(appendfile, params.path, params.content or "")
    if not ok then return nil, tostring(err) end
    return { status = "appended", bytes = #(params.content or "") }
end

function tools.delete_file(params)
    local ok, err = pcall(delfile, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "deleted" }
end

function tools.list_files(params)
    local ok, files = pcall(listfiles, params.folder or "")
    if not ok then return nil, tostring(files) end
    return files
end

function tools.make_folder(params)
    local ok, err = pcall(makefolder, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "created" }
end

function tools.delete_folder(params)
    local ok, err = pcall(delfolder, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "deleted" }
end

function tools.get_custom_asset(params)
    local ok, res = pcall(getcustomasset, params.path)
    if not ok then return nil, tostring(res) end
    return { asset_id = res }
end

function tools.get_objects(params)
    local ok, res = pcall(getobjects, params.asset)
    if not ok then return nil, tostring(res) end
    local out = {}
    for _, inst in ipairs(res) do
        out[#out + 1] = { name = inst.Name, class = inst.ClassName }
    end
    return { count = #out, items = out }
end

function tools.save_instance(params)
    local obj
    if params.path then
        local inst, err = resolvePath(params.path)
        if not inst then return nil, err end
        obj = inst
    end
    local options = {}
    if params.file_name        then options.FileName               = params.file_name end
    if params.decompile ~= nil then options.Decompile              = params.decompile end
    if params.nil_instances ~= nil       then options.NilInstances           = params.nil_instances end
    if params.remove_player_chars ~= nil then options.RemovePlayerCharacters = params.remove_player_chars end
    if params.save_players ~= nil        then options.SavePlayers            = params.save_players end
    if params.decompile_timeout then options.DecompileTimeout        = params.decompile_timeout end
    if params.max_threads      then options.MaxThreads              = params.max_threads end
    if params.decompile_ignore then options.DecompileIgnore         = params.decompile_ignore end
    if params.show_status ~= nil         then options.ShowStatus              = params.show_status end
    if params.ignore_default_props ~= nil then options.IgnoreDefaultProps     = params.ignore_default_props end
    if params.isolate_starter_player ~= nil then options.IsolateStarterPlayer = params.isolate_starter_player end
    local ok, err = pcall(saveinstance, obj, options)
    if not ok then return nil, tostring(err) end
    return { status = "saved", file_name = options.FileName }
end

function tools.crypt_hash(params)
    local algo = params.algorithm or "sha256"
    local ok, h = pcall(crypt.hash, params.data, algo)
    if not ok then return nil, tostring(h) end
    return { hash = h, algorithm = algo }
end

function tools.crypt_hmac(params)
    local algo = params.algorithm or "sha256"
    local ok, h = pcall(crypt.hmac, params.key, params.data, algo)
    if not ok then return nil, tostring(h) end
    return { hmac = h, algorithm = algo }
end

function tools.crypt_encrypt(params)
    local ok, c, iv = pcall(crypt.encrypt, params.data, params.key, params.iv, params.algorithm)
    if not ok then return nil, tostring(c) end
    return { ciphertext = c, iv = iv }
end

function tools.crypt_decrypt(params)
    local ok, p = pcall(crypt.decrypt, params.data, params.key, params.iv, params.algorithm or "CBC")
    if not ok then return nil, tostring(p) end
    return { plaintext = p }
end

function tools.crypt_random(params)
    local ok, b = pcall(crypt.random, params.length or 32)
    if not ok then return nil, tostring(b) end
    return { bytes_base64 = crypt.base64encode(b), length = params.length or 32 }
end

function tools.crypt_generatekey(params)
    local ok, k = pcall(crypt.generatekey, params.length)
    if not ok then return nil, tostring(k) end
    return { key = k }
end

function tools.base64_encode(params)
    return { encoded = crypt.base64encode(params.data) }
end

function tools.base64_decode(params)
    local ok, d = pcall(crypt.base64decode, params.data)
    if not ok then return nil, tostring(d) end
    return { decoded = d }
end

function tools.lz4_compress(params)
    local ok, c = pcall(crypt.lz4compress, params.data)
    if not ok then return nil, tostring(c) end
    return {
        size = #c,
        original_size = #params.data,
        compressed_base64 = crypt.base64encode(c),
    }
end

function tools.lz4_decompress(params)
    local data = params.data
    if params.base64 then data = crypt.base64decode(data) end
    local ok, d = pcall(crypt.lz4decompress, data, params.size)
    if not ok then return nil, tostring(d) end
    return { decompressed = d, size = #d }
end

function tools.http_request(params)
    local opts = {
        Url = params.url,
        Method = params.method or "GET",
        Headers = params.headers,
        Body = params.body,
        Cookies = params.cookies,
    }
    local ok, res = pcall(request, opts)
    if not ok then return nil, tostring(res) end
    return {
        success = res.Success,
        status_code = res.StatusCode,
        status_message = res.StatusMessage,
        headers = res.Headers,
        body = res.Body,
    }
end

function tools.http_get(params)
    local ok, body = pcall(httpget, params.url)
    if not ok then return nil, tostring(body) end
    return body
end

function tools.is_window_active(_)
    return { active = isrbxactive() }
end

function tools.key_click(params)
    keytap(params.keycode)
    return { status = "tapped", keycode = params.keycode }
end

function tools.key_press(params)
    keypress(params.keycode)
    return { status = "pressed", keycode = params.keycode }
end

function tools.key_release(params)
    keyrelease(params.keycode)
    return { status = "released", keycode = params.keycode }
end

function tools.mouse_click(params)
    local button = params.button or "left"
    if button == "left" then
        mouse1click()
    elseif button == "right" then
        mouse2click()
    else
        return nil, "button must be 'left' or 'right'"
    end
    return { status = "clicked", button = button }
end

function tools.mouse_move(params)
    if params.relative then
        mousemoverel(params.x, params.y)
    else
        mousemoveabs(params.x, params.y)
    end
    return { status = "moved", x = params.x, y = params.y, relative = params.relative == true }
end

function tools.mouse_scroll(params)
    mousescroll(params.delta)
    return { status = "scrolled", delta = params.delta }
end

function tools.console_show(_)
    rconsolecreate()
    return { status = "shown" }
end

function tools.console_hide(_)
    rconsoledestroy()
    return { status = "hidden" }
end

function tools.console_print(params)
    local fn = (params.level == "warn"  and rconsolewarn)
        or (params.level == "error" and rconsoleerror)
        or (params.level == "info"  and rconsoleinfo)
        or rconsoleprint
    fn(tostring(params.text))
    return { status = "printed" }
end

function tools.console_clear(_)
    rconsoleclear()
    return { status = "cleared" }
end

function tools.console_title(params)
    rconsolesettitle(params.title)
    return { status = "set", title = params.title }
end

function tools.identify_executor(_)
    local name, version = identifyexecutor()
    return { name = name, version = version }
end

function tools.get_hwid(_)
    return { hwid = gethwid() }
end

function tools.get_fps_cap(_)
    return { fps = getfpscap() }
end

function tools.set_fps_cap(params)
    setfpscap(params.fps)
    return { fps = params.fps }
end

function tools.set_clipboard(params)
    setclipboard(params.text)
    return { status = "copied", bytes = #(params.text or "") }
end

function tools.get_fflag(params)
    local ok, v = pcall(getfflag, params.name)
    if not ok then return nil, tostring(v) end
    return { name = params.name, value = v }
end

function tools.set_fflag(params)
    local ok, err = pcall(setfflag, params.name, params.value)
    if not ok then return nil, tostring(err) end
    return { name = params.name, value = params.value }
end

function tools.message_box(params)
    local result = messagebox(params.text or "", params.caption or "Roblox-Bridge", params.flags or 0)
    return { result = result }
end

function tools.queue_on_teleport(params)
    local ok, err = pcall(queueonteleport, params.code)
    if not ok then return nil, tostring(err) end
    return { status = "queued" }
end

function tools.clear_teleport_queue(_)
    clearteleportqueue()
    return { status = "cleared" }
end

function tools.draw_create(params)
    local ok, d = pcall(Drawing.new, params.type)
    if not ok then return nil, tostring(d) end
    if params.properties then
        for k, v in pairs(params.properties) do
            pcall(setrenderproperty, d, k, v)
        end
    end
    local id = state.next_draw_id
    state.next_draw_id = id + 1
    state.drawings[id] = d
    return { id = id, type = params.type }
end

function tools.draw_set(params)
    local d = state.drawings[params.id]
    if not d then return nil, "no drawing with id " .. tostring(params.id) end
    for k, v in pairs(params.properties or {}) do
        local ok, err = pcall(setrenderproperty, d, k, v)
        if not ok then return nil, ("set %s: %s"):format(k, tostring(err)) end
    end
    return { status = "set", id = params.id }
end

function tools.draw_remove(params)
    local d = state.drawings[params.id]
    if not d then return nil, "no drawing with id " .. tostring(params.id) end
    pcall(function() d:Remove() end)
    state.drawings[params.id] = nil
    return { status = "removed", id = params.id }
end

function tools.draw_clear(_)
    cleardrawcache()
    state.drawings = {}
    return { status = "cleared" }
end

local function readBody(resp)
    if type(resp) == "string" then return resp end
    if type(resp) == "table" then
        local b = resp.Body or resp.body or resp.text
        if type(b) == "function" then b = b() end
        return b or ""
    end
    return ""
end

local function post(path, body)
    local ok, resp = pcall(request, {
        Url = HOST .. path,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jenc(body or {}),
    })
    if not ok then return nil, tostring(resp) end
    return resp, nil
end

local function handleCommand(cmd)
    local handler = tools[cmd.method]
    local response
    if not handler then
        response = { id = cmd.id, ok = false, error = "unknown method: " .. tostring(cmd.method) }
    else
        local results = { xpcall(function()
            return handler(cmd.params or {})
        end, function(e)
            return tostring(e) .. "\n" .. debug.traceback("", 2)
        end) }
        local call_ok = table.remove(results, 1)
        local result, err = results[1], results[2]
        if not call_ok then
            response = { id = cmd.id, ok = false, error = "runtime error in " .. tostring(cmd.method) .. ": " .. tostring(result) }
        elseif err then
            response = { id = cmd.id, ok = false, error = tostring(err) }
        else
            response = { id = cmd.id, ok = true, result = result }
        end
    end
    post("/result", response)
end

local names = {}
for k in pairs(tools) do names[#names + 1] = k end
table.sort(names)
print(("[Claude Gateway] %d tools loaded (Potassium)"):format(#names))
print("[Claude Gateway] connecting to " .. HOST)

local announced = false
while true do
    local resp, err = post("/poll", {})
    if not resp then
        warn("[Claude Gateway] poll failed: " .. tostring(err) .. " (retrying in 2s)")
        task.wait(2)
    else
        if not announced then
            announced = true
            print("[Claude Gateway] connected, awaiting commands...")
        end
        local body = readBody(resp)
        if body and #body > 0 then
            local decodeOk, cmd = pcall(jdec, body)
            if decodeOk and cmd and cmd.id and cmd.method then
                task.spawn(handleCommand, cmd)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.1)
        end
    end
end
