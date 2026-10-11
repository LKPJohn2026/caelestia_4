# uwsm-managed Hyprland session (2026-10-11)

"Hyprland (uwsm-managed)" at the login screen runs Hyprland under [uwsm](https://github.com/Vladimir-csp/uwsm):
the compositor, the shell and every app are systemd user units. The plain "Hyprland" entry still works as before;
the config checks `CAELESTIA4_UWSM` (set only by uwsm's env file) and switches behaviour.

## Setup
```
sudo pacman -S --needed uwsm
tools/uwsm-setup.sh        # idempotent
```
Then log out and pick **Hyprland (uwsm-managed)**.

## What changes under uwsm
| | plain Hyprland | uwsm |
|---|---|---|
| Environment | `hypr/hyprland/env.lua`, `hypr/custom/env.lua` (`hl.env`) | `~/.config/uwsm/env-hyprland` (repo: `dots/.config/uwsm/`) + `env-hyprland.d/caelestia4-local.sh` (repo: `dots-extra/uwsm/`), exported to systemd/D-Bus |
| Shell | child of Hyprland | `caelestia4-shell.service` (Restart=on-failure, journald, session-graphical.slice); Ctrl+Super+R restarts the unit |
| Clipboard history, GeoClue agent | exec in `execs.lua` | `caelestia4-cliphist@{text,image}`, `caelestia4-geoclue-agent` |
| fcitx5, KDE Connect (+ indicator) | `custom/execs.lua` | `caelestia4-fcitx5`, `caelestia4-kdeconnectd`, `caelestia4-kdeconnect-indicator` |
| KWallet unlock, hypridle, ydotoold | exec | packaged `plasma-kwallet-pam`, `hypridle`, `ydotool` units, wanted by the target |
| Apps (keybinds via `launch_first_available.sh`, launcher, dock, session restore) | children of Hyprland / the shell | own unit each (`uwsm-app --`), app-graphical.slice |
| XDG autostart | not run | **masked** for Hyprland (`wayland-session-xdg-autostart@hyprland.desktop.target`) |
| Logout | logind Terminate | same (Caelestia session menu uses logind; uwsm-compatible). Don't use Hyprland's `exit`. |

All caelestia4 units are `WantedBy=wayland-session@hyprland.desktop.target`, uwsm's per-compositor target, not
`graphical-session.target`: Plasma also activates graphical-session.target, so anything wanted by it would start in
Plasma too. Same reason XDG autostart is masked: `XDG_CURRENT_DESKTOP=Hyprland:KDE` (needed so Chromium/Electron use
KWallet in both sessions) would make every `OnlyShowIn=KDE` entry (plasmashell, powerdevil, kglobalacceld,
polkit-kde-agent, xembedsniproxy…) match.

## Handy commands
```
systemctl --user list-dependencies wayland-session@hyprland.desktop.target
systemctl --user status caelestia4-shell        # or restart / stop
journalctl --user -u caelestia4-shell -f
systemctl --user list-units 'app-*' --type=scope # apps, one unit each
uwsm check is-active && echo "in uwsm"
```
