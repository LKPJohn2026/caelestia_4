-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()
    -- caelestia4: uwsm-only. The shell, clipboard history, geoclue agent, fcitx5, KDE Connect and EasyEffects are
    -- systemd user units (tools/uwsm-setup.sh); uwsm exports the environment to systemd/D-Bus itself.
    if not UWSM then
        hl.exec_cmd("notify-send -u critical -a Hyprland 'Started without uwsm' 'This setup needs the \"Hyprland (uwsm-managed)\" session: log out and pick it at the login screen (or run: uwsm start hyprland.desktop).'")
        return
    end
    -- packaged units, started here (they can't take the uwsm-only condition); KWallet's PAM unit is gone with Plasma
    -- (the keys are in gnome-keyring, which PAM unlocks itself: docs/dev/kde-removal.md)
    hl.exec_cmd("systemctl --user start hypridle.service ydotool.service")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    if not is_file_exists(HOME .. "/.config/caelestia4/shared-desktop") then
        hl.exec_cmd(bg("gnome-keyring-daemon --start --components=secrets"))
    end
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)

