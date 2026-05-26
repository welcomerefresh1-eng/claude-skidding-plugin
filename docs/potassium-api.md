d# Potassium - Complete API Reference (entire.md)

> Compiled from <https://docs.potassium.pro/llms.txt> - every documented Potassium
> function, library, and Drawing object, with Lua signatures and example usage
> exactly as they appear in the upstream docs.
>
> Potassium follows the [UNC](https://github.com/unified-naming-convention/NamingStandard)
> standard. All code below assumes a Potassium-enabled Roblox executor environment.

## Table of Contents

- [Actor Library](#actor-library)
- [Closure Library](#closure-library)
- [Console Library](#console-library)
- [Crypt Library](#crypt-library)
- [Debug Library](#debug-library)
- [Drawing Library](#drawing-library)
- [DrawingImmediate Library](#drawingimmediate-library)
- [Environment Library](#environment-library)
- [FileSystem Library](#filesystem-library)
- [Input Library](#input-library)
- [Instance Library](#instance-library)
- [Metatable Library](#metatable-library)
- [Miscellaneous Library](#miscellaneous-library)
- [Oth Library (Off-Thread Hooks)](#oth-library-off-thread-hooks)
- [PsmSignal Library](#psmsignal-library)
- [RakNet Library](#raknet-library)
- [Reflection Library](#reflection-library)
- [Regex Library](#regex-library)
- [Script Library](#script-library)
- [Signal Library](#signal-library)
- [WebSocket Library](#websocket-library)
- [Drawing Objects](#drawing-objects)

---

# Actor Library

# create_comm_channel

> Returns an identifier and a `BindableEvent`. Used in one-way communication between actors.

```lua theme={null}
function create_comm_channel(): number, BindableEvent
```

### Example

```lua theme={null}
local id, channel = create_comm_channel()
channel.Event:Connect(function(data)
    print(data)
end)

run_on_actor(getactors()[1], [[
    local id = ...
    local channel = get_comm_channel(id)
    channel:Fire("Hello, World!")
]], id)
```

# get_comm_channel

> Returns a `BindableEvent`. Used in one-way communication between actors.

```lua theme={null}
function get_comm_channel(id: number): BindableEvent
```

<ResponseField name="id" type="number" required="True">
  The `id` used in obtaining the corresponding channel.
</ResponseField>

### Example

```lua theme={null}
local id, channel = create_comm_channel()
channel.Event:Connect(function(data)
    print(data)
end)

run_on_actor(getactors()[1], [[
    local id = ...
    local channel = get_comm_channel(id)
    channel:Fire("Hello, World!")
]], id)
```

# getactors

> Returns a table of `actor` (not including deleted ones). Some games delete their actors while they're running.

```lua theme={null}
function getactors(): {Actor}
```

<Tip>
  Alias: `get_actors`
</Tip>

### Example

This script will print every actor.

```lua theme={null}
for _, actor in getactors() do
    print(actor)
end
```

# getactorthreads

> Returns a table of every thread connected to every actor.

```lua theme={null}
function getactorthreads(): {thread}
```

<Tip>
  Alias: `get_actor_threads`
</Tip>

### Example

This script will print every actor thread.

```lua theme={null}
for _, actorThread in getactorthreads() do
    print(actorThread)
end
```

# getdeletedactors

> Returns a table of every deleted actor. Some games delete their actors while they're running.

```lua theme={null}
function getdeletedactors(): {Actor}
```

<Tip>
  Alias: `get_deleted_actors`
</Tip>

### Example

This script will print every deleted actor.

```lua theme={null}
for _, deletedActor in getdeletedactors() do
    print(deletedActor)
end
```

# is_parallel

> Returns a boolean indicating whether `is_parallel` was called in parallel.

```lua theme={null}
function is_parallel(): boolean
```

### Example

```lua theme={null}
print(is_parallel()) --> false

run_on_actor(getactors()[1], [[
    print(is_parallel())
]]) --> true
```

# run_on_actor

> Executes a script on an actor.

```lua theme={null}
function run_on_actor(actor: Actor, script: string, ...): ()
```

<ResponseField name="actor" type="Actor" required="True">
  The `actor` used in script execution.
</ResponseField>

<ResponseField name="script" type="string" required="True">
  The script to be executed on `actor`.
</ResponseField>

### Example

```lua theme={null}
run_on_actor(getactors()[1], [[
    print("Hello, world!")
]])
```

# run_on_thread

> Executes a script on an actor thread.

```lua theme={null}
function run_on_thread(thread: thread, script: string, ...): ()
```

<ParamField path="thread" type="thread" required>
  The thread to run the script on.
</ParamField>

<ParamField path="script" type="string" required>
  The script to be executed.
</ParamField>

### Example

```lua theme={null}
run_on_thread(getactorthreads()[1], [[
    print("Hello, world!")
]])
```


---

# Closure Library

# getfunctionhash

> Returns the hash of a lua function.

```lua theme={null}
function getfunctionhash(func: function): string
```

<ResponseField name="func" type="function" required="True">
  The `function` to hash.
</ResponseField>

### Example

This code sample will compare the hash of 2 basic lua functions.

```lua theme={null}
local function foo()
    print("Hello, world!")
end

local function bar(x, y)
    return x + y
end

local firstHash = getfunctionhash(foo)
local secondHash = getfunctionhash(bar)

print(firstHash == secondHash) --> false
```

# hookfunction

> Hooks a Lua or C function. Returns a copy of the original function.

```lua theme={null}
function hookfunction(target: function, hook: function): function
```

<ResponseField name="target" type="function" required="True">
  The `function` to hook.
</ResponseField>

<ResponseField name="hook" type="function" required="True">
  The `function` to call instead.
</ResponseField>

<Tip>
  Aliases: `hookfunc` `replaceclosure`
</Tip>

### Example

This example hooks the `print` function and replaces it with a warning if the content is "Hello, world!".

```lua theme={null}
local old = nil
old = hookfunction(print, function(...)
    if select(1, ...) == "Hello, world!" then
        return warn(...)
    end

    return old(...)
end)

print("Hello, world!") -- This will be a warning.
print("Goodbye, world!") -- This will be a print.
```

# iscclosure

> Returns a boolean indicating whether the function is a C closure.

```lua theme={null}
function iscclosure(func: function): boolean
```

<ResponseField name="func" type="function" required="True">
  The `function` to evaluate.
</ResponseField>

### Example

This code sample will print false on lua closures and true on C closures.

```lua theme={null}
local function foo()
    print("Hello, world!")
end

print(iscclosure(foo)) --> false
print(iscclosure(print)) --> true
```

# isexecutorclosure

> Returns a boolean indicating whether the function has been created by Potassium.

```lua theme={null}
function isexecutorclosure(func: function): boolean
```

<ResponseField name="func" type="function" required="True">
  The `function` to evaluate.
</ResponseField>

### Example

This code sample will print true if 'foo' was created by Potassium.

```lua theme={null}
local function foo()
    print("Hello, world!")
end

print(isexecutorclosure(foo)) --> true
print(isexecutorclosure(print)) --> false
```

# isfunctionhooked

> Returns a boolean indicating whether the function has been hooked.

```lua theme={null}
function isfunctionhooked(target: function): boolean
```

<ResponseField name="target" type="function" required="True">
  The `function` to evaluate.
</ResponseField>

### Example

This example will print true if 'foo' is hooked.

```lua theme={null}
local function foo()
    print("Hello, world!")
end

print("Before hooking:", isfunctionhooked(foo)) --> false

hookfunction(foo, function()
    print("Hello, new world!")
end)

print("After hooking:", isfunctionhooked(foo)) --> true

restorefunction(foo)
print("After restoring:", isfunctionhooked(foo)) --> false
```

# islclosure

> Returns a boolean indicating whether the function is a lua closure.

```lua theme={null}
function islclosure(func: function): boolean
```

<ResponseField name="func" type="function" required="True">
  The `function` to evaluate.
</ResponseField>

### Example

This code sample will print true on lua closures and false on C closures.

```lua theme={null}
local function foo()
    print("Hello, world!")
end

print(islclosure(foo)) --> true
print(islclosure(print)) --> false
```

# isnewcclosure

> Returns a boolean indicating whether the function has been created using `newcclosure`.

```lua theme={null}
function isnewcclosure(func: function): boolean
```

<ResponseField name="func" type="function" required="True">
  The `function` to evaluate.
</ResponseField>

### Example

This code sample will print true if 'foo' has been wrapped using newcclosure, false if otherwise.

```lua theme={null}
local function foo() end
print(isnewcclosure(foo)) --> false

local bar = newcclosure(foo)
print(isnewcclosure(bar)) --> true
```

# isourthread

> Returns a boolean indicating whether the thread is a Potassium thread.

```lua theme={null}
function isourthread(thread: thread): boolean
```

<ResponseField name="thread" type="thread" required="True">
  The `thread` to evaluate.
</ResponseField>

### Example

This code sample will iterate every thread, only printing the ones created by Potassium.

```lua theme={null}
for _, thread in getallthreads() do
    if isourthread(thread) then
        print(thread)
    end
end
```

# loadstring

> Creates a chunk from the provided source code. The environment of the returned function is the global environment. If there are no compilation errors, the chunk is returned by itself; otherwise, it returns nil and the error message.

```lua theme={null}
function loadstring(source: string, chunkname: string?): function?, string?
```

<ResponseField name="source" type="string" required="True">
  The `source` that will be used to create a chunk.
</ResponseField>

<ResponseField name="chunkname" type="string">
  `chunkname` will be used as the chunk name for error messages and debug information.
</ResponseField>

### Example

This code sample will create two chunks. Both will be called, one will error.

```lua theme={null}
local source = "print('Hello, world!')"
local chunk = loadstring(source, "hello")
chunk() --> Hello, world!

source = "error('Goodbye, world!')"
chunk = loadstring(source, "goodbye")
chunk() --> Error: Goodbye, world!
```

# newcclosure

> Creates a new C closure for 'func'.

```lua theme={null}
function newcclosure(func: function, name: string?): function
```

<ResponseField name="func" type="function" required="True">
  Creates a C function that wraps around 'func'
</ResponseField>

<ResponseField name="name" type="string">
  Set a name for the newly created C closure.
</ResponseField>

### Example

```lua theme={null}
local function foo()
    print("Hello, world!")
end

local newCClosure = newcclosure(foo, "bar")

newCClosure() --> Hello, world!
print(debug.info(newCClosure, "n")) --> bar
```

# newlclosure

> Creates a new Lua closure for 'func'.

```lua theme={null}
function newlclosure(func: function, name: string?): function
```

<ResponseField name="func" type="function" required="True">
  Creates a Lua function that wraps around 'func'
</ResponseField>

<ResponseField name="name" type="string">
  Set a name for the newly created L closure.
</ResponseField>

### Example

```lua theme={null}
print(islclosure(warn)) --> false

local luaClosure = newlclosure(warn)
print(islclosure(luaClosure)) --> true
```

# restorefunction

> Restores a previously hooked Lua or C function to its original implementation.

```lua theme={null}
function restorefunction(target: function): function
```

<ResponseField name="target" type="function" required="True">
  The `function` to restore.
</ResponseField>

### Example

This example hooks the `tick` function to print its return value and then restores it.

```lua theme={null}
local old = nil
old = hookfunction(tick, function(...)
    local result = old(...)

    print("Tick:", result)
    restorefunction(tick)

    return result
end)
```

# setstackhidden

> Hide a function from call-stack based detections.

```lua theme={null}
function setstackhidden(func: function | number, hidden: boolean): ()
```

<ResponseField name="func" type="function | number" required="True">
  The function or level that will be hidden.
</ResponseField>

<ResponseField name="hidden" type="boolean" required="True">
  Determines whether the function should be hidden or unhidden.
</ResponseField>

### Example

This code sample will hide 'bar' from 'debug.traceback'.

```lua theme={null}
local function foo()
   print(debug.traceback())
end

local function bar()
   foo()
end

bar() -- expected output

setstackhidden(bar, true)

bar() -- now hidden
```


---

# Console Library

# rconsoleclear

> Clears all text in the console.

```lua theme={null}
function rconsoleclear()
```

### Example

This script will both create a console and print a basic message, clearing it after.

```lua theme={null}
rconsolecreate()
rconsoleprint("Goodbye, world!\n")
task.wait(1)
rconsolewarn("Clearing console...")
task.wait(1)
rconsoleclear()
```

# rconsolecreate

> Creates a console window. Text previously output to the console will not be cleared. Only 1 console can be created.

```lua theme={null}
function rconsolecreate()
```

### Example

This script will create a console and print a basic message.

```lua theme={null}
rconsolecreate()
rconsoleprint("Hello, world!\n")
```

# rconsoledestroy

> Destroys the console window. Text output to the console will be cleared.

```lua theme={null}
function rconsoledestroy()
```

### Example

```lua theme={null}
rconsolecreate()
rconsoleprint("Hello, world!\n")

rconsoledestroy() -- Destroy console and clear old messages.

rconsolecreate()
rconsoleprint("Hello, world! Again!\n")
```

# rconsoleerror

> Prints a red message to the console. If the console hasn't been already created, `rconsoleerror` will create one.

```lua theme={null}
function rconsoleerror(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The text to be printed. Does not clear existing text or create a new line.
</ResponseField>

### Example

This script will both create a console and print a basic message.

```lua theme={null}
rconsoleerror("ERROR!\n")
```

# rconsoleinfo

> Prints a dark blue message to the console. If the console hasn't been already created, `rconsoleinfo` will create one.

```lua theme={null}
function rconsoleinfo(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The text to be printed. Does not clear existing text or create a new line.
</ResponseField>

### Example

This script will both create a console and print a basic message.

```lua theme={null}
rconsoleinfo("INFO!\n")
```

# rconsoleinput

> Receives input directly from the console. Any thread that runs this function will be suspended until input is received.

```lua theme={null}
function rconsoleinput(): string
```

### Example

This script will not finish (print) until input is properly received.

```lua theme={null}
rconsolecreate()
rconsoleprint("What's your name?\n")
local username = rconsoleinput()
print(username)
```

# rconsoleprint

> Prints to the console. If the console hasn't been already created, `rconsoleprint` will create one.

```lua theme={null}
function rconsoleprint(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The text to be printed. Does not clear existing text or create a new line.
</ResponseField>

### Example

This script will both create a console and print a basic message.

```lua theme={null}
rconsoleprint("Hello, world!\n")
```

# rconsolesettitle

> Sets the title of the console window.

```lua theme={null}
function rconsolesettitle(title: string): ()
```

<ResponseField name="title" type="string" required="True">
  The string that the title will be set to.
</ResponseField>

<Tip>
  Alias: `rconsolename`
</Tip>

### Example

This script will set the title of the console.

```lua theme={null}
rconsolecreate()
rconsolesettitle("Custom Title")
```

# rconsolewarn

> Prints a yellow message to the console. If the console hasn't been already created, `rconsolewarn` will create one.

```lua theme={null}
function rconsolewarn(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The text to be printed. Does not clear existing text or create a new line.
</ResponseField>

### Example

This script will both create a console and print a basic message.

```lua theme={null}
rconsolewarn("WARNING!\n")
```


---

# Crypt Library

# crypt.base64decode

> Returns a base64 decoded string.

```lua theme={null}
function crypt.base64decode(data: string): string
```

<ResponseField name="data" type="string" required="True">
  The data to be base64 decoded.
</ResponseField>

<Tip>
  Alias: `base64decode`
</Tip>

### Example

```lua theme={null}
local encodedData = "SGVsbG8sIHdvcmxkIQ=="
print(crypt.base64decode(encodedData))
```

# crypt.base64encode

> Returns a base64 encoded string.

```lua theme={null}
function crypt.base64encode(data: string): string
```

<ResponseField name="data" type="string" required="True">
  The data to be base64 encoded.
</ResponseField>

<Tip>
  Alias: `base64encode`
</Tip>

### Example

```lua theme={null}
local data = "Hello, world!"
local encoded = crypt.base64encode(data)
print(encoded)
```

# crypt.decrypt

> Decrypts provided data using AES encryption. Returns the decrypted data.

```lua theme={null}
function crypt.decrypt(data: string, key: string, iv: string, mode: string): string
```

<ResponseField name="data" type="string" required="True">
  User provided data.
</ResponseField>

<ResponseField name="key" type="string" required="True">
  Base64 encoded decryption key.
</ResponseField>

<ResponseField name="iv" type="string" required="True">
  Base64 encoded initialization vector.
</ResponseField>

<ResponseField name="mode" type="string">
  Decryption mode. Decrytion mode options: OFB, GCM, ECB, CTR, CFB, and CBC. Default option is "CBC".
</ResponseField>

### Example

```lua theme={null}
local username = game:GetService("Players").LocalPlayer.Character.Name
print("Username:", username)

local key = crypt.generatekey(16)
local data, iv = crypt.encrypt(username, key)

local decryptedData = crypt.decrypt(data, key, iv)
print("Decrypted result:", decryptedData)
```

# crypt.encrypt

> Encrypts provided data using AES encryption. Returns both the encrypted data and the initialization vector (iv).

```lua theme={null}
function crypt.encrypt(data: string, key: string, iv: string?, mode: string?): (string, string)
```

<ResponseField name="data" type="string" required="True">
  User provided data.
</ResponseField>

<ResponseField name="key" type="string" required="True">
  Base64 encoded encryption key.
</ResponseField>

<ResponseField name="iv" type="string">
  Base64 encoded initialization vector.
</ResponseField>

<ResponseField name="mode" type="string">
  Encryption mode. Encrytion mode options: OFB, GCM, ECB, CTR, CFB, and CBC. Default option is "CBC".
</ResponseField>

### Example

```lua theme={null}
local hwid = gethwid()
print("HWID:", hwid)

local key = crypt.generatekey(16)
print("Encryption key:", key)

local data, iv = crypt.encrypt(hwid, key)
print(data, iv)
```

# crypt.generatebytes

> Returns a string of randomly generated bytes. The result is base64 encoded.

```lua theme={null}
function crypt.generatebytes(amount: number): string
```

<ResponseField name="amount" type="number" required="True">
  The amount of random bytes to generate.
</ResponseField>

### Example

This script will print both the length of the random bytes generated, and the random bytes themselves.

```lua theme={null}
local randomBytes = base64decode(crypt.generatebytes(16))
print(#randomBytes, randomBytes)
```

# crypt.generatekey

> Generates and returns a random key. Frequently used in combination with with `crypt.encrypt` and `crypt.decrypt`.

```lua theme={null}
function crypt.generatekey(keylength: number?): string
```

<ResponseField name="keylength" type="number">
  Length of the random key to generate. Default is 32 bytes in length.
</ResponseField>

### Example

```lua theme={null}
local username = game:GetService("Players").LocalPlayer.Character.Name
print("Username:", username)

local key = crypt.generatekey()
print("Encryption key:", key)

local data, iv = crypt.encrypt(username, key)
print("Encrypted username:", data)
```

# crypt.hash

> Hashes and returns user provided data using the specified hashing algorithm.

```lua theme={null}
function crypt.hash(data: string, algorithm: string): string
```

<ResponseField name="data" type="string" required="True">
  User provided data.
</ResponseField>

<ResponseField name="algorithm" type="string" required="True">
  The specified hashing algorithm. Algorithms include: "md5", "sha256", "sha1", "sha384", "sha512", "sha3-224", "sha3-256", "sha3-384", "sha3-512", "sha224".
</ResponseField>

### Example

```lua theme={null}
local data = game:GetService("Players").LocalPlayer.Character.Name
print("Username:", data)

local hashAlgorithmList = {
    "md5", 
    "sha256", 
    "sha1", 
    "sha384", 
    "sha512", 
    "sha3-224", 
    "sha3-256",
    "sha3-384", 
    "sha3-512", 
    "sha224"
}

for _, algorithm in hashAlgorithmList do
    print(algorithm .. ":", crypt.hash(data, algorithm))
end
```

# crypt.hmac

> Generates and returns an HMAC (Hash-based Message Authentication Code). Frequently used in message authentication (see example below).

```lua theme={null}
function crypt.hmac(key: string, data: string, algorithm: string): string
```

<ResponseField name="key" type="string" required="True">
  The secret key.
</ResponseField>

<ResponseField name="data" type="string" required="True">
  User provided data.
</ResponseField>

<ResponseField name="algorithm" type="string" required="True">
  The specified hashing algorithm. Algorithms include: "md5", "sha1", "sha224", "sha256", "sha384", "sha512", "sha3-224", "sha3\_224", "sha3-256", "sha3\_256", "sha3-384", "sha3\_384", "sha3-512", and "sha3\_512".
</ResponseField>

### Example

```lua theme={null}
local data = game:GetService("Players").LocalPlayer.Character.Name
print("Username:", data)

local hashAlgorithmList = {
    "md5",
    "sha1",
    "sha224",
    "sha256",
    "sha384",
    "sha512",
    "sha3-224",
    "sha3_224",
    "sha3-256",
    "sha3_256",
    "sha3-384",
    "sha3_384",
    "sha3-512",
    "sha3_512"
}

for _, algorithm in hashAlgorithmList do
    print(algorithm .. ":", crypt.hmac(crypt.generatebytes(16), data, algorithm))
end
```

# crypt.lz4compress

> Returns a compressed string using the LZ4 algorithm.

```lua theme={null}
function crypt.lz4compress(data: string): string
```

<ResponseField name="data" type="string" required="True">
  The user specified data.
</ResponseField>

<Tip>
  Alias: `lz4compress`
</Tip>

### Example

```lua theme={null}
local data = "Hello, world!"
local compressed = crypt.lz4compress(data)
print(compressed)
```

# crypt.lz4decompress

> Returns a decompressed string using the LZ4 algorithm.

```lua theme={null}
function crypt.lz4decompress(data: string, originallength: number): string
```

<ResponseField name="data" type="string" required="True">
  The user specified data.
</ResponseField>

<ResponseField name="originallength" type="number" required="True">
  The length of the original (non lz4 compressed) string.
</ResponseField>

<Tip>
  Alias: `lz4decompress`
</Tip>

### Example

```lua theme={null}
local data = "Hello, world!"
local compressed = crypt.lz4compress(data)

local decompressed = crypt.lz4decompress(compressed, #data)
print(decompressed)
```

# crypt.random

> Returns a string of randomly generated bytes. The result is not base64 encoded.

```lua theme={null}
function crypt.random(amount: number): string
```

<ResponseField name="amount" type="number" required="True">
  The amount of random bytes to generate.
</ResponseField>

### Example

This script will print both the length of the random bytes generated, and the random bytes themselves.

```lua theme={null}
local randomBytes = base64decode(crypt.random(16))
print(#randomBytes, randomBytes)
```


---

# Debug Library

# debug.getcallstack

> Returns a table of the entire stack's information. Table array fields: source (definition), line (start line), what ("Lua", "C"), name, func.

```lua theme={null}
function debug.getcallstack(offset: number): table
```

<ResponseField name="offset" type="number">
  The offset you want the callstack table to begin at.
</ResponseField>

<Tip>
  Alias: `getcallstack`
</Tip>

### Example

```lua theme={null}
local function foo()
    local callStack = debug.getcallstack()

    print("Number of calls:", #callStack) --> 3
    print("Name of caller:", callStack[2].name) --> bar
end

local function bar()
    foo()
end

bar()
```

# debug.getconstant

> Returns a singular constant that's derived from a function. Selected via index.

```lua theme={null}
function debug.getconstant(function: function | number, index: number): any
```

<ResponseField name="function" type="function | number" required="True">
  The function whose constant is returned.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The index of the constant to return.
</ResponseField>

<Tip>
  Alias: `getconstant`
</Tip>

### Example

```lua theme={null}
function foo()
    return 123
end

local constant = debug.getconstant(foo, 1)
print(constant) --> 123
```

# debug.getconstants

> Returns a table of constants that's derived from a function.

```lua theme={null}
function debug.getconstants(function: function | number): { any? }
```

<ResponseField name="function" type="function | number" required="True">
  The function whose constants are returned.
</ResponseField>

<Tip>
  Alias: `getconstants`
</Tip>

### Example

```lua theme={null}
function foo()
    return 123
end

local constantTable = debug.getconstants(foo)
for index, constant in constantTable do
    print(index, constant)
end
```

# debug.getinfo

> Returns a table of information that's derived from a function or stack level.
Table fields: source (definition), short_src (truncated), linedefined (start line),
what ("Lua", "C", "main"), name, namewhat (scope), nups (upvalue count),
and func (function itself).


```lua theme={null}
function debug.getinfo(function: function | number, what: string): table
```

<ResponseField name="function" type="function | number" required="True">
  The function or stack level whose information is collected and returned.
</ResponseField>

<ResponseField name="what" type="string">
  Used to specify what information is returned in the table. Options include: "n" for name and namewhat, "s" for source and line details, "l" for currentline, and "f" for the function itself.
</ResponseField>

<Tip>
  Alias: `getinfo`
</Tip>

### Example

```lua theme={null}
function foo()
    return "Hello, world!"
end

local functionInfo = debug.getinfo(foo)
for i, v in functionInfo do
    print(i, v)
end
```

# debug.getproto

> Gets a cloned proto inside the 'func' unless the 'active' is specified which returns a table of all active protos.

```lua theme={null}
function debug.getproto(function: function | number, index: number, active: boolean?): function | {function}
```

<ResponseField name="function" type="function | number" required="True">
  The function or level you want to get the proto from.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The indice for the proto.
</ResponseField>

<ResponseField name="active" type="number">
  Return actively used protos instead of cloned ones.
</ResponseField>

<Tip>
  Alias: `getproto`
</Tip>

### Example

```lua theme={null}
local function foo()
   local function bar()
      print("foo's inner proto bar!")
   end
end

local bar = debug.getproto(foo, 1, true)[1]
bar() --> foo's inner proto bar!
```

# debug.getprotos

> Return a list of all cloned protos.

```lua theme={null}
function debug.getprotos(function: function | number): {function}
```

<ResponseField name="function" type="function | number" required="True">
  The function or level you want to get the protos from.
</ResponseField>

<Info>
  debug.getprotos return cloned protos which are unable to be called but can be interacted with other debug functions such as getconstant or getinfo. Consider using 'debug.getproto' with the 'active' argument set to true if you want active protos you can interact with.
</Info>

<Tip>
  Alias: `getprotos`
</Tip>

### Example

```lua theme={null}
local function foo()
   local function bar()
      print("foo's inner proto bar!")
   end
end

print(debug.info(debug.getprotos(foo)[1], "n")) --> bar
```

# debug.getregistry

> Returns the global registry table. The registry is used to store references. Any object referenced in the registry will never be collected by the garbage collector, as the registry itself will never be collected. Thus a strong reference will always be held.

```lua theme={null}
function debug.getregistry(): { [any]: any }
```

<Tip>
  Alias: `getregistry`
</Tip>

### Example

This script will print every object that's stored in the registry.

```lua theme={null}
local registry = debug.getregistry()
for i, v in registry do
    print(i, v)
end
```

# debug.getsafeenv

> Returns the safeenv flag.

```lua theme={null}
function debug.getsafeenv(object: function | table | thread)
```

<ResponseField name="object" type="function | table | thread" required="True">
  The object you would like to get the safeenv of.
</ResponseField>

<Tip>
  Alias: `debug.isuntouched`
</Tip>

### Example

All executed scripts are marked with safeenv as false for compatibility.

```lua theme={null}
print(debug.getsafeenv()) --> false
debug.setsafeenv(true)
print(debug.getsafeenv()) --> true

-- Since we are breaking safeenv protections by
-- replacing a global function with getfenv, safeenv
-- becomes false. Also applicable to setfenv.
getfenv().warn = function() end
print(debug.getsafeenv()) --> false
```

# debug.getstack

> Returns a table (of the stack) or a singular object from the stack. Only returns objects that are currently on the stack.

```lua theme={null}
function debug.getstack(level: number, index: number?): ( any | { any } )
```

<ResponseField name="level" type="number" required="True">
  The stack level at which the objects are collected.
</ResponseField>

<ResponseField name="index" type="number">
  The index of a specific object on the stack to return. If omitted, the entire stack at the given level is returned as a table.
</ResponseField>

<Tip>
  Alias: `getstack`
</Tip>

### Example debug.getstack returning a table.

This code sample will print all of the objects on the calling function's stack.

```lua theme={null}
-- Imagine this is a hook of some kind.
function foo(vec3)
    local stack = debug.getstack(2)
    for i, v in stack do
        print(i, v)
    end
end

local function bar()
    local vec3 = Vector3.new()

    foo(vec3)

    return vec3
end

bar()
```

### Example debug.getstack returning a singluar object.

This code sample will print a single object that's on the calling function's stack.

```lua theme={null}
-- Imagine this is a hook of some kind.
function foo(vec3)
    local object = debug.getstack(2, 3)
    print(object)
end

local function bar()
    local vec3 = Vector3.new()

    foo(vec3)

    return vec3
end

bar()
```

# debug.getupvalue

> Returns a singular upvalue that's derived from a function's upvalue list. Selected via index.

```lua theme={null}
function debug.getupvalue(function: function | number, index: number): any
```

<ResponseField name="function" type="function | number" required="True">
  The function whose upvalue is returned.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The index of the upvalue to return.
</ResponseField>

<Tip>
  Alias: `getupvalue`
</Tip>

### Example

This code sample will print an upvalue from the function's upvalue list.

```lua theme={null}
local bar = "Hello, World!"
function foo()
    print(bar)
end

local upvalue = debug.getupvalue(foo, 1)
print(upvalue)
```

# debug.getupvalues

> Returns a table of upvalues from a function's upvalue's list.

```lua theme={null}
function debug.getupvalues(function: function | number): { any }
```

<ResponseField name="function" type="function | number" required="True">
  The function whose upvalues are returned. Stack levels are also supported.
</ResponseField>

<Tip>
  Alias: `getupvalues`
</Tip>

### Example

This code sample will print every upvalue the function's upvalue list.

```lua theme={null}
local upvalue = "Hello, World!"
function foo()
    print(upvalue)
end

local upvalues = debug.getupvalues(foo)
for i, v in upvalues do
    print(i, v)
end
```

# debug.isvalidlevel

> Checks if 'level' is valid in the stack

```lua theme={null}
function debug.isvalidlevel(level: number)
```

<ResponseField name="level" type="number" required="True">
  The level you want to check.
</ResponseField>

<Tip>
  Alias: `debug.validlevel`
</Tip>

### Example

```lua theme={null}
local function a()
  print(debug.isvalidlevel(3))
end

a() --> false
newlclosure(a)() --> true
```

# debug.setconstant

> Sets a singular constant that's derived from a function. Selected via index.

```lua theme={null}
function debug.setconstant(function: function | number, index: number, replacement: any): ()
```

<ResponseField name="function" type="function | number" required="True">
  The function whose constant is set.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The index of the constant to set.
</ResponseField>

<ResponseField name="replacement" type="any" required="True">
  The replacement object. Must be of the same type.
</ResponseField>

<Tip>
  Alias: `setconstant`
</Tip>

### Example

```lua theme={null}
function foo()
    return 696969420
end

debug.setconstant(foo, 1, 0)

print(foo())
```

# debug.setinfo

> Sets the debug info around the 'func'.

```lua theme={null}
function debug.setinfo(func: function, info: table): ()
```

<ResponseField name="func" type="function" required="True">
  The function you would like to change the info of
</ResponseField>

<ResponseField name="info" type="table" required="True">
  The info you would like to change. (name, source, short\_src, currentline)
</ResponseField>

<Tip>
  Alias: `setinfo`
</Tip>

### Example

```lua theme={null}
local foo = function()
  print(debug.traceback())
end

foo() --> Original info

debug.setinfo(foo, {
  name = "bar",
  source = "bar",
  short_src = "bar",
  currentline = 123
})

foo() --> Spoofed one
```

# debug.setname

> Changes the function name specified to the set one.

```lua theme={null}
function debug.setname(function: function | number, name: string): ()
```

<ResponseField name="function" type="function | number" required="True">
  The function to set the name of.
</ResponseField>

<ResponseField name="name" type="number" required="True">
  The name you want to set the function to.
</ResponseField>

<Tip>
  Alias: `setname`
</Tip>

### Example

```lua theme={null}
local function foo()
  print("name", debug.info(1, "n"))
end

foo() -- name foo
debug.setname(foo, "bar")
foo() -- name bar
```

# debug.setsafeenv

> Marks the safeenv for an object.

```lua theme={null}
function debug.setsafeenv(func: function | table | thread | boolean, safe: boolean?)
```

<ResponseField name="object" type="function | table | thread | boolean" required="True">
  The object you would like to set the safeenv of. (If a boolean is provided it will set the current state's safeenv)
</ResponseField>

<ResponseField name="safe" type="boolean">
  What to set the safeenv of the 'func'.
</ResponseField>

<Tip>
  Alias: `debug.setuntouched`
</Tip>

### Example

Potassium marks safeenv to false in all executed scripts for compatibility.

```lua theme={null}
print(debug.getsafeenv()) --> false
debug.setsafeenv(true)
print(debug.getsafeenv()) --> true

-- Since we are breaking safeenv protections by
-- replacing a global function with getfenv, safeenv
-- becomes false. Also applicable to setfenv.
getfenv().warn = function() end
print(debug.getsafeenv()) --> false
```

# debug.setstack

> Sets a singular object from the stack.

```lua theme={null}
function debug.setstack(level: number, index: number, replacement: any): ()
```

<ResponseField name="level" type="number" required="True">
  The stack level of the function whose stack object is set.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The index of the stack object to set.
</ResponseField>

<ResponseField name="replacement" type="any" required="True">
  The replacement object. Must be of the same type.
</ResponseField>

<Tip>
  Alias: `setstack`
</Tip>

### Example

This code sample will set a single object that's on the calling function's stack.

```lua theme={null}
-- Imagine this is a hook of some kind.
function foo(vec3)
    local replacement = Vector3.new(100, 100, 100)
    debug.setstack(2, 1, replacement)
end

local function bar()
    local vec3 = Vector3.new()

    foo(vec3)

    return vec3
end

print(bar())
```

# debug.setupvalue

> Sets a singular upvalue that's derived from a function's upvalue list. Selected via index.

```lua theme={null}
function debug.setupvalue(function: function | number, index: number, replacement: any): ()
```

<ResponseField name="function" type="function | number" required="True">
  The function whose upvalue is set.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The index of the upvalue to set.
</ResponseField>

<ResponseField name="replacement" type="any" required="True">
  The replacement object. Must be of the same type.
</ResponseField>

<Tip>
  Alias: `setupvalue`
</Tip>

### Example

This script will set a function's upvalue.

```lua theme={null}
local upvalue = 0

local function foo()
    return upvalue
end

local function bar()
    upvalue += 1
end

print(foo())

debug.setupvalue(foo, 1, 10000)

print(foo())
```


---

# Drawing Library

# Base

### Base

| Property     | Type      | Default             |
| ------------ | --------- | ------------------- |
| Visible      | `boolean` | false               |
| ZIndex       | `number`  | 1                   |
| Transparency | `number`  | 1                   |
| Color        | `Color3`  | Color3.new(0, 0, 0) |

### Methods

| Method          | Description                   |
| --------------- | ----------------------------- |
| `Destroy(): ()` | Destroys the `DrawingObject`. |
| `Remove(): ()`  | Destroys the `DrawingObject`. |

# Drawing.new

> Create a new drawing object of the specified type.

```lua theme={null}
function Drawing.new(type: string): DrawingObject
```

<ResponseField name="type" type="string" required="True">
  The type of drawing object to create.
</ResponseField>

### Types

| Type                  | Description                           |
| --------------------- | ------------------------------------- |
| [Line](/line)         | A line between two points.            |
| [Text](/text)         | Rendered text.                        |
| [Image](/image)       | An image from a URL or file.          |
| [Circle](/circle)     | A circle shape.                       |
| [Square](/square)     | A square shape.                       |
| [Triangle](/triangle) | A triangle shape with three vertices. |
| [Quad](/quad)         | A quadrilateral with four vertices.   |
| [Font](/font)         | A font with data from a URL or file.  |
| [Shader](/shader)     | A HLSL shader.                        |

### Example

This script will make a red `Circle` and remove it.

```lua theme={null}
local circle = Drawing.new("Circle")
circle.Radius = 50
circle.Color = Color3.fromRGB(255, 0, 0)
circle.Filled = true
circle.NumSides = 32
circle.Position = Vector2.new(300, 300)
circle.Transparency = 0.7
circle.Visible = true

task.wait(1)
circle:Destroy()
```

# Drawing.Fonts

| Index       | Value |
| ----------- | ----- |
| `UI`        | 0     |
| `System`    | 1     |
| `Plex`      | 2     |
| `Monospace` | 3     |

# cleardrawcache

> Removes all rendered drawing objects from the cache.

```lua theme={null}
function cleardrawcache(): ()
```

### Example

This example draws a bunch of `Circle` objects and utilzies `cleardrawcache` to clear them all from the cache at once.

```lua theme={null}
for i = 1, 10 do
    local circle = Drawing.new("Circle")
    circle.Radius = 50
    circle.Color = Color3.fromRGB(255, 0, 0)
    circle.Filled = true
    circle.NumSides = 32
    circle.Position = Vector2.new(100 * i, 100)
    circle.Transparency = 0.7
    circle.Visible = true
end

task.wait(1)

cleardrawcache()
```

# getrenderproperty

> Gets a property value from a `DrawingObject`.

```lua theme={null}
function getrenderproperty(drawing: DrawingObject, property: string): any
```

<ResponseField name="drawing" type="DrawingObject" required="True">
  The drawing object to retrieve the property from.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The property to retrieve.
</ResponseField>

### Example

This script will make a print the default radius for a `Circle`.

```lua theme={null}
local circle = Drawing.new("Circle")

print("Radius:", getrenderproperty(circle, "Radius"))
```

# setrenderproperty

> Sets a property value on a `DrawingObject`.

```lua theme={null}
function setrenderproperty(drawing: DrawingObject, property: string, value: any): ()
```

<ResponseField name="drawing" type="DrawingObject" required="True">
  The drawing object to edit the property on.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The property to edit.
</ResponseField>

<ResponseField name="value" type="any" required="False">
  The value to set.
</ResponseField>

### Example

This script will make a red `Circle` and remove it.

```lua theme={null}
local circle = Drawing.new("Circle")

setrenderproperty(circle, "Radius", 50)
setrenderproperty(circle, "Position", Vector2.new(300, 300))
setrenderproperty(circle, "NumSides", 32)
setrenderproperty(circle, "Color", Color3.fromRGB(255, 0, 0))
setrenderproperty(circle, "Transparency", 1)
setrenderproperty(circle, "Visible", true)
setrenderproperty(circle, "Filled", true)
setrenderproperty(circle, "Thickness", 2)
setrenderproperty(circle, "ZIndex", 1)

task.wait(1)
circle:Destroy()
```

# isrenderobj

> Returns a boolean indicating whether the object is a `DrawingObject`.

```lua theme={null}
function isrenderobj(object: DrawingObject): boolean
```

<ResponseField name="object" type="DrawingObject" required="True">
  The `DrawingObject` to evaluate.
</ResponseField>

### Example

This code sample will print true on a `Circle` and false on an `Instance`.

```lua theme={null}
local circle = Drawing.new("Circle")
local part = Instance.new("Part")

print(isrenderobj(circle))
print(isrenderobj(part))
```


---

# DrawingImmediate Library

# DrawingImmediate.GetPaint

> Returns an event that is fired every render step for a specific `zindex`. Lower value `zindex` events will fire before higher value events. DrawingImmediate.* APIs can only be called under these events.

```lua theme={null}
function DrawingImmediate.GetPaint(zindex: int): PsmSignal
```

<ResponseField name="zindex" type="int" required="False">
  The zindex that the event will fire on.
</ResponseField>

### Example

This script utilizes the `DrawingImmediate` library to continuously render a circle at the current mouse position. Useful for an FOV circle.

```lua theme={null}
local signal = DrawingImmediate.GetPaint(1)
local uis = game:GetService("UserInputService")

signal:Connect(function()
    local mousepos = uis:GetMouseLocation()

    DrawingImmediate.Circle(mousepos, 100, Color3.new(1, 1, 1), 1, 100, 1)
end)
```

# Functions

### Line

*Renders a line between two specified points.*

```lua theme={null}
function DrawingImmediate.Line(from: Vector2, to: Vector2, color: Color3, opacity: number, thickness: number): ()
```

### Circle

*Renders a circle at one specified point.*

```lua theme={null}
function DrawingImmediate.Circle(center: Vector2, radius: number, color: Color3, opacity: number, num_sides: int, thickness: number): ()
```

### FilledCircle

*Renders a filled circle at one specified point.*

```lua theme={null}
function DrawingImmediate.FilledCircle(center: Vector2, radius: number, color: Color3, num_sides: int, opacity: number): ()
```

### Triangle

*Renders a triangle between three specified points.*

```lua theme={null}
function DrawingImmediate.Triangle(point_a: Vector2, point_b: Vector2, point_c: Vector2, color: Color3, opacity: number, thickness: number): ()
```

### FilledTriangle

*Renders a filled triangle between three specified points.*

```lua theme={null}
function DrawingImmediate.FilledTriangle(point_a: Vector2, point_b: Vector2, point_c: Vector2, color: Color3, opacity: number): ()
```

### Rectangle

*Renders a rectangle at one specified point.*

```lua theme={null}
function DrawingImmediate.Rectangle(top_left: Vector2, size: Vector2, color: Color3, opacity: number, rounding: number, thickness: number): ()
```

### FilledRectangle

*Renders a filled rectangle at one specified point.*

```lua theme={null}
function DrawingImmediate.FilledRectangle(top_left: Vector2, size: Vector2, color: Color3, opacity: number, rounding: number): ()
```

### Quad

*Renders a quad between four specified points.*

```lua theme={null}
function DrawingImmediate.Quad(point_a: Vector2, point_b: Vector2, point_c: Vector2, point_d: Vector2, color: Color3, opacity: number, thickness: number): ()
```

### FilledQuad

*Renders a filled quad between four specified points.*

```lua theme={null}
function DrawingImmediate.FilledQuad(point_a: Vector2, point_b: Vector2, point_c: Vector2, point_d: Vector2, color: Color3, opacity: number): ()
```

### Text

*Renders text at a specified point.*

```lua theme={null}
function DrawingImmediate.Text(position: Vector2, font: number, font_size: number, color: Color3, opacity: number, text: string, center: bool): ()
```

### OutlinedText

*Renders outlined text at a specified point.*

```lua theme={null}
function DrawingImmediate.OutlinedText(position: Vector2, font: number, font_size: number, color: Color3, opacity: number, outline_color: Color3, outline_opacity: number, text: string, center: bool): ()
```


---

# Environment Library

# filtergc

> Returns a table of objects filtered from the garbage collection list. If specified, a single object can also be filtered and returned instead.

```lua theme={null}
function filtergc(filterType: string, filterOptions: table, filterOne: boolean): {any} | any?
```

<ResponseField name="filterType" type="string" required>
  The specific type to filter for. "function" or "table" are the only accepted strings. Each filter type has it's own filter options.
</ResponseField>

<ResponseField name="filterOptions" type="table" required>
  Filter options. See corresponding usage in example below.
</ResponseField>

<ResponseField name="filterOne" type="boolean">
  Boolean indicating whether to return a singular object.
</ResponseField>

## Function filter options

| Field          | Type    | Description                                    |
| -------------- | ------- | ---------------------------------------------- |
| IgnoreExecutor | boolean | Whether to ignore executor-created functions.  |
| Name           | string  | The name of the function.                      |
| Hash           | string  | The function hash.                             |
| Environment    | table   | The environment table to match.                |
| StartLine      | number  | The line number of the function.               |
| Constants      | table   | A list of constants the function must contain. |
| Upvalues       | table   | A list of upvalues the function must contain.  |

## Table filter options

| Field         | Type  | Description                                           |
| ------------- | ----- | ----------------------------------------------------- |
| Keys          | table | A list of keys the table must contain.                |
| Values        | table | A list of values the table must contain.              |
| KeyValuePairs | table | A dictionary of key-value pairs the table must match. |
| Metatable     | table | The metatable the table must have.                    |

### Example function filter

```lua theme={null}
local function exampleFunction()
    return "Hello, world!"
end

local filterOptions = {
    IgnoreExecutor = false,
    Name = "exampleFunction"
}

local result = filtergc("function", filterOptions, true)
print(exampleFunction == found) --> true
print(result()) --> Hello, world!
```

### Example table filter

```lua theme={null}
local myTable = {
    ["myKey"] = 123456
}

local filterOptions = {
    Keys = { "myKey" }
}

local found = filtergc("table", filterOptions, true)
print(found == myTable) --> true
print(found.myKey) --> 123456
```

# getgc

> Returns a table of objects from the garbage collection list. If specified, tables will be included.

```lua theme={null}
function getgc(includeTables: boolean?): {any}
```

<ResponseField name="includeTables" type="boolean">
  If true, all tables will be included.
</ResponseField>

### Example

This script will print every potassium-created function in the garbage collection list.

```lua theme={null}
for _, object in getgc() do
    if type(object) == "function" and isexecutorclosure(object) then
        print(object)
    end
end
```

# getgenv

> Returns the global environment table, which is shared across all potassium-made threads. This table is commonly used to share or store information between different potassium-executed scripts.

```lua theme={null}
function getgenv(): { any }
```

### Example

```lua theme={null}
local alreadyRan = getgenv().alreadyRan

if alreadyRan then
    print("Already ran!")
else
    print("Hello, world!")
    getgenv().alreadyRan = true
end
```

# getreg

> Returns the global registry table. The registry is used to store references. Any object referenced in the registry will never be collected by the garbage collector, as the registry itself will never be collected. Thus a strong reference will always be held.

```lua theme={null}
function getreg(): { [any]: any }
```

### Example function filter

```lua theme={null}
local registry = getreg()
for i, v in registry do
    print(i, v)
end
```

# getrenv

> Returns the roblox's global environment table, which is inherited by all threads.

```lua theme={null}
function getrenv(): { any }
```

### Example

This script will print every module required (after execution).

```lua theme={null}
local old = nil
old = hookfunction(getrenv().require, function(...)
    print(...)
    return old(...)
end)
```

# getsenv

> Returns the global environment table of a `Script`, `LocalScript`, or `ModuleScript`.

```lua theme={null}
function getsenv(script: Script): { [any]: any }?
```

<ResponseField name="script" type="Script" required="True">
  Can be a `LocalScript`, `ModuleScript` or a `Script` (if it's `RunContext` is `Client`). The script must be running.
</ResponseField>

### Example function filter

This script will print the environment of an arbitrary script.

```lua theme={null}
local script = getrunningscripts()[1]
table.foreach(getsenv(script), print)
```

# gettenv

> Returns a thread's environment table.

```lua theme={null}
function gettenv(thread: thread?): { any }
```

<ResponseField name="thread" type="thread">
  The thread that will be used. If not specified, it will default to the current thread.
</ResponseField>

### Example

This script will print everything inside of a thread's environment.

```lua theme={null}
local thread = coroutine.create(function() end)
table.foreach(gettenv(thread), print)
```


---

# FileSystem Library

# readfile

> Read an existing file from the 'workspace' directory.

```lua theme={null}
function readfile(file: string): string
```

<ResponseField name="file" type="string" required="True">
  The path to the file you're looking to read.
</ResponseField>

### Example

```lua theme={null}
print("Contents of 'test.txt'", readfile("test.txt"))
```

# writefile

> Write a file to the 'workspace' directory.

```lua theme={null}
function writefile(file: string, contents: string): ()
```

<ResponseField name="file" type="string" required="True">
  The path to the file you're wanting to write to.
</ResponseField>

<ResponseField name="contents" type="string" required="True">
  The contents you want the file to contain.
</ResponseField>

### Example

```lua theme={null}
writefile("test.txt", tostring(workspace:GetServerTimeNow()))
```

# appendfile

> Append an already existing file's contents from workspace.

```lua theme={null}
function appendfile(file: string, contents: string): ()
```

<ResponseField name="file" type="string" required="True">
  The path to the file you're looking to append.
</ResponseField>

<ResponseField name="contents" type="string" required="True">
  The contents you want to append the existing file.
</ResponseField>

### Example

```lua theme={null}
appendfile("test.txt", "\n" .. workspace:GetServerTimeNow())
```

# delfile

> Deletes the file from the specified 'path'.

```lua theme={null}
function delfile(file: string): ()
```

<ResponseField name="file" type="string" required="True">
  The file's path.
</ResponseField>

### Example

```lua theme={null}
delfile("test.txt")
```

# isfile

> Checks if specified 'path' is a file.

```lua theme={null}
function isfile(path: string): boolean
```

<ResponseField name="path" type="string" required="True">
  The path to the potentional file
</ResponseField>

### Example

```lua theme={null}
writefile("test", "hello!")
print(isfile("test")) -- true
```

# loadfile

> Loadstring's the file specified and returning its chunk

```lua theme={null}
function loadfile(file: string, chunkname: string): (function?, string?)
```

<ResponseField name="file" type="string" required="True">
  The path to the file you're looking to load code from.
</ResponseField>

<ResponseField name="chunkname" type="string">
  The chunk string you want to have.
</ResponseField>

### Example

```lua theme={null}
local chunk, error = loadfile("test.txt")
if error then
    print("Code failed to compile, error:", error)
    return
end

chunk()
```

# dofile

> Attemps to execute contents from 'file'.

```lua theme={null}
function dofile(file: string): ()
```

<ResponseField name="file" type="string" required="True">
  The path to the file you're looking to load code from.
</ResponseField>

### Example

```lua theme={null}
dofile("test.txt") -- Directly executes
```

# listfiles

> Returns an array with the list of files in the specified directory.

```lua theme={null}
function listfiles(path: string): {string}
```

<ResponseField name="path" type="string" required="True">
  The path you want to list files from.
</ResponseField>

### Example

```lua theme={null}
for index, file in listfiles("") do -- list files from workspace root
  print(index, file)
end
```

# makefolder

> Creates a folder in the specified 'path'.

```lua theme={null}
function makefolder(path: string): ()
```

<ResponseField name="path" type="string" required="True">
  The path you want to create a folder with
</ResponseField>

### Example

```lua theme={null}
print(makefolder("mk"))
```

# isfolder

> Checks if specified 'path' is a folder.

```lua theme={null}
function isfolder(path: string): boolean
```

<ResponseField name="path" type="string" required="True">
  The path you want to check
</ResponseField>

### Example

```lua theme={null}
writefile("test", "hello!")
print(isfolder("test")) --> false
```

# delfolder

> Deletes the folder from the specified 'path'.

```lua theme={null}
function delfolder(path: string): ()
```

<ResponseField name="path" type="string" required="True">
  The path to the folder you want to delete
</ResponseField>

### Example

```lua theme={null}
delfolder("mk")
```


---

# Input Library

# isrbxactive

> Returns a boolean indicating whether roblox is currently in focus.

```lua theme={null}
function isrbxactive(): boolean
```

<Tip>
  Aliases: `isgameactive` `iswindowactive`
</Tip>

### Example

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

local isactive = isrbxactive()
print("isactive: ", isactive)
```

# keypress

> Simulate a key being pressed. The key press will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function keypress(keycode: number)
```

<ResponseField name="keycode" type="number" required="True">
  The keycode to press. The only accepted keycodes are Window's Virtual-Key codes.
</ResponseField>

### Example

This script will press and release the 'H' key.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

local H_KEYCODE = 0x48

keypress(H_KEYCODE)
task.wait()
keyrelease(H_KEYCODE)
```

# keyrelease

> Simulate a key being released. The key release will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function keyrelease(keycode: number)
```

<ResponseField name="keycode" type="number" required="True">
  The keycode to release. The only accepted keycodes are Window's Virtual-Key codes.
</ResponseField>

### Example

This script will press and release the 'H' key.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

local H_KEYCODE = 0x48

keypress(H_KEYCODE)
task.wait()
keyrelease(H_KEYCODE)
```

# keytap

> Simulate a key being pressed and released. The key tap will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function keytap(keycode: number)
```

<ResponseField name="keycode" type="number" required="True">
  The keycode to tap. The only accepted keycodes are Window's Virtual-Key codes.
</ResponseField>

<Tip>
  Alias: `keyclick`
</Tip>

### Example

This script will tap (press and release) the 'H' key.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

local H_KEYCODE = 0x48
keytap(H_KEYCODE)
```

# mouse1click

> Simulate a left mouse click. The click will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function mouse1click()
```

### Example

This script will click the left mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse1click()
```

# mouse1press

> Simulate a left mouse press. The left mouse press will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function mouse1press()
```

### Example

This script will press and release the left mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse1press()
task.wait()
mouse1release()
```

# mouse1release

> Simulate a left mouse release. The left mouse will only be released (simulated) if Roblox's currently active or in focus.

```lua theme={null}
function mouse1release()
```

### Example

This script will press and release the left mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse1press()
task.wait()
mouse1release()
```

# mouse2click

> Simulate a right mouse click. The click will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function mouse2click()
```

### Example

This script will click the right mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse2click()
```

# mouse2press

> Simulate a right mouse press. The right mouse press will only be simulated if Roblox's currently active or in focus.

```lua theme={null}
function mouse2press()
```

### Example

This script will press and release the right mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse2press()
task.wait()
mouse2release()
```

# mouse2release

> Simulate a right mouse release. The right mouse will only be released (simulated) if Roblox's currently active or in focus.

```lua theme={null}
function mouse2release()
```

### Example

This script will press and release the right mouse button.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mouse2press()
task.wait()
mouse2release()
```

# mousemoveabs

> Simulate a mouse movement. This movement is not relative to the current mouse's position. The mouse will only be moved if Roblox's currently active or in focus.

```lua theme={null}
function mousemoveabs(x: number, y: number)
```

<ResponseField name="x" type="number" required="True">
  The absolute X coordinate to move the mouse to.
</ResponseField>

<ResponseField name="y" type="number" required="True">
  The absolute Y coordinate to move the mouse to.
</ResponseField>

### Example

This script will move the mouse to (100, 100) on the screen.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mousemoveabs(100, 100)
```

# mousemoverel

> Simulate a mouse movement. This movement is relative to the current mouse's position. The mouse will only be moved if Roblox's currently active or in focus.

```lua theme={null}
function mousemoverel(x: number, y: number)
```

<ResponseField name="x" type="number" required="True">
  The relative X coordinate to move the mouse to.
</ResponseField>

<ResponseField name="y" type="number" required="True">
  The relative Y coordinate to move the mouse to.
</ResponseField>

### Example

This script will move the mouse (100, 100) pixels relative to the current mouse's position.

```lua theme={null}
task.wait(1) -- Give the user time to put roblox in focus.

mousemoverel(100, 100)
```

# mousescroll

> Simulate a mouse scroll. The mouse will only scroll if Roblox's currently active or in focus.

```lua theme={null}
function mousescroll(scroll: number)
```

<ResponseField name="scroll" type="number" required="True">
  The relative scroll amount. See the example below.
</ResponseField>

### Example

```lua theme={null}
mousescroll(10) --> Scrolls up

task.wait()

mousescroll(-10) --> Scrolls down
```


---

# Instance Library

# fireclickdetector

> Fires a `ClickDetector`'s signal.

```lua theme={null}
function fireclickdetector(clickdetector: ClickDetector, distance?: number, signal?: string): ()
```

<ResponseField name="clickdetector" type="ClickDetector" required="True">
  The `ClickDetector` that's fired.
</ResponseField>

<ResponseField name="distance" type="number">
  The distance between the `LocalPlayer` and the `ClickDetector`'s parent part. The default distance is 0.
</ResponseField>

<ResponseField name="signal" type="string">
  This string determines which signal to fire. Signal types include: "MouseClick", "RightMouseClick", "MouseHoverEnter", and "MouseHoverLeave". The Default is "MouseClick".
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part")
local clickdetector = Instance.new("ClickDetector", part)

clickdetector.MouseClick:Connect(function()
    print("fired MouseClick")
end)

clickdetector.RightMouseClick:Connect(function()
    print("fired RightMouseClick")
end)

fireclickdetector(clickdetector) -- Will fire "MouseClick"
task.wait(1)
fireclickdetector(clickdetector, 0, "RightMouseClick")
```

# fireproximityprompt

> Fires the `ProximityPrompt`'s `Triggered` signal.

```lua theme={null}
function fireproximityprompt(proximityprompt: ProximityPrompt): ()
```

<ResponseField name="proximityprompt" type="ProximityPrompt" required="True">
  The `ProximityPrompt` that's triggered.
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part", workspace)
local proximityPrompt = Instance.new("ProximityPrompt", part)

proximityPrompt.Triggered:Connect(function()
    print("proximityPrompt Triggered")
end)

fireproximityprompt(proximityPrompt)
```

# firetouchinterest

> Fires an `Instance`'s `Touched` and `TouchEnded` signals.

```lua theme={null}
function firetouchinterest(source: Instance, target: Instance, touch: boolean): ()
```

<ResponseField name="source" type="Instance" required="True">
  The `Instance` that will touch the target.
</ResponseField>

<ResponseField name="target" type="Instance" required="True">
  The `Instance` that will be touched by the source.
</ResponseField>

<ResponseField name="touch" type="boolean" required="True">
  This boolean toggles between touching and not touching the target `Instance`.
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part", workspace)

part.Touched:Connect(function()
    print("Touched")
end)

part.TouchEnded:Connect(function()
    print("TouchEnded")
end)

local character = game.Players.LocalPlayer.Character

firetouchinterest(part, character.HumanoidRootPart, true)
task.wait(1)

firetouchinterest(part, character.HumanoidRootPart, false)
task.wait()

part:Destroy()
```

# getcallbackvalue

> Returns a callback function associated with a callback property.

```lua theme={null}
function getcallbackvalue(instance: Instance, property: string): function?
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that is used to derive the callback.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The name of the callback property. See example below.
</ResponseField>

<Tip>
  Alias: `getcallbackmember`
</Tip>

### Example

```lua theme={null}
local bindableFunction = Instance.new("BindableFunction")
bindableFunction.OnInvoke = function()
    print("Invoked")
end

local callback = getcallbackvalue(bindableFunction, "OnInvoke")
callback() --> Invoked
```

# getcustomasset

> Returns an asset ID that can be used in loading custom assets.

```lua theme={null}
function getcustomasset(filepath: string): string
```

<ResponseField name="file" type="string" required="True">
  The file path from the `workspace` folder.
</ResponseField>

### Example

```lua theme={null}
local assetId = getcustomasset("mysound.mp3")

local sound = Instance.new("Sound", workspace)
sound.SoundId = assetId
sound:Play()
```

# gethui

> Returns a container that's hidden from game scripts.

```lua theme={null}
function gethui(): Instance
```

<Tip>
  Alias: `get_hidden_gui`
</Tip>

### Example

```lua theme={null}
local hiddenContainer = gethui()

local frame = Instance.new("Frame", hiddenContainer)
frame.Size = UDim2.new(0, 100, 0, 100)
```

# getinstances

> Returns a table of every instance in the game.

```lua theme={null}
function getinstances(): { Instance }
```

### Example

This script will print every instance in the game.

```lua theme={null}
for _, instance in getinstances() do
    print(instance)
end
```

# getnilinstances

> Returns a table of every instance in the game that is parented to nil.

```lua theme={null}
function getnilinstances(): { Instance }
```

### Example

This script will print every nil instance in the game.

```lua theme={null}
for _, instance in getnilinstances() do
    print(instance)
end
```

# getrendersteppedlist

> Returns a table of every callback that's bound using `BindToRenderStep`.

```lua theme={null}
function getrendersteppedlist(): { function }
```

### Example

This script will print every callback that's bound to 'RenderStepped'.

```lua theme={null}
local connections = getrendersteppedlist()

for _, callback in connections do
    print("Function:", callback.Function)
    print("Thread:", callback.Thread)
    print("Priority:", callback.Priority)
    print("Name:", callback.Name)
end
```


---

# Metatable Library

# getnamecallmethod

> Gets the current thread's `__namecall` method.

```lua theme={null}
function getnamecallmethod(): string?
```

<Tip>
  Alias: `get_namecall_method`
</Tip>

### Example

```lua theme={null}
xpcall(function()
  return game:method()
end, function()
  print(getnamecallmethod()) --> method
end)
```

# setnamecallmethod

> Sets the current threads's `__namecall` method.

```lua theme={null}
function setnamecallmethod(method: string): ()
```

<ResponseField name="method" type="string" required="True">
  The new namecall method name to set on the current state.
</ResponseField>

<Tip>
  Alias: `set_namecall_method`
</Tip>

### Example

```lua theme={null}
game:GetFullName()
print(getnamecallmethod()) --> GetFullName

setnamecallmethod("getFullName")
print(getnamecallmethod()) --> getFullName

print(getrawmetatable(game).__namecall(game)) --> Ugc
```

# getrawmetatable

> Gets the 'metatable' from a table or userdata whilst ignoring the `__metatable` value.

```lua theme={null}
function getrawmetatable(meta: table | userdata): table?
```

<ResponseField name="meta" type="table | userdata" required="True">
  The table or userdata that contains a metatable.
</ResponseField>

<Tip>
  Alias: `debug.getmetatable`
</Tip>

### Example

```lua theme={null}
local t = setmetatable({}, {
  __index = function(self, index)
      print(index)
  end,
  __metatable = "This table is locked."
})

print(getmetatable(t)) --> This table is locked.
print(getrawmetatable(t)) --> table: 0x.....
```

# setrawmetatable

> Sets the 'metatable' for a table or userdata whilst ignoring the '__metatable' value.

```lua theme={null}
function setrawmetatable(tbl: table | userdata, meta: table): table?
```

<ResponseField name="tbl" type="table | userdata" required="True">
  A table or userdata.
</ResponseField>

<ResponseField name="meta" type="table" required="True">
  The metatable you want to set the 'tbl' to.
</ResponseField>

<Tip>
  Alias: `debug.setmetatable`
</Tip>

### Example

```lua theme={null}
local t = setmetatable({}, {
  __index = function(self, index)
      print(index)
  end,
  __metatable = "This table is locked."
})

print(pcall(setmetatable, t, {})) --> false, cannot change a protected metatable
print(setrawmetatable(t, {})) --> table: 0x......
```

# hookmetamethod

> hooks the `method` inside the `object` with `func` returning the old func.

```lua theme={null}
function hookmetamethod(object: Instance | table | userdata, method: string, hook: function): table?
```

<ResponseField name="object" type="Instance | table | userdata" required="True">
  The object that contains a metatable.
</ResponseField>

<ResponseField name="method" type="string" required="True">
  A metatable method.
</ResponseField>

<ResponseField name="hook" type="function" required="True">
  The function that will hook the 'method' function.
</ResponseField>

### Example

Using `old` we are able to call the old function and act as a middle man between the original function for '\_\_newindex'.

```lua theme={null}
local old = nil
old = hookmetamethod(game, "__newindex", function(self, index, value)
  if not checkcaller() then --> Ignore non-executor newindex calls
      return old(self, index, value)
  end

  if value == game then --> Prevent any changes from being made to game
      return nil
  end

  return old(self, index, value)
end)

local objectValue = Instance.new("ObjectValue")
objectValue.Value = workspace
print(objectValue.Value) --> Workspace

objectValue.Value = game
print(objectValue.Value) --> Workspace
```

# isreadonly

> Checks if the `table` is read-only/protected.

```lua theme={null}
function isreadonly(table: table): boolean
```

<ResponseField name="table" type="table" required="True">
  The table to check the read-only status of.
</ResponseField>

<Tip>
  Alias: `is_readonly`
</Tip>

### Example

```lua theme={null}
local protected = table.freeze({ foo = "bar" })

print(isreadonly(protected)) --> true
```

# setreadonly

> Sets the 'table's read-only/protected status.

```lua theme={null}
function setreadonly(table: table, readonly: boolean): ()
```

<ResponseField name="table" type="table" required="True">
  The table whose read-only status will be changed.
</ResponseField>

<ResponseField name="readonly" type="boolean" required="True">
  Whether to make the table read-only (`true`) or writable (`false`).
</ResponseField>

<Tip>
  Alias: `set_readonly`
</Tip>

### Example

```lua theme={null}
local protected = table.freeze({ foo = "bar" })

print(pcall(function() protected.bar = "foo" end)) --> false, attempt to modify a readonly table

setreadonly(protected, false) -- Makes the table writable; similar to makewritable(protected)

protected.bar = "foo"
print(protected.bar, table.isfrozen(protected)) --> foo, false

table.freeze(protected) -- Sets the table back to read-only; similar to makereadonly(protected)
```

# makereadonly

> Sets the `table` to read-only.

```lua theme={null}
function makereadonly(table: table): ()
```

<ResponseField name="table" type="table" required="True">
  The table to set as read-only.
</ResponseField>

### Example

```lua theme={null}
local protected = { foo = "bar" }

makereadonly(protected) -- Equivalent to setreadonly(protected, true) or table.freeze(protected)

protected.foo = "test" --> attempt to modify a readonly table
```

# makewritable

> Makes the `table` writable.

```lua theme={null}
function makewritable(table: table): ()
```

<ResponseField name="table" type="table" required="True">
  The read-only table to make writable.
</ResponseField>

### Example

```lua theme={null}
local protected = table.freeze({ foo = "bar" })

print(pcall(function() protected.bar = "foo" end)) --> false, attempt to modify a readonly table

makewritable(protected) -- Equivalent to setreadonly(protected, false)

protected.bar = "foo"
print(protected.bar, table.isfrozen(protected)) --> foo, false

makereadonly(protected) -- Equivalent to setreadonly(protected, true) or table.freeze(protected)
```


---

# Miscellaneous Library

# decompile

> Return pseudocode from the bytecode of 'LuaSourceContainer' with RunContext of 'Client', Legacy with a LocalScript or a ModuleScript.

```lua theme={null}
function decompile(script: LuaSourceContainer): string
```

<ResponseField name="script" type="LuaSourceContainer" required="True">
  The `LuaSourceContainer` (e.g. a `LocalScript` or `ModuleScript`) whose bytecode will be decompiled into pseudocode.
</ResponseField>

### Example

```lua theme={null}
local script = game:GetService("Players").LocalPlayer.Character.Animate

print(decompile(script)) --> Psuedocode of the bytecode from the script
```

# getfflag

> Returns the value of a Fast Flag.

```lua theme={null}
function getfflag(fflag: string): string
```

<ParamField path="fflag" type="string" required>
  The name of the Fast Flag.
</ParamField>

<Tip>
  Alias: `getfastflag`
</Tip>

### Example

```lua theme={null}
local fps = getfflag("TaskSchedulerTargetFps")
print("Current FPS cap:", fps)

local dpiFix = getfflag("FixDPIScaling")
print("DPI fix enabled:", dpiFix)
```

# getfflagtype

> Gets the type of a Fast Flag.

```lua theme={null}
function getfflagtype(fflag: string): string
```

<ParamField path="fflag" type="string" required>
  The name of the Fast Flag to get the type of.
</ParamField>

<Tip>
  Alias: `getfastflagtype`
</Tip>

### Example

```lua theme={null}
print(getfflagtype("TaskSchedulerTargetFps")) --> int
print(getfflagtype("AddClassFullName")) --> flag
```

# setfflag

> Sets the value of a Fast Flag.

```lua theme={null}
function setfflag(fflag: string, value: any): ()
```

<ParamField path="fflag" type="string" required>
  The name of the Fast Flag to set its value of.
</ParamField>

<ParamField path="value" type="string" required>
  The value to set.
</ParamField>

<Tip>
  Alias: `setfastflag`
</Tip>

### Example

```lua theme={null}
-- This will cap the users fps to 120 without setfpscap.
setfflag("TaskSchedulerTargetFps", 120)
```

# getfpscap

> Returns the fps cap set by the client.

```lua theme={null}
function getfpscap(): number
```

### Example

```lua theme={null}
print(getfpscap()) --> 60
```

# setfpscap

> Sets the fps cap set by the client.

```lua theme={null}
function setfpscap(cap: number): ()
```

<ResponseField name="cap" type="number" required="True">
  The frame rate limit to apply. Use a very large value (e.g. `2000`) to effectively uncap the frame rate.
</ResponseField>

### Example

Unlock the frame cap and bypass the 240fps cap set by Roblox.

```lua theme={null}
print(setfpscap(2000))
```

# gethwid

> Returns a unique string for the users device.

```lua theme={null}
function gethwid(): string
```

<Tip>
  Aliases: `get_hwid` `get_user_identifier`
</Tip>

### Example

```lua theme={null}
print("HWID:", gethwid())
```

# identifyexecutor

> Returns information about the executor alongside its version.

```lua theme={null}
function identifyexecutor(): (string, string)
```

<Tip>
  Alias: `getexecutorname`
</Tip>

### Example

```lua theme={null}
print(identifyexecutor()) --> Ex: Potassium, v1.0.0
```

# httpget

> HTTP GET request to `url`.

```lua theme={null}
function httpget(self: any?, url: string): ()
```

<ResponseField name="self" type="any">
  An optional legacy first argument (e.g. `game`) used for backwards compatibility. When provided, the second `url` argument is used as the request target.
</ResponseField>

<ResponseField name="url" type="string" required="True">
  The URL to send the HTTP GET request to.
</ResponseField>

<Tip>
  Alias: `HttpGet`
</Tip>

### Example

```lua theme={null}
print(httpget("https://httpbin.org/get")) --> HTTP body

-- Backwards compatibility but functions exactly the same
print(httpget(game, "https://httpbin.org/get")) --> HTTP body
```

# request

> Creates a HTTP request with specified options.

```lua theme={null}
function request(options: HttpRequest): ()
```

<ResponseField name="options" type="HttpRequest" required>
  The options for the HTTP request.
</ResponseField>

<Tip>
  Aliases: `http_request` `http.request`
</Tip>

### HttpRequest

| Field     | Type    | Description              |
| --------- | ------- | ------------------------ |
| `Url`     | string  | The URL for the request. |
| `Method`  | string  | The HTTP method to use.  |
| `Body`    | string? | The body of the request. |
| `Headers` | table?  | A table of headers.      |
| `Cookies` | table?  | A table of cookies.      |

### Response

| Field           | Type    | Description                                |
| --------------- | ------- | ------------------------------------------ |
| `Body`          | string  | The body of the response.                  |
| `StatusCode`    | number  | The number status code of the response.    |
| `StatusMessage` | string  | The status message of the response.        |
| `Success`       | boolean | Whether or not the request was successful. |
| `Headers`       | table   | A dictionary of headers.                   |

### Example

```lua theme={null}
local response = request({
   Url = "https://httpbin.org", Method = "GET"
})

print(response.Success)
print(response.StatusCode)
print(response.StatusMessage)
```

# getobjects

> Equivalent for game:GetObjects by fetching `asset` from Roblox.

```lua theme={null}
function getobjects(self: any?, asset: string): ()
```

<ResponseField name="self" type="any">
  An optional legacy first argument (e.g. `game`) used for backwards compatibility. When provided, the second `asset` argument is used as the asset identifier.
</ResponseField>

<ResponseField name="asset" type="string" required="True">
  The `rbxassetid://` URL of the Roblox asset to fetch and load.
</ResponseField>

### Example

```lua theme={null}
local asset = getobjects("rbxassetid://1818") --> Fetches Crossroads

print(asset[1]) --> SoundService
```

# messagebox

> Creates a message box with the specified `text`, `caption` and `flags`.

```lua theme={null}
function messagebox(text: string, caption: string, flags: number): number
```

<ResponseField name="text" type="string" required="True">
  The message content to display inside the message box.
</ResponseField>

<ResponseField name="caption" type="string" required="True">
  The title text shown in the message box title bar.
</ResponseField>

<ResponseField name="flags" type="number" required="True">
  A bitmask of `uType` flags from `winuser.h` that control the buttons and icon displayed.
</ResponseField>

<Info>
  Flags utilize winuser.h's MessageBox uType which is documented [here](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messagebox)
</Info>

<Tip>
  Alias: `messageboxasync`
</Tip>

### Example

```lua theme={null}
local MB_ICONWARNING = 0x00000030
local MB_CANCELTRYCONTINUE = 0x00000006
local MB_DEFBUTTON2 = 0x00000100

local IDCANCEL = 0x00000002
local IDTRYAGAIN = 0x0000000A
local IDCONTINUE = 0x0000000B

local input = messagebox(
   "?",
   "Resource not found",
   bit32.bor(MB_ICONWARNING, MB_CANCELTRYCONTINUE, MB_DEFBUTTON2)
)

if input == IDCANCEL then
    print("IDCANCEL")
elseif input == IDTRYAGAIN then
    print("IDTRYAGAIN")
elseif input == IDCONTINUE then
    print("IDCONTINUE")
end
```

# saveinstance

> Saves an instance in .rbxl or .rbxm format.

```lua theme={null}
function saveinstance(object: Instance?, options: table?): ()
```

<ResponseField name="object" type="Instance">
  The `Instance` to save. Defaults to `game`.
</ResponseField>

<ResponseField name="options" type="table">
  A table of options controlling decompilation, threading, filtering, and output behaviour. See the Options table below.
</ResponseField>

### Options

| Option                   | Type    | Default                             | Description                                                           |
| ------------------------ | ------- | ----------------------------------- | --------------------------------------------------------------------- |
| `FileName`               | string  | Varies                              | Output file name                                                      |
| `Decompile`              | boolean | `false`                             | Should scripts be decompiled during saveinstance                      |
| `NilInstances`           | boolean | `false`                             | Save instances that are not parented in the DataModel (nil instances) |
| `RemovePlayerCharacters` | boolean | `true`                              | Ignore characters whilst doing saveinstance                           |
| `SavePlayers`            | boolean | `false`                             | Save player instances                                                 |
| `DecompileTimeout`       | number  | `10`                                | Timeout (in seconds) for decompile jobs                               |
| `MaxThreads`             | number  | `3`                                 | Number of threads used to decompile scripts                           |
| `DecompileIgnore`        | table   | `{"Chat","CoreGui","CorePackages"}` | Services to ignore during decompile                                   |
| `ShowStatus`             | boolean | `true`                              | Show saveinstance status while running                                |
| `IgnoreDefaultProps`     | boolean | `true`                              | Ignore default properties                                             |
| `IsolateStarterPlayer`   | boolean | `true`                              | Clears StarterPlayer and places saved version into folders            |

### Example

```lua theme={null}
saveinstance(game, {
    FileName = "game.rbxl",
    Decompile = true,
    MaxThreads = 5 -- Adjust depending on PC specs
})
```

# setclipboard

> Sets the 'text' into the user clipboard.

```lua theme={null}
function setclipboard(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The text to copy into the user's system clipboard.
</ResponseField>

<Tip>
  Alias: `toclipboard`
</Tip>

### Example

```lua theme={null}
setclipboard("Hello, world!")
```

# setrbxclipboard

> Sets the 'text' into the Roblox Studio clipboard.

```lua theme={null}
function setrbxclipboard(text: string): ()
```

<ResponseField name="text" type="string" required="True">
  The XML or binary model data to copy into the Roblox Studio clipboard.
</ResponseField>

<Info>
  The data must be in a valid xml/binary model format or it will not work.
</Info>

### Example

```lua theme={null}
local part = Instance.new("Part")
part.Name = "Exploit Side"

saveinstance(part, {
   FileName = "clipboard.rbxmx" 
})

task.wait(3)

setrbxclipboard(readfile("clipboard.rbxmx"))

delfile("clipboard.rbxmx")
```

# queueonteleport

> Queues 'code' for teleport and executes once a teleport completes.

```lua theme={null}
function queueonteleport(code: string): ()
```

<ResponseField name="code" type="string" required="True">
  The Lua code string to execute once a teleport completes.
</ResponseField>

<Tip>
  Alias: `queue_on_teleport`
</Tip>

### Example

Once a teleport is initiated this code will execute

```lua theme={null}
queueonteleport([[
print("Hello, world!")
]])
```

# clearteleportqueue

> Clears the queue created by 'queueonteleport'.

```lua theme={null}
function clearteleportqueue(): ()
```

<Tip>
  Aliases: `clear_teleport_queue` `clearqueueonteleport`
</Tip>

### Example

Once a teleport is initiated this code will execute.

```lua theme={null}
queueonteleport([[
    print("Hello, world!")
]])

-- No code will be executed after teleport
clearteleportqueue()
```


---

# Oth Library (Off-Thread Hooks)

# oth.hook

> Hooks a function by utilizing a secure 'Off-Thread' execution model that runs hook code on isolated threads. This method is specifically designed for hooking C functions where standard `hookfunction` might be detected.

```lua theme={null}
function oth.hook(target: function, hook: function): ()
```

<ResponseField name="target" type="function" required="True">
  The function to hook.
</ResponseField>

<ResponseField name="hook" type="function" required="True">
  The hook function.
</ResponseField>

### Example

This example hooks `Instance.new` to print the class name of every new instance created.

```lua theme={null}
local old = nil
old = oth.hook(Instance.new, function(...)
    print("Creating new instance:", ...)

    return old(...)
end)
```

# oth.unhook

> Unhooks a function previously hooked with `oth.hook`.

```lua theme={null}
function oth.unhook(target: function): ()
```

<ResponseField name="target" type="function" required="True">
  The function to unhook.
</ResponseField>

### Example

This example replaces `print` with `warn` and then unhooks it to restore the original behavior.

```lua theme={null}
local old = nil
old = oth.hook(print, function(...)
    return warn(...)
end)

print("This will be a warning.")

oth.unhook(print)

print("This will be a print.")
```

# oth.is_hook_thread

> Returns whether or not this thread is a hook thread.

```lua theme={null}
function oth.is_hook_thread(): boolean
```

### Example

This example hooks `math.random` to ensure that any calls made from within the hook thread always return 1, while allowing normal game scripts to receive actual random numbers.

```lua theme={null}
local old = nil
old = oth.hook(math.random, function(...)
    if oth.is_hook_thread() then
        return 1
    end
    
    return old(...)
end)
```

# oth.get_original_thread

> Return the original thread this hook comes from, or nil if the current thread is not a hook.

```lua theme={null}
function oth.get_original_thread(): thread
```

### Example

This example hooks `game.GetService(game, ...)` and returns an infinite yield for any calls made from scripts in `nilinstances` to fully bypass some anti-cheats that rely on `game.GetService` on startup.

```lua theme={null}
oth.hook(game.GetService, function(...)
    local thread = oth.get_original_thread()
    local script = getscriptfromthread(thread)

    if script and script.Parent == nil then
        return task.wait(9e9)
    end

    return oth.get_root_callback()(...)
end)
```

# oth.get_root_callback

> Retrieves a function that can be used to call the original function in the context of a hook thread.

```lua theme={null}
function oth.get_root_callback(): function
```

### Example

This example hooks `Instance.FindService(Instance, ...)` to return `nil` for `VirtualInputManager`, effectively hiding it from detection.

```lua theme={null}
oth.hook(game.FindService, function(self, service)
    if service == "VirtualInputManager" then
        return nil
    end

    return oth.get_root_callback()(self, service)
end)
```


---

# PsmSignal Library

# PsmSignal.new

> Constructs a new `PsmSignal` object.

```lua theme={null}
function PsmSignal.new(): PsmSignal
```

<Tip>
  Alias: `Signal.new`
</Tip>

### Methods

| Method                            | Description                                                      |
| --------------------------------- | ---------------------------------------------------------------- |
| `Connect(callback: function): ()` | Connects a callback function to the signal.                      |
| `Once(callback: function): ()`    | Connects a callback function to the signal that fires only once. |
| `Wait(): ()`                      | Yields until the signal fires.                                   |
| `Fire(...: any): ()`              | Fires the signal with the given arguments.                       |

### Example

This script creates a PsmSignal `Once` connection and fires it.

```lua theme={null}
local signal = PsmSignal.new()

signal:Once(function()
    print("Signal fired!")
end)

signal:Fire()
```

# PsmConnection

### Methods

| Method             | Description                                     |
| ------------------ | ----------------------------------------------- |
| `Disconnect(): ()` | Disconnect a callback function from the signal. |


---

# RakNet Library

# RakNetPacket

### Fields

| Field             | Type     | Description                                                  |
| ----------------- | -------- | ------------------------------------------------------------ |
| `PacketId`        | `number` | The ID of the packet.                                        |
| `Size`            | `number` | The size of the packet data.                                 |
| `Priority`        | `number` | The priority of the packet.                                  |
| `AsBuffer`        | `buffer` | The data of the packet as a buffer.                          |
| `AsArray`         | `table`  | The data of the packet as an array.                          |
| `AsString`        | `string` | The data of the packet as a string.                          |
| `Reliability`     | `number` | The reliability mode of the packet.                          |
| `OrderingChannel` | `number` | The ordering channel of the packet used for ordered traffic. |

### Methods

| Method                                                     | Description                        |
| ---------------------------------------------------------- | ---------------------------------- |
| `SetData(data: buffer \| table \| string \| {number}): ()` | Sets the packet's payload.         |
| `Block(): ()`                                              | Blocks the packet from being sent. |

# raknet.send

> Sends a packet with a payload, priority, reliability, and ordering channel.

```lua theme={null}
function raknet.send(packet: buffer | table | string, priority: int, reliability: int, orderingChannel: int): ()
```

<ResponseField name="packet" type="buffer | table | string" required="True">
  The packet to send.
</ResponseField>

<ResponseField name="priority" type="int">
  The priority of the packet.
</ResponseField>

<ResponseField name="reliability" type="int">
  The reliability mode of the packet.
</ResponseField>

<ResponseField name="orderingChannel" type="int">
  The ordering channel of the packet used for ordered traffic.
</ResponseField>

<Warning>
  Due to the nature of RakNet, in order for this function to do anything, you need to enable it in the internal UI settings. Bans may occur from using this.
</Warning>

### Example

This example sends a packet with a buffer as payload, a priority of `1`, a reliability of `0`, and an ordering channel of `0`.

```lua theme={null}
local buf = buffer.create(2);
buffer.writeu8(buf, 1, 123);

raknet.send(buf, 1, 0, 0)
```

# raknet.add_send_hook

> Registers a callback that runs before a `RakNetPacket` is sent.

```lua theme={null}
function raknet.add_send_hook(callback: (packet: RakNetPacket) -> nil): ()
```

<ResponseField name="callback" type="function" required="True">
  The callback function to register.
</ResponseField>

<Warning>
  Due to the nature of RakNet, in order for this function to do anything, you need to enable it in the UI settings. Bans may occur from using this.
</Warning>

### Example

This example prints the data of every packet sent.

```lua theme={null}
raknet.add_send_hook(function(packet)
    print("ID:", packet.PacketId)
    print("Size:", packet.Size)
    print("Priority:", packet.Priority)
    print("Data (as buffer):", packet.AsBuffer)
    print("Data (as array):", packet.AsArray)
    print("Data (as string):", packet.AsString)
    print("Reliability:", packet.Reliability)
    print("Ordering Channel:", packet.OrderingChannel)
end)
```

### Desync Example

This example is a widely known replication desync that registers a send hook that modifies `ID_TIMESTAMP` packets before they are sent.

```lua theme={null}
raknet.add_send_hook(function(packet)
    if packet.PacketId == 0x1B then
        local buf = packet.AsBuffer
        buffer.writeu32(buf, 1, 0xFFFFFFFF)

        packet:SetData(buf)
    end
end)
```

# raknet.remove_send_hook

> Removes a previously registered send hook.

```lua theme={null}
function raknet.remove_send_hook(callback: function): ()
```

<ResponseField name="callback" type="function" required="True">
  The callback function to remove.
</ResponseField>

<Warning>
  Due to the nature of RakNet, in order for this function to do anything, you need to enable it in the UI settings. Bans may occur from using this.
</Warning>

### Example

This example prints the data of every packet sent and then removes the send hook to prevent it from printing future packets.

```lua theme={null}
local send_hook = nil
send_hook = function(packet)
    print("ID:", packet.PacketId)
    print("Size:", packet.Size)
    print("Priority:", packet.Priority)
    print("Data (as buffer):", packet.AsBuffer)
    print("Data (as array):", packet.AsArray)
    print("Data (as string):", packet.AsString)
    print("Reliability:", packet.Reliability)
    print("Ordering Channel:", packet.OrderingChannel)

    raknet.remove_send_hook(send_hook)
end

raknet.add_send_hook(send_hook)
```


---

# Reflection Library

# gethiddenproperty

> Returns the value of a hidden property, and a boolean indicating whether the property is hidden.

```lua theme={null}
function gethiddenproperty(instance: Instance, propertyname: string): (any, boolean)
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that contains the hidden property.
</ResponseField>

<ResponseField name="propertyname" type="string" required="True">
  The name of the property returned.
</ResponseField>

<Tip>
  Alias: `gethiddenprop`
</Tip>

### Example

```lua theme={null}
local fire = Instance.new("Fire")

local size_xml, hidden = gethiddenproperty(fire, "size_xml")
print(size_xml, hidden)
```

# sethiddenproperty

> Sets the value of a hidden property. Returns a boolean indicating whether the property is hidden.

```lua theme={null}
function sethiddenproperty(instance: Instance, property: string, value: any): boolean
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that contains the hidden property.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The name of the property.
</ResponseField>

<ResponseField name="value" type="any" required="True">
  The new value of the property.
</ResponseField>

<Tip>
  Alias: `sethiddenprop`
</Tip>

### Example

```lua theme={null}
local fire = Instance.new("Fire")
local hidden = sethiddenproperty(fire, "size_xml", 123)
print(hidden) --> true
```

# gethiddenproperties

> Returns a table of every non-scriptable property and its value.

```lua theme={null}
function gethiddenproperties(instance: Instance): { property: value }
```

### Example

This script will print the value of every non-scriptable property for workspace.

```lua theme={null}
for property, value in gethiddenproperties(workspace) do
    print(property, value);
end
```

# getproperties

> Returns a table of every property, including non-scriptable properties and its value.

```lua theme={null}
function getproperties(instance: Instance): { property: value }
```

### Example

This script will print the value of every property for workspace.

```lua theme={null}
for property, value in getproperties(workspace) do
    print(property, value)
end
```

# isscriptable

> Returns boolean indicating whether a property is scriptable.

```lua theme={null}
function isscriptable(instance: Instance, property: string): boolean
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that contains the property.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The name of the property returned.
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part")
print(isscriptable(part, "Transparency")) --> false
```

# setscriptable

> Sets whether a property is scriptable.

```lua theme={null}
function setscriptable(instance: Instance, property: string, scriptable: boolean): ()
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that contains the property.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The name of the property.
</ResponseField>

<ResponseField name="scriptable" type="boolean" required="True">
  Whether the property will become scriptable.
</ResponseField>

### Example

```lua theme={null}
local fire = Instance.new("Fire")
setscriptable(fire, "size_xml", true)

fire.size_xml = 123
print(fire.size_xml) --> 123
```

# getbspval

> Reads a `BinaryString` property’s value. Useful for reading conventionally unreadable `BinaryString` properties such as Terrain.SmoothGrid, PartOperation.PhysicsData, BinaryStringValue.Value, and so on.

```lua theme={null}
function getbspval(instance: Instance, property: string, base64: boolean): string
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that contains the `BinaryString`'s value.
</ResponseField>

<ResponseField name="property" type="string" required="True">
  The name of the property read.
</ResponseField>

<ResponseField name="base64" type="boolean">
  Boolean indicating whether the `BinaryString`'s value is Base64 encoded.
</ResponseField>

### Example

```lua theme={null}
local result = getbspval(workspace.Terrain, "SmoothGrid", true)
print(result) --> AQU= (Example output)
```

# getpcd

> Returns a 16-byte hash and binary data corresponding to TriangleMeshPart’s PhysicalConfigData property.

```lua theme={null}
function getpcd(trianglemeshpart: Instance): string, string
```

<ResponseField name="trianglemeshpart" type="Instance" required="True">
  The `Instance` that contains the binary data.
</ResponseField>

<Tip>
  Alias: `getpcdprop`
</Tip>

### Example

This example prints the hash, and the BinaryData.

```lua theme={null}
print(getpcd(Instance.new("UnionOperation")))
```

# getproximitypromptduration

> Returns the value of a proximity prompt's duration.

```lua theme={null}
function getproximitypromptduration(proximityprompt: ProximityPrompt): number
```

<ResponseField name="proximityprompt" type="ProximityPrompt" required="True">
  The `ProximityPrompt` that contains the duration.
</ResponseField>

### Example

This script will print the duration of a proximity prompt

```lua theme={null}
local proximityprompt = Instance.new("ProximityPrompt")
proximityprompt.HoldDuration = 3

local duration = getproximitypromptduration(proximityprompt)
print(duration)
```

# setproximitypromptduration

> Sets the value of a proximity prompt's duration.

```lua theme={null}
function setproximitypromptduration(proximityprompt: ProximityPrompt, duration: number): ()
```

<ResponseField name="proximityprompt" type="ProximityPrompt" required="True">
  The `ProximityPrompt` that contains the duration.
</ResponseField>

<ResponseField name="duration" type="number" required="True">
  The new duration of the `ProximityPrompt`.
</ResponseField>

### Example

```lua theme={null}
local proximityprompt = Instance.new("ProximityPrompt")
setproximitypromptduration(proximityprompt, 99)

local duration = getproximitypromptduration(proximityprompt)
print(duration) --> 99
```

# getsimulationradius

> Returns the simulation radius of the `LocalPlayer`.

```lua theme={null}
function getsimulationradius(): number
```

### Example

```lua theme={null}
print(getsimulationradius()) --> 1000
setsimulationradius(2000)
print(getsimulationradius()) --> 2000
```

# setsimulationradius

> Sets the simulation radius of the `LocalPlayer`.

```lua theme={null}
function setsimulationradius(simulationradius: number): ()
```

<ResponseField name="simulationradius" type="number" required="True">
  The `LocalPlayer`'s new simulation radius.
</ResponseField>

### Example

```lua theme={null}
setsimulationradius(999)
print(getsimulationradius()) --> 999
```

# isnetworkowner

> Returns boolean indicating whether the `LocalPlayer` is the network owner of a given instance.

```lua theme={null}
function isnetworkowner(instance: Instance): boolean
```

<ResponseField name="instance" type="Instance" required="True">
  The `Instance` that the user has provided.
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part")
print(isnetworkowner(part))
```


---

# Regex Library

# Regex.new

> Constructs a new `Regex` object using the specified pattern.

```lua theme={null}
function Regex.new(pattern: string): Regex
```

<ResponseField name="pattern" type="string" required="True">
  The regular expression pattern.
</ResponseField>

### Methods

| Method                                                    | Description                                                                   |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `Match(contents: string): match`                          | Matches contents against the Regex object and returns the first Match.        |
| `MatchMany(contents: string): table`                      | Matches contents against the Regex object and returns all matches.            |
| `Replace(contents: string, replacement: string): string ` | Replaces the first match of this Regex object in contents with `replacement`. |

### Example

This example creates a Regex object to extract an ID from a string and then prints the ID.

```lua theme={null}
local input = "My Cool Id: 31235335"
local regex = Regex.new("My Cool Id:\\s*(\\w+)")
local match = regex:Match(input)

if match then
    print("ID:", regex:Replace(match, "$1"))
end
```

# Regex.Escape

> Escapes a string for use in a regular expression.

```lua theme={null}
function Regex.Escape(contents: string): string
```

<ResponseField name="contents" type="string" required="True">
  The string to escape.
</ResponseField>

### Example

This example uses `Regex.Escape` to escape a string that contains special characters and then uses the escaped string in a regular expression to extract an ID from an input string.

```lua theme={null}
local input = "[DEBUG] (ID): 99821"
local label = "[DEBUG] (ID): "

local escaped = Regex.Escape(label)
local regex = Regex.new(escaped .. "(\\d+)")
local match = regex:Match(input)

if match then
    print("ID:", regex:Replace(match, "$1"))
end
```


---

# Script Library

# getscripts

> Returns a table of every script in the game.

```lua theme={null}
function getscripts(): { BaseScript }
```

### Example

This script will print every script.

```lua theme={null}
for _, script in getscripts() do
    print(script)
end
```

# getrunningscripts

> Returns a table of every script that's currently running.

```lua theme={null}
function getrunningscripts(): { BaseScript }
```

### Example

This script will print the name of `LocalPlayer`'s character.

```lua theme={null}
for _, script in getrunningscripts() do
    if script.Name == "Animate" then
        print(script.Parent.Name)
    end
end
```

# getloadedmodules

> Returns a table of every `ModuleScript` that's loaded in the game.

```lua theme={null}
function getloadedmodules(): { ModuleScript }
```

### Example

This script will print the path of the `ModuleScript` named "PlayerModule".

```lua theme={null}
for _, script in getloadedmodules() do
    if script.Name == "PlayerModule" then
        print(script:GetFullName())
    end
end
```

# getscriptbytecode

> Returns the bytecode of a given script.

```lua theme={null}
function getscriptbytecode(script: BaseScript): string
```

<ResponseField name="script" type="BaseScript" required="True">
  The script that will have it's bytecode returned.
</ResponseField>

<Tip>
  Alias: `dumpstring`
</Tip>

### Example

This script will print the bytecode of the `Animate` script inside of `LocalPlayer`'s character.

```lua theme={null}
for _, script in getrunningscripts() do
    if script.Name == "Animate" then
        print(getscriptbytecode(script))
    end
end
```

# getscriptclosure

> Returns the main function of a given script.

```lua theme={null}
function getscriptclosure(script: BaseScript): function
```

<ResponseField name="script" type="BaseScript" required="True">
  The script that will have it's main function returned.
</ResponseField>

<Tip>
  Alias: `getscriptfunction`
</Tip>

### Example

This script will print every running script's main function.

```lua theme={null}
for _, script in getrunningscripts() do
    print(getscriptclosure(script))
end
```

# getscripthash

> Returns a hash of a given script.

```lua theme={null}
function getscripthash(script: BaseScript): string
```

<ResponseField name="script" type="BaseScript" required="True">
  The script that will be hashed.
</ResponseField>

### Example

This script will print every running script's hash.

```lua theme={null}
for _, script in getrunningscripts() do
    print(getscripthash(script))
end
```

# getscriptthread

> Returns a thread (or nil) that's derived from an associated script.

```lua theme={null}
function getscriptthread(script: BaseScript): thread?
```

<ResponseField name="script" type="BaseScript" required="True">
  The script that will have it's thread returned.
</ResponseField>

### Example

This is an example script that could be used to disable an anticheat script.

```lua theme={null}
for _, script in getnilinstances() do
    if not script:IsA("LocalScript") then
        continue
    end

    local thread = getscriptthread(script);

    if thread and coroutine.status(thread) ~= "dead" then
        task.cancel(thread)
    end
end
```

# getscriptfromthread

> Returns a script (or nil) that's derived from an associated thread.

```lua theme={null}
function getscriptfromthread(thread: thread): BaseScript?
```

<ResponseField name="thread" type="thread" required="True">
  User provided thread.
</ResponseField>

### Example

This script will print every script associated with a thread.

```lua theme={null}
for _, thread in getallthreads() do
    local script = getscriptfromthread(thread)
    if script then
        print(script)
    end
end
```

# getthreadidentity

> Returns the current thread's identity.

```lua theme={null}
function getthreadidentity(): number
```

<Tip>
  Aliases: `getidentity` `getthreadcontext` `get_thread_identity` `getthreadcaps`
</Tip>

### Example

This script will print the current thread's identity.

```lua theme={null}
print(getthreadidentity()) --> 8 (without previous changes)
```

# setthreadidentity

> Sets the current thread's identity.

```lua theme={null}
function getthreadidentity(identity: number): ()
```

<ResponseField name="identity" type="number" required="True">
  The new identity of the current thread.
</ResponseField>

<Tip>
  Aliases: `setidentity` `setthreadcontext` `set_thread_identity` `getthreadcaps`
</Tip>

### Example

This script will print the current thread's new identity.

```lua theme={null}
setthreadidentity(2)
print(getthreadidentity()) --> 2
```


---

# Signal Library

# firesignal

> Fires all connections connected to a `RBXScriptSignal`.

```lua theme={null}
function firesignal(signal: RBXScriptSignal, ...: any?)
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The specific signal to fire.
</ResponseField>

### Example

```lua theme={null}
local localPlayer = game.Players.LocalPlayer

localPlayer.Idled:Connect(function()
    print("Fired!")
end)

firesignal(localPlayer.Idled)
```

# replicatesignal

> Fires all server connections connected to a `RBXScriptSignal`. Arguments provided must be valid, otherwise it will fail.

```lua theme={null}
function replicatesignal(signal: RBXScriptSignal, ...: any?)
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The specific signal to replicate.
</ResponseField>

### Example with arguments

This example will replicate a mouse click for a click detector.

```lua theme={null}
local clickDetector = Instance.new("ClickDetector")
local player = game.Players.LocalPlayer

replicatesignal(clickDetector.MouseActionReplicated, player, 0)
```

### Example without arguments

This example will kill the `LocalPlayer`.

```lua theme={null}
local player = game.Players.LocalPlayer

replicatesignal(player.Kill)
```

# cansignalreplicate

> Returns a boolean indicating whether an `RBXScriptSignal` can replicate (fire server events).

```lua theme={null}
function cansignalreplicate(signal: RBXScriptSignal): boolean
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The signal that is checked.
</ResponseField>

### Example

```lua theme={null}
local part = Instance.new("Part")
print(cansignalreplicate(part.Touched))
```

# getconnection

> Returns a `Connection` object that is connected to a given `RBXScriptSignal`.

```lua theme={null}
function getconnection(signal: RBXScriptSignal, index: number): {Connection}
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The specific signal to use.
</ResponseField>

<ResponseField name="index" type="number" required="True">
  The specific signal to grab using the index provided.
</ResponseField>

### Example

This script is a common anti-afk script. You will not be kicked for being afk (or "Idled").

```lua theme={null}
local connection = getconnection(game.Players.LocalPlayer.Idled, 1)
connection:Disable()
```

# getconnections

> Returns a table of `Connection` objects that are connected to a given `RBXScriptSignal`.

```lua theme={null}
function getconnections(signal: RBXScriptSignal): {Connection}
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The specific signal to use.
</ResponseField>

### Connection

| Field           | Type                | Description                                                                    |
| --------------- | ------------------- | ------------------------------------------------------------------------------ |
| `Enabled`       | boolean             | Whether the connection can receive events.                                     |
| `ForeignState`  | boolean             | Whether the function was connected by a foreign Luau state (i.e. CoreScripts). |
| `LuaConnection` | boolean             | Whether the connection was created in Luau code and not by Roblox.             |
| `Function`      | function?           | The function bound to this connection. Nil when `ForeignState` is true.        |
| `Thread`        | thread?             | The thread that created the connection. Nil when `ForeignState` is true.       |
| `Script`        | LuaSourceContainer? | The script that created the connection.                                        |

| Method                | Description                                                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `Fire(...: any): ()`  | Fires this connection with the provided arguments.                                                                                   |
| `Defer(...: any): ()` | [Defers](https://devforum.roblox.com/t/beta-deferred-lua-event-handling/1240569) an event to connection with the provided arguments. |
| `Disconnect(): ()`    | Disconnects the connection.                                                                                                          |
| `Disable(): ()`       | Prevents the connection from firing.                                                                                                 |
| `Enable(): ()`        | Allows the connection to fire if it was previously disabled.                                                                         |

### Example

This script is a common anti-afk script. You will not be kicked for being afk (or "Idled").

```lua theme={null}
local connection = getconnections(game.Players.LocalPlayer.Idled)[1]
connection:Disable()
```

# getsignalarguments

> Returns a table of expected argument types for a given `RBXScriptSignal`.

```lua theme={null}
function getsignalarguments(signal: RBXScriptSignal): { string }
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The signal that will have it's arguments derived from.
</ResponseField>

### Example

```lua theme={null}
local signal = game.Players.LocalPlayer.Idled
local signalArguments = getsignalarguments(signal)

for _, argument in signalArguments do
    print(argument)
end
```

# getsignalargumentsinfo

> Returns a table of expected argument information for a given `RBXScriptSignal`. You can use this information to replicate signals.

```lua theme={null}
function getsignalargumentsinfo(signal: RBXScriptSignal): { ArgumentInfo }
```

<ResponseField name="signal" type="RBXScriptSignal" required="True">
  The signal that will have it's arguments derived from.
</ResponseField>

### Example

```lua theme={null}
local signal = game.Players.LocalPlayer.Idled
local signalArgumentInfo = getsignalargumentsinfo(signal)

for _, argumentInfo in signalArgumentInfo do
    print(argumentInfo)
end
```

# getsignalwhitelist

> Returns a table of `SignalWhitelistInfo` objects that are in Roblox's replication whitelist.

```lua theme={null}
function getsignalwhitelist(): { SignalWhitelistInfo }
```

### SignalWhitelistInfo

| Field    | Type     | Description        |
| -------- | -------- | ------------------ |
| `Parent` | `string` | Name of the signal |
| `Event`  | `string` | Name of the event  |

### Example

This example prints the names of all signals and events that are in Roblox's replication whitelist.

```lua theme={null}
local whitelist = getsignalwhitelist()
for _, signal in whitelist do
    print(string.format("%s.%s", signal.Parent, signal.Event))
end
```


---

# WebSocket Library

# WebSocket.connect

> Creates a `WebSocket` connection using the specified URL.

```lua theme={null}
function WebSocket.connect(url: string): WebSocket
```

<ResponseField name="url" type="string" required="True">
  The WebSocket URL that will be connected to.
</ResponseField>

<Tip>
  Alias: `WebSocket.new`
</Tip>

### Methods

| Method                      | Description                                    |
| --------------------------- | ---------------------------------------------- |
| `Send(message: string): ()` | Sends a message over the WebSocket connection. |
| `Close(): ()`               | Closes the WebSocket connection.               |

### Events

| Event                            | Description                                                     |
| -------------------------------- | --------------------------------------------------------------- |
| `OnMessage(message: string): ()` | Fired when a message is received over the WebSocket connection. |
| `OnClose(): ()`                  | Fired when the WebSocket connection is closed.                  |

### Example

This script creates a WebSocket connection, sends to the connection, and closes the connection.

```lua theme={null}
local ws = WebSocket.connect("wss://echo.websocket.org")
ws:Send("Hello, WebSocket!")
ws:Close()
```


---

# Drawing Objects

# Circle

### Circle

| Property  | Type      | Default      |
| --------- | --------- | ------------ |
| Position  | `Vector2` | Vector2.zero |
| Radius    | `number`  | 0            |
| Thickness | `number`  | 1            |
| Filled    | `boolean` | false        |
| NumSides  | `number`  | 250          |

# Font

### Font

| Property | Type     | Default |
| -------- | -------- | ------- |
| Data     | `string` | ""      |

# Image

### Image

| Property | Type      | Default           |
| -------- | --------- | ----------------- |
| Data     | `string`  | ""                |
| Size     | `Vector2` | Vector2.new(0, 0) |
| Position | `Vector2` | Vector2.new(0, 0) |
| Rounding | `number`  | 0                 |

# Line

### Line

| Property  | Type      | Default      |
| --------- | --------- | ------------ |
| From      | `Vector2` | Vector2.zero |
| To        | `Vector2` | Vector2.zero |
| Thickness | `number`  | 1            |

# Quad

### Quad

| Property  | Type      | Default      |
| --------- | --------- | ------------ |
| PointA    | `Vector2` | Vector2.zero |
| PointB    | `Vector2` | Vector2.zero |
| PointC    | `Vector2` | Vector2.zero |
| PointD    | `Vector2` | Vector2.zero |
| Thickness | `number`  | 1            |
| Filled    | `boolean` | false        |

# Square

### Square

| Property  | Type      | Default      |
| --------- | --------- | ------------ |
| Position  | `Vector2` | Vector2.zero |
| Size      | `Vector2` | Vector2.zero |
| Thickness | `number`  | 1            |
| Filled    | `boolean` | false        |

# Text

### Text

| Property     | Type      | Default             |
| ------------ | --------- | ------------------- |
| Text         | `string`  | ""                  |
| Size         | `number`  | 18                  |
| Center       | `boolean` | false               |
| Outline      | `boolean` | false               |
| OutlineColor | `Color3`  | Color3.new(0, 0, 0) |
| Position     | `Vector2` | Vector2.zero        |
| Font         | `number`  | 0                   |
| TextBounds   | `Vector2` | (Read Only)         |

# Triangle

### Triangle

| Property  | Type      | Default      |
| --------- | --------- | ------------ |
| PointA    | `Vector2` | Vector2.zero |
| PointB    | `Vector2` | Vector2.zero |
| PointC    | `Vector2` | Vector2.zero |
| Thickness | `number`  | 1            |
| Filled    | `boolean` | false        |

# Shader

> This object is meant for rendering HLSL shaders.

<Info>
  This object is new and subject to change; keep up with the documentation in case of changes.
</Info>

| Property | Type      | Default      |
| -------- | --------- | ------------ |
| Vertex   | `string`  | ""           |
| Pixel    | `string`  | ""           |
| Position | `Vector2` | Vector2.zero |
| Size     | `Vector2` | Vector2.zero |

| Method         | Description                                  |
| -------------- | -------------------------------------------- |
| `Create(): ()` | Builds the shader from `Vertex` and `Pixel`. |

## Things to keep in mind

* `Create` must be called every time after you change the `Vertex` and `Pixel` shaders.
* The entry points for the `Vertex` and `Pixel` shaders are called "main", you cannot change this.
* If `Size` is not set, the shader will take up the maximum available space of the game window.

## Tips

* To access the extra globals that Potassium gives to the GPU, define them as follows in your `Pixel` shader:

```js theme={null}
cbuffer Params : register(b0)
{
    float time;
    float2 resolution;
    float2 mouse;
};
```

## Wavey Sine Shader Example

```lua theme={null}
local shaderObject = Drawing.new("Shader")

shaderObject.Vertex = [[
struct VSOut
{
    float4 pos : SV_POSITION;
    float2 uv  : TEXCOORD0;
};

VSOut main(uint id : SV_VertexID)
{
    VSOut o;

    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2(-1.0,  3.0),
        float2( 3.0, -1.0)
    };

    float2 uv[3] = {
        float2(0.0, 1.0),
        float2(0.0, -1.0),
        float2(2.0, 1.0)
    };

    o.pos = float4(pos[id], 0.0, 1.0);
    o.uv  = uv[id];

    return o;
}]]

shaderObject.Pixel = [[
cbuffer Params : register(b0)
{
    float time;
   float2 resolution;
    float2 mouse;
};

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    float2 p = uv - 0.5;
    p *= 2.0;

    for (int i = 1; i < 5; i++)
    {
        float fi = (float)(i + 11);

        float2 freq  = float2(1.6, 1.1) * fi;
        float2 phase = time * (float)i * float2(3.4, 0.5) / 10.0;

        p += sin(p.yx * freq + phase) * 0.1;
    }

    float c = abs(sin(p.y) + sin(p.x)) * 0.5;

    return float4(c.xxx, 1.0);
}]]

shaderObject:Create()
```

