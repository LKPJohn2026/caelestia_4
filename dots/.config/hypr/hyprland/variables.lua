-- Default variables
-- Copy these to ~/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- The folder within ~/.config/quickshell containing the config
hl.env("qsConfig", "ii")

-- Apps
-- PULL REQUESTS ADDING MORE WILL NOT BE ACCEPTED, CONFIG FOR YOURSELF
terminal = "uwsm-app -T" -- caelestia4: default terminal from ~/.config/xdg-terminals.list (Settings > Apps > Terminal)
-- caelestia4: Atlas first (Caelestia-style file manager, caelestia4-atlas package), then Thunar (no Dolphin: Plasma's)
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'atlas' 'thunar' 'nautilus' 'nemo' '@term yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'windsurf' 'antigravity' 'code' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' '@term nvim' '@term micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
-- caelestia4: Zed first (Kate went with the KDE apps), micro in a terminal last
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zeditor' 'zed' 'gnome-text-editor' 'emacs' '@term micro'"
volumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
-- caelestia4: Nexus, Caelestia's settings app (end-4's settings app was removed: Nexus has all of its rows)
settingsApp = "qs -c $qsConfig ipc call nexus open"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-system-monitor' '@term btop'"

workspaceGroupSize = 10
