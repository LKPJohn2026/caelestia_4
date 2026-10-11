HOME = os.getenv("HOME")

function is_file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then
      io.close(f)
      return true
   else
      return false
   end
end

function create_if_not_exists(path)
   if not is_file_exists(path) then
      os.execute("mkdir -p \"$(dirname \"" .. path .. "\")\"")
      os.execute("echo '-- This file will not be overwritten across dots-hyprland updates.\n-- The file name is for the sake of organization and does not matter\n-- See the corresponding files in ~/.config/hypr/hyprland for examples' > \"" .. path .. "\"")
      return true
   end
   return false
end

function workspace_in_group(i)
    local curr = hl.get_active_workspace().id
    local newVal = math.floor((curr - 1) / workspaceGroupSize) * workspaceGroupSize + i
    -- hl.notification.create({ text = "curr " .. curr .. " floor " .. math.floor(curr / 10) .. " new " .. newVal, duration = 5000 })
    return newVal
end

-- caelestia4: running in the uwsm-managed session ("Hyprland (uwsm-managed)" at login)? The marker comes from
-- ~/.config/uwsm/env-hyprland. Under uwsm, env lives in uwsm's env files, long-running things are systemd user
-- units (wanted by wayland-session@hyprland.desktop.target) and apps are started as their own units.
UWSM = os.getenv("CAELESTIA4_UWSM") == "1"

-- Command for launching an app: its own systemd scope under uwsm (app-graphical.slice), unchanged otherwise.
-- uwsm-app is uwsm's fast client (on-demand daemon), a drop-in for `uwsm app`.
function app(cmd)
    if UWSM then
        return "uwsm-app -- " .. cmd
    end
    return cmd
end

-- Same for background helpers (background-graphical.slice: low priority, non-interactive).
function bg(cmd)
    if UWSM then
        return "uwsm-app -s b -- " .. cmd
    end
    return cmd
end
