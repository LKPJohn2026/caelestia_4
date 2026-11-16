-- caelestia4: lists the Hyprland shortcuts that ~/.config/hypr/hyprland/keybinds.lua and custom/keybinds.lua make, as
-- JSON on stdout, for Nexus > Hyprland > Keyboard shortcuts (nexus-keybinds.py runs it). It runs the two files with a
-- stand-in `hl` that only records each hl.bind, so loops come out as the binds they make and nothing is changed: no
-- commands run, no files are written. Usage: lua nexus-keybinds-dump.lua HYPR_DIR

local hypr = arg[1] or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
package.path = hypr .. "/?.lua;" .. hypr .. "/?/init.lua;" .. package.path

-- Nothing the config does while loading may reach the system
os.execute = function() return true end
os.remove = function() return true end
os.rename = function() return true end
io.popen = function() return nil end
local realOpen = io.open
io.open = function(name, mode)
    if mode and mode:find("[wa+]") then return nil end
    return realOpen(name, mode)
end

-- A stand-in for any hl value: indexing gives another one, calling one gives {dsp = "a.b.c", args = ...}
local function proxy(path)
    return setmetatable({}, {
        __index = function(_, k) return proxy(path == "" and k or (path .. "." .. k)) end,
        __call = function(_, ...)
            local a = select(1, ...)
            return { __dsp = path, args = type(a) == "table" and a or { a } }
        end,
    })
end

local binds = {}
local source = "default"
local submap = ""

hl = proxy("")
local real = {}
real.bind = function(keys, dsp, opts)
    local info = debug.getinfo(2, "Sl")
    binds[#binds + 1] = {
        keys = tostring(keys),
        dsp = dsp,
        opts = type(opts) == "table" and opts or {},
        submap = submap,
        source = source,
        file = info and info.short_src or "",
        line = info and info.currentline or 0,
    }
    return proxy("keybind")
end
real.unbind = function() end
real.define_submap = function(name, a, b)
    local fn = type(a) == "function" and a or b
    local prev = submap
    submap = tostring(name)
    if type(fn) == "function" then pcall(fn) end
    submap = prev
end
real.get_config = function() return 1 end
real.get_current_submap = function() return "" end
real.version = function() return "0" end
setmetatable(hl, { __index = function(_, k) return real[k] or proxy(k) end })

-- JSON out (strings, numbers, booleans, arrays, objects)
local function enc(v)
    local t = type(v)
    if t == "string" then
        return '"' .. v:gsub('[%c"\\]', function(c)
            local m = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t", ["\r"] = "\\r" }
            return m[c] or string.format("\\u%04x", c:byte())
        end) .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        if getmetatable(v) then return "null" end
        if #v > 0 or next(v) == nil then
            local out = {}
            for _, x in ipairs(v) do out[#out + 1] = enc(x) end
            return "[" .. table.concat(out, ",") .. "]"
        end
        local out = {}
        for k, x in pairs(v) do
            if type(k) == "string" then out[#out + 1] = enc(k) .. ":" .. enc(x) end
        end
        return "{" .. table.concat(out, ",") .. "}"
    end
    return "null"
end

-- A dispatcher as plain data: {name, args} where args keeps strings, numbers and booleans only
local function describe(dsp)
    if type(dsp) == "function" then return { name = "function" } end
    if type(dsp) ~= "table" or not dsp.__dsp then return { name = "unknown" } end
    local args = {}
    for k, x in pairs(dsp.args or {}) do
        local tx = type(x)
        if tx == "string" or tx == "number" or tx == "boolean" then args[tostring(k)] = x end
    end
    return { name = dsp.__dsp:gsub("^dsp%.", ""), args = args }
end

local errors = {}
local function load(file, mod, src)
    local f = realOpen(file, "r")
    if not f then return false end
    f:close()
    source = src
    package.loaded[mod] = nil
    local ok, err = pcall(require, mod)
    if not ok then errors[#errors + 1] = tostring(err) end
    return true
end

-- hyprland.lib first, as keybinds.lua expects; then its variables (keybinds.lua requires them itself)
pcall(require, "hyprland.lib")
HOME = os.getenv("HOME")
load(hypr .. "/hyprland/keybinds.lua", "hyprland.keybinds", "default")
load(hypr .. "/custom/keybinds.lua", "custom.keybinds", "custom")

local out = {}
for _, b in ipairs(binds) do
    local o = {}
    for k, x in pairs(b.opts) do
        local tx = type(x)
        if tx == "string" or tx == "number" or tx == "boolean" then o[k] = x end
    end
    out[#out + 1] = {
        keys = b.keys, action = describe(b.dsp), opts = o, submap = b.submap, source = b.source,
        file = b.file, line = b.line,
    }
end
io.write(enc({ binds = out, errors = errors }))
