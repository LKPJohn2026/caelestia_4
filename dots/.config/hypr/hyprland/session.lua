-- caelestia4: KDE-style session restore for Hyprland.
-- Remembers which apps are open and on which workspace, and at login reopens them on the same workspaces.
--  - Save: every SAVE_INTERVAL ms, once the window layout has stayed the same for one interval. Transient states
--    (apps closing during logout/shutdown) are therefore never saved.
--  - Restore: shortly after login, each saved app is relaunched through its .desktop entry (so flags files and
--    wrappers apply) or its original command line, and every new window of that app is moved to its saved workspace.
--    Apps that restore their own windows (browsers, Electron apps) are launched once; apps listed in MULTI_INSTANCE
--    (terminals, file managers) are launched once per saved window.
-- State: ~/.local/state/caelestia4/hypr-session.lua
-- Opt out: touch ~/.config/caelestia4/no-session-restore

local STATE_DIR = HOME .. "/.local/state/caelestia4"
local STATE_FILE = STATE_DIR .. "/hypr-session.lua"
local OPT_OUT = HOME .. "/.config/caelestia4/no-session-restore"

local SAVE_INTERVAL = 10000   -- ms
local RESTORE_DELAY = 2500    -- ms after login, so the shell and portals are up
local RESTORE_WINDOW = 60000  -- ms during which new windows are matched to saved workspaces

-- Windows that are never saved (Lua patterns, matched against the class)
local IGNORE = {
    "^$",
    "^org%.quickshell",
    "^xdg%-desktop%-portal",
    "polkit",
    "^org%.fcitx",
    "^org%.kde%.kdeconnect%.daemon$",
    "^c4test$",
}

-- Apps launched once per saved window (they don't restore their own windows)
local MULTI_INSTANCE = {
    ["kitty"] = true,
    ["foot"] = true,
    ["Alacritty"] = true,
    ["com.mitchellh.ghostty"] = true,
    ["org.wezfurlong.wezterm"] = true,
    ["org.kde.konsole"] = true,
    ["org.kde.dolphin"] = true,
    ["org.gnome.Nautilus"] = true,
    ["thunar"] = true,
}

local APP_DIRS = {
    HOME .. "/.local/share/applications",
    HOME .. "/.local/share/flatpak/exports/share/applications",
    "/var/lib/flatpak/exports/share/applications",
    "/usr/share/applications",
}

local function ignored(class)
    for _, pat in ipairs(IGNORE) do
        if class:match(pat) then
            return true
        end
    end
    return false
end

local function shell_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function read_first_line(cmd)
    local p = io.popen(cmd)
    if not p then
        return nil
    end
    local line = p:read("*l")
    p:close()
    if line and line ~= "" then
        return line
    end
    return nil
end

-- .desktop entry for a window class: StartupWMClass match first, then a file named after the class
local function desktop_id(class)
    local dirs = {}
    for _, d in ipairs(APP_DIRS) do
        dirs[#dirs + 1] = shell_quote(d)
    end
    dirs = table.concat(dirs, " ")
    local path = read_first_line("for d in " .. dirs .. "; do [ -d \"$d\" ] && grep -lixF "
        .. shell_quote("StartupWMClass=" .. class) .. " \"$d\"/*.desktop 2>/dev/null; done | head -n1")
        or read_first_line("for d in " .. dirs .. "; do [ -d \"$d\" ] && find \"$d\" -maxdepth 1 -iname "
            .. shell_quote(class .. ".desktop") .. " 2>/dev/null; done | head -n1")
    if path then
        return path:match("([^/]+)%.desktop$")
    end
    return nil
end

-- Original command line of a process, shell-quoted
local function proc_cmdline(pid)
    local f = io.open("/proc/" .. pid .. "/cmdline", "rb")
    if not f then
        return nil
    end
    local raw = f:read("*a")
    f:close()
    local args = {}
    for arg in raw:gmatch("([^%z]+)") do
        args[#args + 1] = shell_quote(arg)
    end
    if #args == 0 then
        return nil
    end
    return table.concat(args, " ")
end

local launch_cache = {} -- class -> launch command

local function launch_command(class, pid)
    if launch_cache[class] == nil then
        local id = desktop_id(class)
        if id then
            launch_cache[class] = "gtk-launch " .. shell_quote(id)
        else
            launch_cache[class] = proc_cmdline(pid) or false
        end
    end
    return launch_cache[class] or nil
end

-- ---------------------------------------------------------------- save

local restoring = false
local last_tick = nil  -- serialized layout seen at the previous tick
local last_saved = nil -- serialized layout last written to disk

local function serialize(list)
    local out = { "return {\n" }
    for _, e in ipairs(list) do
        out[#out + 1] = string.format("    { class = %q, workspace = %q, title = %q, cmd = %q },\n",
            e.class, e.workspace, e.title, e.cmd)
    end
    out[#out + 1] = "}\n"
    return table.concat(out)
end

local function layout()
    local list = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and w.workspace and not ignored(w.class) then
            list[#list + 1] = { class = w.class, workspace = w.workspace.name, title = w.title or "", pid = w.pid }
        end
    end
    table.sort(list, function(a, b)
        if a.workspace ~= b.workspace then
            return a.workspace < b.workspace
        end
        if a.class ~= b.class then
            return a.class < b.class
        end
        return a.pid < b.pid
    end)
    return list
end

-- Layout key without titles (titles change constantly, e.g. browser tabs)
local function layout_key(list)
    local parts = {}
    for _, e in ipairs(list) do
        parts[#parts + 1] = e.workspace .. "\t" .. e.class
    end
    return table.concat(parts, "\n")
end

local function save_tick()
    if restoring then
        return
    end
    local list = layout()
    local key = layout_key(list)
    local stable = key == last_tick
    last_tick = key
    if not stable or key == last_saved then
        return
    end
    for _, e in ipairs(list) do
        e.cmd = launch_command(e.class, e.pid) or ""
    end
    os.execute("mkdir -p " .. shell_quote(STATE_DIR))
    local tmp = STATE_FILE .. ".tmp"
    local f = io.open(tmp, "w")
    if not f then
        return
    end
    f:write(serialize(list))
    f:close()
    os.rename(tmp, STATE_FILE)
    last_saved = key
end

-- ---------------------------------------------------------------- restore

local pending = {} -- saved windows not placed yet

local function place(w)
    if not w or not w.class or #pending == 0 then
        return
    end
    -- Prefer an entry with the same title, else the first one of that class
    local idx = nil
    for i, e in ipairs(pending) do
        if e.class == w.class then
            if e.title == w.title then
                idx = i
                break
            end
            idx = idx or i
        end
    end
    if not idx then
        return
    end
    local e = table.remove(pending, idx)
    if w.workspace and w.workspace.name ~= e.workspace then
        hl.dispatch(hl.dsp.window.move({ workspace = e.workspace, window = "address:" .. w.address, follow = false }))
    end
end

local function restore()
    if restoring then
        return
    end
    local ok, saved = pcall(dofile, STATE_FILE)
    if not ok or type(saved) ~= "table" or #saved == 0 then
        return
    end
    restoring = true

    -- Launched apps ask for focus (xdg-activation); with misc.focus_on_activate that would pull the view to
    -- every restored workspace. Keep the user where they are until the restore window ends.
    local focus_on_activate = hl.get_config("misc.focus_on_activate")
    hl.config({ misc = { focus_on_activate = false } })

    for _, e in ipairs(saved) do
        pending[#pending + 1] = { class = e.class, workspace = e.workspace, title = e.title }
    end

    -- Windows already open (autostarted apps) just get moved
    local running = {}
    for _, w in ipairs(hl.get_windows()) do
        running[w.class] = true
        place(w)
    end

    local sub = hl.on("window.open", place)

    local launched = {}
    for _, e in ipairs(saved) do
        if e.cmd ~= "" and not running[e.class] then
            if MULTI_INSTANCE[e.class] or not launched[e.cmd] then
                launched[e.cmd] = true
                hl.exec_cmd(e.cmd, { workspace = e.workspace .. " silent" })
            end
        end
    end

    hl.timer(function()
        sub:remove()
        pending = {}
        restoring = false
        hl.config({ misc = { focus_on_activate = focus_on_activate } })
    end, { timeout = RESTORE_WINDOW, type = "oneshot" })
end

-- ---------------------------------------------------------------- wiring

-- Manual use: hyprctl dispatch 'function() C4_SESSION.save() end'   (or .restore())
C4_SESSION = {
    save = function()
        last_tick = layout_key(layout()) -- treat the current layout as stable
        last_saved = nil
        save_tick()
    end,
    restore = restore,
}

if not is_file_exists(OPT_OUT) then
    hl.on("hyprland.start", function()
        hl.timer(restore, { timeout = RESTORE_DELAY, type = "oneshot" })
    end)
    -- `hyprctl reload` starts a fresh Lua state, so this never runs twice
    hl.timer(save_tick, { timeout = SAVE_INTERVAL, type = "repeat" })
end
