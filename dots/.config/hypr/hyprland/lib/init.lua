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

-- caelestia4: this setup runs only as the uwsm-managed session ("Hyprland (uwsm-managed)" at login): env lives in
-- uwsm's env files, long-running things are systemd user units, apps are their own units. UWSM (marker from
-- ~/.config/uwsm/env-hyprland) is only used to warn when Hyprland was started some other way (execs.lua).
UWSM = os.getenv("CAELESTIA4_UWSM") == "1"

-- Command for launching an app: its own systemd scope (app-graphical.slice). uwsm-app is uwsm's fast client.
function app(cmd)
    return "uwsm-app -- " .. cmd
end

-- Same for background helpers (background-graphical.slice: low priority, non-interactive).
function bg(cmd)
    return "uwsm-app -s b -- " .. cmd
end
