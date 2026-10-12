-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()
    -- caelestia4: uwsm session: the shell, clipboard history, idle daemon, audio effects and the geoclue agent are
    -- systemd user units wanted by wayland-session@hyprland.desktop.target (tools/uwsm-setup.sh); uwsm also exports
    -- the environment to systemd/D-Bus itself. Only one-shot setup is left here.
    if UWSM then
        -- packaged units: no Plasma-excluding condition possible (Plasma uses plasma-kwallet-pam too), so start here
        hl.exec_cmd("systemctl --user start hypridle.service plasma-kwallet-pam.service ydotool.service")
        hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
        if not is_file_exists(HOME .. "/.config/caelestia4/shared-desktop") then
            hl.exec_cmd(bg("gnome-keyring-daemon --start --components=secrets"))
        end
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
        return
    end


    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c $qsConfig")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    -- caelestia4: on an account shared with Plasma (marker file), KWallet owns org.freedesktop.secrets.
    -- Starting gnome-keyring here would take the secrets name and hide KWallet's stored logins.
    if not is_file_exists(HOME .. "/.config/caelestia4/shared-desktop") then
        hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    end
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    -- caelestia4: only if installed (optional; end-4 started it unconditionally and it failed silently)
    hl.exec_cmd("command -v easyeffects >/dev/null && easyeffects --hide-window --service-mode")

    -- Clipboard: history
    --hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
