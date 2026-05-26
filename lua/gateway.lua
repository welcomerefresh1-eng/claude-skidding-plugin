assert(loadstring or load, "executor missing required function loadstring/load")

local HOST = "http://127.0.0.1:7474"

local request = http_request
    or request
    or (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
assert(request, "executor missing required function request/http_request")

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

local lua_load = loadstring or load
local wait_ = (task and task.wait) or wait
local spawn_ = (task and task.spawn) or spawn

local function jenc(t) return HttpService:JSONEncode(t) end
local function jdec(s) return HttpService:JSONDecode(s) end

local function missing(name)
    return nil, "executor missing required function " .. name
end

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
    if not hookmetamethod then return nil, "executor missing required function hookmetamethod" end
    if not getnamecallmethod then return nil, "executor missing required function getnamecallmethod" end
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
        if not setthreadidentity then return missing("setthreadidentity") end
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
    if not getnilinstances then return missing("getnilinstances") end
    local out = {}
    for _, inst in ipairs(getnilinstances()) do
        out[#out + 1] = { class = inst.ClassName, name = inst.Name, path = inst:GetFullName() }
    end
    return out
end

function tools.get_all_instances(params)
    if not getinstances then return missing("getinstances") end
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
    if not gethui then return missing("gethui") end
    local hui = gethui()
    local children = {}
    for _, c in ipairs(hui:GetChildren()) do
        children[#children + 1] = { name = c.Name, class = c.ClassName }
    end
    return { path = hui:GetFullName(), class = hui.ClassName, children = children }
end

function tools.compare_instances(params)
    if not compareinstances then return missing("compareinstances") end
    local a, errA = resolvePath(params.a)
    if not a then return nil, "a: " .. tostring(errA) end
    local b, errB = resolvePath(params.b)
    if not b then return nil, "b: " .. tostring(errB) end
    return { equal = compareinstances(a, b) }
end

function tools.get_property(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, res = pcall(function() return inst[params.name] end)
    if ok then return serialize(res) end
    if gethiddenproperty then
        local ok2, hidden = pcall(gethiddenproperty, inst, params.name)
        if ok2 then return { value = serialize(hidden), via = "gethiddenproperty" } end
    end
    return nil, "read failed: " .. tostring(res)
end

function tools.set_property(params)
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, res = pcall(function() inst[params.name] = params.value end)
    if ok then return { status = "set" } end
    if sethiddenproperty then
        local ok2 = pcall(sethiddenproperty, inst, params.name, params.value)
        if ok2 then return { status = "set via sethiddenproperty" } end
    end
    return nil, "set failed: " .. tostring(res)
end

function tools.get_all_properties(params)
    if not getproperties then return missing("getproperties") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, props = pcall(getproperties, inst)
    if not ok then return nil, tostring(props) end
    return serialize(props)
end

function tools.get_hidden_properties(params)
    if not gethiddenproperties then return missing("gethiddenproperties") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, props = pcall(gethiddenproperties, inst)
    if not ok then return nil, tostring(props) end
    return serialize(props)
end

function tools.is_scriptable(params)
    if not isscriptable then return missing("isscriptable") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    return { scriptable = isscriptable(inst, params.name) }
end

function tools.set_scriptable(params)
    if not setscriptable then return missing("setscriptable") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local prev = setscriptable(inst, params.name, params.scriptable == true)
    return { previous = prev, current = params.scriptable == true }
end

function tools.get_source(params)
    if not decompile then return missing("decompile") end
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
    if not getscriptbytecode then return missing("getscriptbytecode") end
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
    if not getscripthash then return missing("getscripthash") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, hash = pcall(getscripthash, inst)
    if not ok then return nil, tostring(hash) end
    return { hash = hash }
end

function tools.get_script_env(params)
    if not getsenv then return missing("getsenv") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, env = pcall(getsenv, inst)
    if not ok then return nil, tostring(env) end
    local out = {}
    for k, v in pairs(env) do out[tostring(k)] = type(v) end
    return out
end

function tools.get_script_closure(params)
    local fn = getscriptclosure or getscriptfunction
    if not fn then return missing("getscriptclosure") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local ok, closure = pcall(fn, inst)
    if not ok then return nil, tostring(closure) end
    local out = { has_closure = closure ~= nil }
    if debug and debug.getconstants then
        local ok2, cs = pcall(debug.getconstants, closure)
        if ok2 then out.constants = serialize(cs) end
    end
    if debug and debug.getupvalues then
        local ok2, ups = pcall(debug.getupvalues, closure)
        if ok2 then out.upvalues = serialize(ups) end
    end
    if debug and debug.getprotos then
        local ok2, ps = pcall(debug.getprotos, closure)
        if ok2 then out.proto_count = #ps end
    end
    return out
end

function tools.list_scripts(_)
    local out = {}
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Script") then
            out[#out + 1] = { path = d:GetFullName(), class = d.ClassName }
        end
    end
    return out
end

function tools.find_in_source(params)
    if not decompile then return missing("decompile") end
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
    if not decompile then return missing("decompile") end
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

function tools.get_calling_script(_)
    if not getcallingscript then return missing("getcallingscript") end
    local s = getcallingscript()
    if not s then return { script = nil } end
    return { class = s.ClassName, path = s:GetFullName() }
end

function tools.find_remote_callers(params)
    if not decompile then return missing("decompile") end
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
    if not getconnections then return missing("getconnections") end
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
        out[#out + 1] = entry
    end
    return out
end

function tools.fire_signal(params)
    if not firesignal then return missing("firesignal") end
    local signal, err = resolveSignal(params.signal)
    if not signal then return nil, err end
    local args = params.args or {}
    local ok, e = pcall(firesignal, signal, table.unpack(args))
    if not ok then return nil, tostring(e) end
    return { status = "fired", signal = params.signal }
end

function tools.replicate_signal(params)
    if not replicatesignal then return missing("replicatesignal") end
    local signal, err = resolveSignal(params.signal)
    if not signal then return nil, err end
    if cansignalreplicate then
        local can = false
        pcall(function() can = cansignalreplicate(signal) end)
        if not can then return nil, "signal is not in the replication whitelist" end
    end
    local args = params.args or {}
    local ok, e = pcall(replicatesignal, signal, table.unpack(args))
    if not ok then return nil, tostring(e) end
    return { status = "replicated", signal = params.signal }
end

function tools.get_callback(params)
    if not getcallbackvalue then return missing("getcallbackvalue") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    local cb = getcallbackvalue(inst, params.name)
    if cb == nil then return { has_callback = false } end
    local out = { has_callback = true }
    pcall(function() out.source = debug.info(cb, "s") end)
    pcall(function() out.line = debug.info(cb, "l") end)
    if debug.getupvalues then
        local ok, ups = pcall(debug.getupvalues, cb)
        if ok then out.upvalues = serialize(ups) end
    end
    return out
end

function tools.fire_proximity_prompt(params)
    if not fireproximityprompt then return missing("fireproximityprompt") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ProximityPrompt") then
        return nil, "not a ProximityPrompt (got " .. inst.ClassName .. ")"
    end
    fireproximityprompt(inst, params.amount or 1, params.skip ~= false)
    return { status = "fired", path = inst:GetFullName() }
end

function tools.fire_click_detector(params)
    if not fireclickdetector then return missing("fireclickdetector") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    if not inst:IsA("ClickDetector") then
        return nil, "not a ClickDetector (got " .. inst.ClassName .. ")"
    end
    fireclickdetector(inst, params.distance or 0, params.event or "MouseClick")
    return { status = "fired", path = inst:GetFullName(), event = params.event or "MouseClick" }
end

function tools.fire_touch_interest(params)
    if not firetouchinterest then return missing("firetouchinterest") end
    local part, errP = resolvePath(params.part)
    if not part then return nil, "part: " .. tostring(errP) end
    local target, errT = resolvePath(params.target)
    if not target then return nil, "target: " .. tostring(errT) end
    local toggle = params.toggle
    if toggle ~= 0 and toggle ~= 1 then return nil, "toggle must be 0 (TouchEnded) or 1 (Touched)" end
    firetouchinterest(part, target, toggle)
    return { status = "fired", toggle = toggle }
end

function tools.get_loaded_modules(_)
    if not getloadedmodules then return missing("getloadedmodules") end
    local out = {}
    for _, m in ipairs(getloadedmodules()) do
        out[#out + 1] = { path = m:GetFullName(), class = m.ClassName }
    end
    return out
end

function tools.get_running_scripts(_)
    if not getrunningscripts then return missing("getrunningscripts") end
    local out = {}
    for _, s in ipairs(getrunningscripts()) do
        out[#out + 1] = { path = s:GetFullName(), class = s.ClassName }
    end
    return out
end

function tools.gc_search(params)
    if not getgc then return missing("getgc") end
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
    if not filtergc then return missing("filtergc") end
    local kind = params.kind or "function"
    if kind ~= "function" and kind ~= "table" then
        return nil, "kind must be 'function' or 'table'"
    end
    local options = params.options or {}
    local ok, results = pcall(filtergc, kind, options)
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
    elseif kind == "genv" then
        if not getgenv then return missing("getgenv") end
        env = getgenv()
    elseif kind == "renv" then
        if not getrenv then return missing("getrenv") end
        env = getrenv()
    elseif kind == "fenv" then env = getfenv()
    elseif kind == "reg" then
        if not getreg then return missing("getreg") end
        env = getreg()
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
    pcall(function() out.is_c = iscclosure and iscclosure(target) or nil end)
    pcall(function() out.is_executor = isexecutorclosure and isexecutorclosure(target) or nil end)
    if debug.getupvalues then
        local ok2, ups = pcall(debug.getupvalues, target)
        if ok2 then out.upvalues = serialize(ups) end
    end
    if debug.getconstants then
        local ok2, cs = pcall(debug.getconstants, target)
        if ok2 then out.constants = serialize(cs) end
    end
    if debug.getprotos then
        local ok2, ps = pcall(debug.getprotos, target)
        if ok2 then out.proto_count = #ps end
    end
    if getfunctionhash then
        local ok2, h = pcall(getfunctionhash, target); if ok2 then out.hash = h end
    end
    return out
end

function tools.get_thread_identity(_)
    if not getthreadidentity then return missing("getthreadidentity") end
    return { identity = getthreadidentity() }
end

function tools.set_thread_identity(params)
    if not setthreadidentity then return missing("setthreadidentity") end
    local id = tonumber(params.identity)
    if not id then return nil, "identity (1-8) required" end
    setthreadidentity(id)
    return { identity = id }
end

function tools.get_metatable(params)
    if not getrawmetatable then return missing("getrawmetatable") end
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
    if not readfile then return missing("readfile") end
    if isfile and not isfile(params.path) then return nil, "not a file" end
    local ok, content = pcall(readfile, params.path)
    if not ok then return nil, tostring(content) end
    return content
end

function tools.write_file(params)
    if not writefile then return missing("writefile") end
    local ok, err = pcall(writefile, params.path, params.content or "")
    if not ok then return nil, tostring(err) end
    return { status = "written", bytes = #(params.content or "") }
end

function tools.append_file(params)
    if not appendfile then return missing("appendfile") end
    local ok, err = pcall(appendfile, params.path, params.content or "")
    if not ok then return nil, tostring(err) end
    return { status = "appended", bytes = #(params.content or "") }
end

function tools.delete_file(params)
    if not delfile then return missing("delfile") end
    local ok, err = pcall(delfile, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "deleted" }
end

function tools.list_files(params)
    if not listfiles then return missing("listfiles") end
    local ok, files = pcall(listfiles, params.folder or "")
    if not ok then return nil, tostring(files) end
    return files
end

function tools.make_folder(params)
    if not makefolder then return missing("makefolder") end
    local ok, err = pcall(makefolder, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "created" }
end

function tools.delete_folder(params)
    if not delfolder then return missing("delfolder") end
    local ok, err = pcall(delfolder, params.path)
    if not ok then return nil, tostring(err) end
    return { status = "deleted" }
end

function tools.save_instance(params)
    if not saveinstance then return missing("saveinstance") end
    local opts = { FilePath = params.file_path, Mode = params.mode or "optimized" }
    if params.path then
        local inst, err = resolvePath(params.path)
        if not inst then return nil, err end
        opts.Object = inst
    end
    if params.extra_paths then
        local extras = {}
        for _, p in ipairs(params.extra_paths) do
            local i = resolvePath(p); if i then extras[#extras + 1] = i end
        end
        opts.ExtraInstances = extras
    end
    if params.nil_instances ~= nil then opts.NilInstances = params.nil_instances end
    if params.remove_player_chars ~= nil then opts.RemovePlayerCharacters = params.remove_player_chars end
    local ok, err = pcall(saveinstance, opts)
    if not ok then return nil, tostring(err) end
    return { status = "saved", file_path = params.file_path }
end

function tools.save_place(params)
    if not saveplace then return missing("saveplace") end
    local ok, err = pcall(saveplace, params.filename)
    if not ok then return nil, tostring(err) end
    return { status = "saved", filename = params.filename }
end

function tools.crypt_hash(params)
    if not (crypt and crypt.hash) then return missing("crypt.hash") end
    local algo = params.algorithm or "SHA256"
    local ok, h = pcall(crypt.hash, params.data, algo)
    if not ok then return nil, tostring(h) end
    return { hash = h, algorithm = algo }
end

function tools.crypt_hmac(params)
    if not (crypt and crypt.hmac) then return missing("crypt.hmac") end
    local algo = params.algorithm or "SHA256"
    local ok, h = pcall(crypt.hmac, params.data, params.key, algo)
    if not ok then return nil, tostring(h) end
    return { hmac = h, algorithm = algo }
end

function tools.crypt_encrypt(params)
    if not (crypt and crypt.encrypt) then return missing("crypt.encrypt") end
    local ok, c = pcall(crypt.encrypt, params.data, params.key, params.iv, params.algorithm)
    if not ok then return nil, tostring(c) end
    return { ciphertext = c }
end

function tools.crypt_decrypt(params)
    if not (crypt and crypt.decrypt) then return missing("crypt.decrypt") end
    local ok, p = pcall(crypt.decrypt, params.data, params.key, params.iv, params.algorithm)
    if not ok then return nil, tostring(p) end
    return { plaintext = p }
end

function tools.crypt_random(params)
    if not (crypt and crypt.random) then return missing("crypt.random") end
    local ok, b = pcall(crypt.random, params.length or 32)
    if not ok then return nil, tostring(b) end
    local enc = base64encode and base64encode(b) or "<base64 unavailable>"
    return { bytes_base64 = enc, length = params.length or 32 }
end

function tools.base64_encode(params)
    if not base64encode then return missing("base64encode") end
    return { encoded = base64encode(params.data) }
end

function tools.base64_decode(params)
    if not base64decode then return missing("base64decode") end
    local ok, d = pcall(base64decode, params.data)
    if not ok then return nil, tostring(d) end
    return { decoded = d }
end

function tools.lz4_compress(params)
    if not lz4compress then return missing("lz4compress") end
    local ok, c = pcall(lz4compress, params.data)
    if not ok then return nil, tostring(c) end
    return {
        size = #c,
        original_size = #params.data,
        compressed_base64 = base64encode and base64encode(c) or "<base64 unavailable>",
    }
end

function tools.lz4_decompress(params)
    if not lz4decompress then return missing("lz4decompress") end
    local data = params.data
    if params.base64 and base64decode then data = base64decode(data) end
    local ok, d = pcall(lz4decompress, data, params.size)
    if not ok then return nil, tostring(d) end
    return { decompressed = d, size = #d }
end

function tools.http_request(params)
    if not request then return missing("request") end
    local opts = {
        Url = params.url,
        Method = params.method or "GET",
        Headers = params.headers,
        Body = params.body,
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

function tools.is_window_active(_)
    if not iswindowactive then return missing("iswindowactive") end
    return { active = iswindowactive() }
end

function tools.key_click(params)
    if not keyclick then return missing("keyclick") end
    keyclick(params.keycode)
    return { status = "clicked", keycode = params.keycode }
end

function tools.key_press(params)
    if not keypress then return missing("keypress") end
    keypress(params.keycode)
    return { status = "pressed", keycode = params.keycode }
end

function tools.key_release(params)
    if not keyrelease then return missing("keyrelease") end
    keyrelease(params.keycode)
    return { status = "released", keycode = params.keycode }
end

function tools.mouse_click(params)
    local button = params.button or "left"
    if button == "left" then
        if not mouse1click then return missing("mouse1click") end
        mouse1click()
    elseif button == "right" then
        if not mouse2click then return missing("mouse2click") end
        mouse2click()
    else return nil, "button must be 'left' or 'right'" end
    return { status = "clicked", button = button }
end

function tools.mouse_move(params)
    if params.relative then
        if not mousemoverel then return missing("mousemoverel") end
        mousemoverel(params.x, params.y)
    else
        if not mousemoveabs then return missing("mousemoveabs") end
        mousemoveabs(params.x, params.y)
    end
    return { status = "moved", x = params.x, y = params.y, relative = params.relative == true }
end

function tools.mouse_scroll(params)
    if not mousescroll then return missing("mousescroll") end
    mousescroll(params.delta)
    return { status = "scrolled", delta = params.delta }
end

function tools.console_show(_)
    if not rconsoleshow then return missing("rconsoleshow") end
    rconsoleshow()
    return { status = "shown" }
end

function tools.console_hide(_)
    if not rconsolehide then return missing("rconsolehide") end
    rconsolehide()
    return { status = "hidden" }
end

function tools.console_print(params)
    local fn = (params.level == "warn" and rconsolewarn)
        or (params.level == "error" and rconsoleerr)
        or (params.level == "info"  and rconsoleinfo)
        or rconsoleprint
    if not fn then return missing("rconsoleprint") end
    fn(tostring(params.text))
    return { status = "printed" }
end

function tools.console_clear(_)
    if not rconsoleclear then return missing("rconsoleclear") end
    rconsoleclear()
    return { status = "cleared" }
end

function tools.console_title(params)
    if not rconsolename then return missing("rconsolename") end
    rconsolename(params.title)
    return { status = "set", title = params.title }
end

function tools.identify_executor(_)
    if not identifyexecutor then return missing("identifyexecutor") end
    local name, ver = identifyexecutor()
    return { name = name, version = ver }
end

function tools.get_hwid(_)
    if not gethwid then return missing("gethwid") end
    return { hwid = gethwid() }
end

function tools.get_fps_cap(_)
    if not getfpscap then return missing("getfpscap") end
    return { fps = getfpscap() }
end

function tools.set_fps_cap(params)
    if not setfpscap then return missing("setfpscap") end
    setfpscap(params.fps)
    return { fps = params.fps }
end

function tools.set_clipboard(params)
    if not setclipboard then return missing("setclipboard") end
    setclipboard(params.text)
    return { status = "copied", bytes = #(params.text or "") }
end

function tools.get_fflag(params)
    if not getfflag then return missing("getfflag") end
    local ok, v = pcall(getfflag, params.name)
    if not ok then return nil, tostring(v) end
    return { name = params.name, value = v }
end

function tools.set_fflag(params)
    if not setfflag then return missing("setfflag") end
    local ok, err = pcall(setfflag, params.name, tostring(params.value))
    if not ok then return nil, tostring(err) end
    return { name = params.name, value = tostring(params.value) }
end

function tools.message_box(params)
    if not messagebox then return missing("messagebox") end
    local result = messagebox(params.text or "", params.caption or "Roblox-Bridge", params.flags or 0)
    return { result = result }
end

function tools.queue_on_teleport(params)
    if not queueonteleport then return missing("queueonteleport") end
    local ok, err = pcall(queueonteleport, params.code)
    if not ok then return nil, tostring(err) end
    return { status = "queued" }
end

function tools.clear_teleport_queue(_)
    if not clearqueueonteleport then return missing("clearqueueonteleport") end
    clearqueueonteleport()
    return { status = "cleared" }
end

function tools.draw_create(params)
    if not Drawing then return missing("Drawing") end
    local ok, d = pcall(Drawing.new, params.type)
    if not ok then return nil, tostring(d) end
    if params.properties then
        for k, v in pairs(params.properties) do
            pcall(function() d[k] = v end)
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
    if not setrenderproperty then return missing("setrenderproperty") end
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
    if cleardrawcache then cleardrawcache() end
    state.drawings = {}
    return { status = "cleared" }
end

function tools.cache_invalidate(params)
    if not (cache and cache.invalidate) then return missing("cache.invalidate") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    cache.invalidate(inst)
    return { status = "invalidated", path = inst:GetFullName() }
end

function tools.cache_replace(params)
    if not (cache and cache.replace) then return missing("cache.replace") end
    local a, errA = resolvePath(params.path)
    if not a then return nil, errA end
    local b, errB = resolvePath(params.replacement)
    if not b then return nil, errB end
    cache.replace(a, b)
    return { status = "replaced", path = a:GetFullName(), replacement = b:GetFullName() }
end

function tools.cache_iscached(params)
    if not (cache and cache.iscached) then return missing("cache.iscached") end
    local inst, err = resolvePath(params.path)
    if not inst then return nil, err end
    return { cached = cache.iscached(inst) }
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
print(("[Claude Gateway] %d tools loaded"):format(#names))
print("[Claude Gateway] connecting to " .. HOST)

local announced = false
while true do
    local resp, err = post("/poll", {})
    if not resp then
        warn("[Claude Gateway] poll failed: " .. tostring(err) .. " (retrying in 2s)")
        wait_(2)
    else
        if not announced then
            announced = true
            print("[Claude Gateway] connected, awaiting commands...")
        end
        local body = readBody(resp)
        if body and #body > 0 then
            local decodeOk, cmd = pcall(jdec, body)
            if decodeOk and cmd and cmd.id and cmd.method then
                spawn_(handleCommand, cmd)
            else
                wait_(0.5)
            end
        else
            wait_(0.1)
        end
    end
end
