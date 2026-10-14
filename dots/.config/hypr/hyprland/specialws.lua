-- caelestia4: Caelestia's special workspaces (caelestia-dots/caelestia hypr/utils/functions.lua `toggle`, f4bb062).
-- communication, music, sysmon and todo each open their app on first use; a toggle also gathers the app's stray
-- windows onto the workspace. Window rules in rules.lua send the apps there when they're started some other way.
--
-- Apps per workspace are upstream's defaults, merged with "toggles" from ~/.config/caelestia/cli.json (same file and
-- format as Caelestia), e.g. { "toggles": { "music": { "feishin": { "command": ["feishin"] } } } }.
-- An app: enable, match (list of window fields to match, any one), command (argv to start it), move (gather strays).
-- Changes from upstream: apps start as their own systemd unit (uwsm-app), btop runs in kitty, parse errors are
-- shown with notify-send (no caelestia CLI here).

local json = require("hyprland.lib.json") -- rxi's json.lua (MIT)

local config_dir = os.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")

local function default_config()
    return {
        communication = {
            discord  = { enable = true, match = { { class = "discord" } }, command = { "discord" }, move = true },
            whatsapp = { enable = true, match = { { class = "whatsapp" } }, move = true },
        },
        music = {
            spotify = {
                enable  = true,
                match   = { { class = "Spotify" }, { initial_title = "Spotify" }, { initial_title = "Spotify Free" } },
                -- As upstream: `spicetify watch -s` starts Spotify and re-applies the theme when its colours change;
                -- without spicetify, plain spotify-launcher (or the AUR spotify)
                command = { "sh", "-c", "command -v spicetify >/dev/null && exec spicetify watch -s; command -v spotify-launcher >/dev/null && exec spotify-launcher; exec spotify" },
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

-- Start what isn't running (its own unit, via uwsm), gather stray windows of what is
local function place_apps(apps, special_workspace)
    local target = "special:" .. special_workspace
    local clients = hl.get_windows() or {}

    for _, app_conf in pairs(apps) do
        if app_conf.enable then
            local running, windows = get_clients(clients, app_conf, special_workspace)
            if not running then
                if app_conf.command then
                    hl.dispatch(hl.dsp.exec_cmd(app(shell_join(app_conf.command)), { workspace = target }))
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

-- toggle("music"): show the music workspace (starting its apps), or hide it if it's the one shown.
-- toggle("specialws"): hide whichever special workspace is shown, else show the plain scratchpad ("special").
local function toggle(special_workspace)
    return function()
        local active = hl.get_active_special_workspace()

        if special_workspace == "specialws" then
            local target = active and active.name:gsub("^special:", "") or "special"
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
