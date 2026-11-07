-- caelestia4: Caelestia's special workspaces (caelestia-dots/caelestia hypr/utils/functions.lua `toggle`, f4bb062).
-- communication, music, sysmon and todo each open their app on first use; a toggle also gathers the app's stray
-- windows onto the workspace. Window rules in rules.lua send the apps there when they're started some other way.
--
-- Apps per workspace are upstream's defaults, merged with "toggles" from ~/.config/caelestia/cli.json (same file and
-- format as Caelestia), e.g. { "toggles": { "music": { "feishin": { "command": ["feishin"] } } } }.
-- An app: enable, match (list of window fields to match, any one), command (argv to start it), move (gather strays).
-- An app may give "commands" instead: alternatives, the first one installed is started ("command" wins if set).
-- Changes from upstream: apps start as their own systemd unit (uwsm-app), btop runs in kitty, parse errors and apps
-- that aren't installed are shown with notify-send (no caelestia CLI here), Discord's clients count as Discord, and
-- Super+S with nothing shown and an empty scratchpad shows the special workspace used last.

local json = require("hyprland.lib.json") -- rxi's json.lua (MIT)

local config_dir = os.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")

local function default_config()
    return {
        communication = {
            -- (Vesktop and Equibop are Discord clients: one of them is what runs here more often than not)
            discord  = {
                enable   = true,
                match    = { { class = "discord" }, { class = "vesktop" }, { class = "equibop" } },
                commands = { { "vesktop" }, { "equibop" }, { "discord" } },
                move     = true,
            },
            whatsapp = { enable = true, match = { { class = "whatsapp" } }, move = true },
        },
        music = {
            spotify = {
                enable  = true,
                match   = { { class = "Spotify" }, { initial_title = "Spotify" }, { initial_title = "Spotify Free" } },
                -- As upstream: `spicetify watch -s` starts Spotify and re-applies the theme when its colours change;
                -- without spicetify, plain spotify-launcher (or the AUR spotify)
                -- (no exec on spicetify: before the first login it exits with "Can't find offline.bnk", then the
                -- plain launcher still opens Spotify; the theme is patched into Spotify's files either way)
                command = { "sh", "-c", "command -v spicetify >/dev/null && spicetify watch -s && exit; command -v spotify-launcher >/dev/null && exec spotify-launcher; exec spotify" },
                move    = true,
            },
            feishin = { enable = true, match = { { class = "feishin" } }, move = true },
        },
        sysmon = {
            btop = {
                enable  = true,
                match   = { { class = "btop", title = "btop", workspace = { name = "special:sysmon" } } },
                command = { "kitty", "--class", "btop", "--title", "btop", "btop" },
            },
        },
        todo = {
            todoist = { enable = true, match = { { class = "todoist" } }, command = { "todoist" }, move = true },
        },
    }
end

local function merge(default_conf, user_conf)
    for category, apps in pairs(user_conf) do
        default_conf[category] = default_conf[category] or {}
        for app_name, options in pairs(apps) do
            default_conf[category][app_name] = default_conf[category][app_name] or {}
            for key, value in pairs(options) do
                default_conf[category][app_name][key] = value
            end
            -- caelestia4: a match of one's own with no command of one's own: the default alternatives would start an
            -- app that match doesn't see as running, again on every toggle
            if type(options) == "table" and options.match and options.command == nil and options.commands == nil then
                default_conf[category][app_name].commands = nil
            end
        end
    end
end

-- A field of a Hyprland object, also trying snake_case for camelCase keys (initialTitle -> initial_title)
local function get_field(obj, key)
    local value = obj[key]
    if value == nil and type(key) == "string" then
        value = obj[(key:gsub("(%u)", "_%1")):lower()]
    end
    return value
end

local function deep_match(actual, expected)
    if type(expected) == "table" then
        if type(actual) ~= "table" and type(actual) ~= "userdata" then
            return false
        end
        for key, sub_expected in pairs(expected) do
            if not deep_match(get_field(actual, key), sub_expected) then
                return false
            end
        end
        return true
    end
    return actual and string.find(tostring(actual), tostring(expected), 1, true)
end

-- Is the app running, and its windows (with whether each is already on the special workspace)
local function get_clients(clients, app_config, target_special)
    local matched = {}
    if not (app_config and app_config.match) then
        return false, matched
    end
    for _, window in ipairs(clients) do
        for _, rule in ipairs(app_config.match) do
            local ok = true
            for key, expected in pairs(rule) do
                if not deep_match(get_field(window, key), expected) then
                    ok = false
                    break
                end
            end
            if ok then
                local ws = window.workspace and window.workspace.name
                table.insert(matched, { window = window, is_in_place = (ws == "special:" .. target_special) })
                break
            end
        end
    end
    return #matched > 0, matched
end

local function shell_join(argv)
    local quoted = {}
    for i, arg in ipairs(argv) do
        quoted[i] = "'" .. tostring(arg):gsub("'", [['"'"']]) .. "'"
    end
    return table.concat(quoted, " ")
end

local function load_config()
    local config = default_config()
    local f = io.open(config_dir .. "/caelestia/cli.json", "r")
    if not f then
        return config
    end
    local content = f:read("*a")
    f:close()

    local ok, conf_or_err = pcall(json.decode, content)
    if ok and type(conf_or_err) == "table" then
        merge(config, conf_or_err.toggles or {})
    else
        local reason = ok and "Expected a JSON object" or tostring(conf_or_err):gsub("^.-:%d+: ", "")
        hl.exec_cmd("notify-send -u critical -a Hyprland " ..
            shell_join({ "Special workspaces: can't read ~/.config/caelestia/cli.json", reason }))
    end
    return config
end

-- Whether argv[1] is a program on PATH (or a path to one): a plain look, nothing is run in the compositor
local function installed(argv)
    local cmd = type(argv) == "table" and argv[1]
    if type(cmd) ~= "string" or cmd == "" then
        return false
    end
    if cmd:find("/", 1, true) then
        return is_file_exists(cmd)
    end
    for dir in (os.getenv("PATH") or "/usr/bin"):gmatch("[^:]+") do
        if is_file_exists(dir .. "/" .. cmd) then
            return true
        end
    end
    return false
end

-- What to start for an app: its command, else the first of its commands that is installed. nil and the names tried
-- when nothing is
-- (An entry not shaped ["prog", "arg"...] in cli.json counts as malformed, rather than failing the whole keybind)
local function app_command(app_conf)
    local tried, malformed = {}, false
    local commands = app_conf.command and { app_conf.command } or app_conf.commands
    for _, argv in ipairs(type(commands) == "table" and commands or {}) do
        if installed(argv) then
            return argv, tried, malformed
        elseif type(argv) == "table" and type(argv[1]) == "string" then
            table.insert(tried, argv[1])
        else
            malformed = true
        end
    end
    return nil, tried, malformed
end

-- Start what isn't running (its own unit, via uwsm), gather stray windows of what is
local function place_apps(apps, special_workspace)
    local target = "special:" .. special_workspace
    local clients = hl.get_windows() or {}

    for app_name, app_conf in pairs(apps) do
        if app_conf.enable then
            local running, windows = get_clients(clients, app_conf, special_workspace)
            if not running then
                local argv, tried, malformed = app_command(app_conf)
                if argv then
                    hl.dispatch(hl.dsp.exec_cmd(app(shell_join(argv)), { workspace = target }))
                elseif malformed then
                    hl.exec_cmd("notify-send -a Hyprland " .. shell_join({ "Special workspaces: \"" .. app_name .. "\" in ~/.config/caelestia/cli.json",
                        "Its command must be a list: [\"program\", \"arg\", ...]" }))
                elseif #tried > 0 then
                    hl.exec_cmd("notify-send -a Hyprland " .. shell_join({ "Special workspaces: " .. table.concat(tried, ", ") ..
                        " isn't installed", "Install it, or set another app under \"toggles\" in ~/.config/caelestia/cli.json" }))
                end
            elseif app_conf.move then
                for _, w in ipairs(windows) do
                    if not w.is_in_place then
                        hl.dispatch(hl.dsp.window.move({ window = w.window, workspace = target, follow = false }))
                    end
                end
            end
        end
    end
end

-- Upstream's specialWsCloseAny = false (b476a36): Super+S only toggles the scratchpad. Set with this file
-- (Nexus > Hyprland > "Super+S closes any special workspace"), read on every press
local SCRATCHPAD_ONLY = config_dir .. "/caelestia4/special-ws-scratchpad-only"

-- toggle("music"): show the music workspace (starting its apps), or hide it if it's the one shown.
-- The special workspace with the window focused last (focus history: 0 is the latest, -1 never), other than the
-- scratchpad, and whether the scratchpad has windows
local function specials_in_use()
    local last, last_id, scratchpad = nil, nil, false
    for _, w in ipairs(hl.get_windows() or {}) do
        local ws = w.workspace
        if ws and ws.special then
            if ws.name == "special:special" then
                scratchpad = true
            else
                local id = w.focus_history_id or -1
                local rank = id >= 0 and id or math.huge
                if not last_id or rank < last_id then
                    last, last_id = ws.name, rank
                end
            end
        end
    end
    return last, scratchpad
end

-- toggle("specialws"): hide whichever special workspace is shown; else show the scratchpad ("special") if it has
-- windows, else the special workspace used last, else the empty scratchpad. With SCRATCHPAD_ONLY, toggle the
-- scratchpad whatever is shown.
local function toggle(special_workspace)
    return function()
        local active = hl.get_active_special_workspace()

        if special_workspace == "specialws" then
            local target = "special"
            if not is_file_exists(SCRATCHPAD_ONLY) then
                if active then
                    target = active.name:gsub("^special:", "")
                else
                    local last, scratchpad = specials_in_use()
                    if not scratchpad and last then
                        target = last:gsub("^special:", "")
                    end
                end
            end
            return hl.dispatch(hl.dsp.workspace.toggle_special(target))
        end

        local on_it = active and active.name == "special:" .. special_workspace
        if not on_it then
            hl.dispatch(hl.dsp.focus({ workspace = "special:" .. special_workspace }))
        end

        local apps = load_config()[special_workspace]
        if apps then
            place_apps(apps, special_workspace)
        end

        if on_it then
            hl.dispatch(hl.dsp.workspace.toggle_special(special_workspace))
        end
    end
end

return { toggle = toggle }
