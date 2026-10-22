-- caelestia4: Caelestia's window resizer (caelestia-dots/caelestia f4bb062: hypr/hyprland/execs.lua listeners +
-- utils/functions.lua resizer / move_actions). Window rules only apply when a window opens, but some windows get
-- their real title or class later (browser picture-in-picture, extension popups), so these re-run on every class,
-- title or tag change and resize / float / move the window then.
--   - Picture-in-picture: floated, pinned, a quarter of the screen height, bottom-right corner
--   - Bitwarden (app, Firefox and Chromium extension popups): floated, centred, 20% x 54% of the screen
--   - Windows tagged float_50_60 / float_60_70 / float_70_80 (e.g. from custom/rules.lua): floated, centred, that size
-- Keys: Super+Alt+Backslash makes the focused window a picture-in-picture; Ctrl+Super+Alt+Backslash resets it
-- to 55% x 70% of the screen, centred.

-- {x, y} in pixels for x% / y% of the focused monitor (0 = full size on that axis), or nil for 0 x 0
local function resize_by_screen(x, y)
    local screen = hl.get_active_monitor()
    if screen and type(screen.width) == "number" and type(screen.height) == "number" and not (x == 0 and y == 0) then
        local w = (x and x > 0) and math.floor(screen.width * x / 100) or screen.width
        local h = (y and y > 0) and math.floor(screen.height * y / 100) or screen.height
        return { x = w, y = h, relative = false }
    end
end

-- When `matches(window)`: run `actions` (one dispatcher or a list), then resize to x% / y% of the screen
local function resizer(window, matches, x_percent, y_percent, actions)
    if window and matches(window) then
        local list = (type(actions) == "table") and actions or { actions }
        for _, a in ipairs(list) do
            hl.dispatch(a)
        end
        -- Target the window explicitly; without window= the focused one would be resized instead
        local size = resize_by_screen(x_percent, y_percent)
        if size then
            size.window = window
            hl.dispatch(hl.dsp.window.resize(size))
        end
    end
end

-- Dispatchers that shrink a window to a quarter of the screen height (aspect kept) in the bottom-right corner
local function pip_actions(win)
    local screen = hl.get_active_monitor()
    if not (screen and screen.width and screen.height and win and win.size) then
        return nil
    end
    local monitor_height = screen.height / screen.scale
    local monitor_width  = screen.width / screen.scale
    local scale_factor   = (monitor_height / 4) / win.size.y
    local width          = math.floor(math.max(200, win.size.x * scale_factor))
    local height         = math.floor(math.max(150, win.size.y * scale_factor))
    local offset         = math.min(monitor_width, monitor_height) * 0.03
    return {
        hl.dsp.window.resize({ x = width, y = height, window = win }),
        hl.dsp.window.move({
            x = math.floor(screen.x + monitor_width - width - offset),
            y = math.floor(screen.y + monitor_height - height - offset),
            relative = false,
            window = win,
        }),
        hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true", window = win }),
    }
end

-- Deferred picture-in-picture placement, at most one pending per window (the timer is kept referenced here)
local pip_pending = {}

local function schedule_pip(win)
    local id = win.stable_id
    if pip_pending[id] then
        return
    end
    pip_pending[id] = hl.timer(function()
        pip_pending[id] = nil
        for _, w in ipairs(hl.get_windows() or {}) do
            if w.stable_id == id then
                for _, action in ipairs(pip_actions(w) or {}) do
                    hl.dispatch(action)
                end
                return
            end
        end
    end, { timeout = 300, type = "oneshot" })
end

local function apply_rules(win)
    local match_str = function(pattern, field, plain)
        return function(w)
            return w[field] and string.find(w[field], pattern, 1, plain)
        end
    end
    local match_title = function(pattern, plain) return match_str(pattern, "title", plain) end
    local match_class = function(pattern, plain) return match_str(pattern, "class", plain) end
    local match_tag = function(tag)
        return function(w)
            for _, t in ipairs(w.tags or {}) do
                if t == tag or t == tag .. "*" then
                    return true
                end
            end
            return false
        end
    end

    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }

    -- Bitwarden: native app, Firefox extension popup, Chromium extension popup
    resizer(win, match_class("Bitwarden", true), 20, 54, float_center)
    resizer(win, match_title("^Extension: %(Bitwarden Password Manager%) %- Bitwarden", false), 20, 54, float_center)
    resizer(win, match_class("nngceckbapebfimnlniiiahkandclblb", true), 20, 54, float_center)

    -- Picture in picture. Float and pin now: window rules' float / pin only apply when a window opens, and browsers
    -- can set the "Picture-in-Picture" title after that (resizing a tiled window would just move the split).
    -- Shrink and move a moment later: on open the window doesn't have its own size (the video's aspect) yet.
    -- Whole title only (upstream 4f7407c): a tab about picture-in-picture is not a PiP window
    if match_title("^Picture[- ]in[- ][Pp]icture$", false)(win) then
        if not win.floating then
            hl.dispatch(hl.dsp.window.float({ action = "on", window = win }))
        end
        if not win.pinned then
            hl.dispatch(hl.dsp.window.pin({ action = "on", window = win }))
        end
        schedule_pip(win)
    end

    -- Size tags
    resizer(win, match_tag("float_60_70"), 60, 70, float_center)
    resizer(win, match_tag("float_70_80"), 70, 80, float_center)
    resizer(win, match_tag("float_50_60"), 50, 60, float_center)
end

hl.on("window.class", apply_rules)
hl.on("window.title", apply_rules)
hl.on("window.open", apply_rules)

-- Tags have no change event: compare them on every rule update
local last_tags = {}

local function tag_key(tags)
    local copy = {}
    for _, tag in ipairs(tags or {}) do
        copy[#copy + 1] = tag:gsub("%*$", "")
    end
    table.sort(copy)
    return table.concat(copy, "\0")
end

hl.on("window.update_rules", function(win)
    local key = tag_key(win.tags)
    if last_tags[win.stable_id] ~= key then
        last_tags[win.stable_id] = key
        apply_rules(win)
    end
end)

hl.on("window.close", function(win)
    last_tags[win.stable_id] = nil
end)

-- Keys
hl.bind("SUPER + ALT + Backslash", function()
    local a = hl.get_active_window()
    if a then
        local actions = pip_actions(a) or {}
        if not a.floating then
            table.insert(actions, 1, hl.dsp.window.float())
        end
        table.insert(actions, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))
        for _, x in ipairs(actions) do
            hl.dispatch(x)
        end
    end
end, { description = "Window: Picture-in-picture (corner, pinned)" })

hl.bind("CTRL + SUPER + ALT + Backslash", function()
    hl.dispatch(hl.dsp.window.resize(resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end, { description = "Window: Reset size (55% x 70%, centred)" })
