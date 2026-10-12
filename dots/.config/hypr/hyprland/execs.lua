-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()
    -- caelestia4: uwsm-only. The shell, clipboard history, geoclue agent, fcitx5, KDE Connect and EasyEffects are
    -- systemd user units (tools/uwsm-setup.sh); uwsm exports the environment to systemd/D-Bus itself.
    if not UWSM then
        hl.exec_cmd("notify-send -u critical -a Hyprland 'Started without uwsm' 'This setup needs the \"Hyprland (uwsm-managed)\" session: log out and pick it at the login screen (or run: uwsm start hyprland.desktop).'")
        return
    end
    -- packaged units: no Plasma-excluding condition possible (Plasma uses plasma-kwallet-pam too), so start here
    hl.exec_cmd("systemctl --user start hypridle.service plasma-kwallet-pam.service ydotool.service")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    if not is_file_exists(HOME .. "/.config/caelestia4/shared-desktop") then
        hl.exec_cmd(bg("gnome-keyring-daemon --start --components=secrets"))
    end
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)

