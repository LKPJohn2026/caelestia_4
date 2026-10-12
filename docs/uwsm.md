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
| EasyEffects | exec in `execs.lua` (if installed) | `caelestia4-easyeffects` (if installed), background-graphical.slice |
| Memory pressure | systemd-oomd watches the whole user slice (swap) | also `app-graphical.slice` (drop-in, 60 % pressure for 30 s): kills the one app scope causing it; the shell is in session-graphical.slice and is spared |
| Settings app, task manager, mixer, Bluetooth/network apps, recordings, `$` run commands | children of the shell | own unit each via `AppLauncher.exec` (survive a shell restart) |
| fcitx5, KDE Connect (+ indicator) | `custom/execs.lua` | `caelestia4-fcitx5`, `caelestia4-kdeconnectd`, `caelestia4-kdeconnect-indicator` |
| KWallet unlock, hypridle, ydotoold | exec | packaged `plasma-kwallet-pam`, `hypridle`, `ydotool` units, wanted by the target |
| Apps (keybinds via `launch_first_available.sh`, launcher, dock, session restore) | children of Hyprland / the shell | own unit each (`uwsm-app --`), app-graphical.slice |
| XDG autostart | not run | **masked** for Hyprland (`wayland-session-xdg-autostart@hyprland.desktop.target`) |
| Logout | logind Terminate | same (Caelestia session menu uses logind; uwsm-compatible). Don't use Hyprland's `exit`. |

All caelestia4 units are `WantedBy=graphical-session.target` with `ConditionEnvironment=CAELESTIA4_UWSM=1`: Plasma also
activates graphical-session.target, but never has that variable, so they're skipped there. They must **not** be wanted
by uwsm's `wayland-session@hyprland.desktop.target` (the first version did this): a target is implicitly ordered after
what it wants, uwsm orders graphical-session.target after that target, and the units are `After=graphical-session.target`,
so systemd found an ordering cycle at login and deleted the start jobs (no shell, hypridle, fcitx5, clipboard…).
Packaged units (hypridle, plasma-kwallet-pam, ydotool) can't take the condition (Plasma uses plasma-kwallet-pam), so
`execs.lua` starts them under uwsm. XDG autostart is masked because `XDG_CURRENT_DESKTOP=Hyprland:KDE` (needed so
Chromium/Electron use KWallet in both sessions) would make every `OnlyShowIn=KDE` entry (plasmashell, powerdevil,
kglobalacceld, polkit-kde-agent, xembedsniproxy…) match.

## Login screen
Only **Hyprland (uwsm-managed)** is shown. Plasma Login Manager lists every file in `/usr/share/wayland-sessions` and
ignores `NoDisplay`/`Hidden`, so the plain entry is removed (`NoExtract` in `/etc/pacman.conf` keeps upgrades from
restoring it). uwsm still needs a `hyprland.desktop` to start the compositor; it reads the private copy in
`~/.local/share/wayland-sessions/` (repo: `dots-extra/uwsm/`), which the login manager can't see. The plain session
still works from a TTY: `start-hyprland`.

## Handy commands
```
systemctl --user list-dependencies graphical-session.target | grep caelestia4
journalctl --user -b | grep -i "ordering cycle"   # must be empty
systemctl --user status caelestia4-shell        # or restart / stop
journalctl --user -u caelestia4-shell -f
systemctl --user list-units 'app-*' --type=scope # apps, one unit each
uwsm check is-active && echo "in uwsm"
oomctl                                           # app-graphical.slice should be listed under memory pressure
```
