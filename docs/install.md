# Installing caelestia_4

The result is a **Hyprland (uwsm-managed)** session on the login screen running the Caelestia-design shell on end-4's
illogical-impulse, next to any other desktop you already use (it was built on an account that also runs KDE Plasma,
and leaves Plasma's settings alone). Nothing here needs root except installing packages.

> [!WARNING]
> Read the scripts before running them. Take a snapshot first if your system supports it (`snapper`, Timeshift…).

## 1. Dependencies (Arch / CachyOS)

1. **Hyprland ≥ 0.55** (the config is Lua) and **uwsm**:
   ```bash
   sudo pacman -S --needed hyprland uwsm
   ```
2. **end-4's dependency metapackages** (local PKGBUILDs in `sdata/dist-arch`; they pull some AUR packages, so read
   them). Only the dependency step of end-4's installer, which copies no configs:
   ```bash
   ./setup install-deps
   ```
   See [the illogical-impulse wiki](https://ii.clsty.link/en/ii-qs/01setup/) for what they contain.
3. **Quickshell** built for your Qt version. `packaging/caelestia4-quickshell` pins a known-good commit and replaces
   end-4's `illogical-impulse-quickshell-git` (accept the removal when pacman asks):
   ```bash
   cd packaging/caelestia4-quickshell && makepkg -Csi
   ```
   Quickshell and the Caelestia plugin use Qt's private API: **rebuild both after every Qt minor update**
   (`makepkg -Cf` here, then `tools/build-caelestia-plugin.sh`).
4. **qt6-m3shapes-git** (AUR), used by Caelestia's shapes: `yay -S qt6-m3shapes-git`
5. Optional, enables the matching features:
   - `gpu-screen-recorder` — screen recording with pause
   - `mpvpaper` — video wallpapers
   - `thunar thunar-volman tumbler gvfs` — the file manager the session uses
   - `spotify-launcher` + `spicetify-cli` (AUR) — Spotify with the Caelestia theme

## 2. Install

```bash
tools/build-caelestia-plugin.sh   # the Caelestia QML plugin, into ~/.local/lib/qt6/qml (no sudo)
tools/install-main.sh             # the configs; backs up what it replaces to ~/.local/state/caelestia4/backup-*
tools/uwsm-setup.sh               # the uwsm session: env, systemd user units, login entry
```

Log out and pick **Hyprland (uwsm-managed)**. The shell runs as the `caelestia4-shell` user unit
(`systemctl --user restart caelestia4-shell`, or Ctrl+Super+R).

`install-main.sh` never overwrites your own files: `~/.config/hypr/custom/`, `monitors.lua`, `workspaces.lua` and the
configs of apps it themes (btop, cava, fastfetch, Zen…) are only created when missing. It also creates
`~/.config/caelestia4/shared-desktop`, which tells the patched end-4 scripts to leave other desktops' settings alone
(see below). Delete that file on an account that only uses this session to get end-4's normal behaviour back.

## 3. One-time choices after the first login

- **Settings app** (Super+I): appearance, desktop widgets, bar, dock, idle times, apps.
- **Colours**: Nexus → Wallpaper & style → Colours: follow the wallpaper, or a preset scheme.
- **Editors / apps themed by Caelestia's integrations**: pick the theme named **Caelestia** once in VS Code / Cursor /
  VSCodium and Zed; restart Zen once.
- **Brave's frame colour** follows the scheme through a browser policy; allow it once:
  `sudo install -d -o "$USER" /etc/brave/policies/managed`
- **Spotify**: open it once and log in, then `spicetify config spotify_path ~/.local/share/spotify-launcher/install/usr/share/spotify prefs_path ~/.config/spotify/prefs`
  and `tools/install-main.sh` again (it sets the theme); after Spotify updates itself, run `spicetify backup apply`.
- **NVIDIA with an iGPU** (optional): `system/udev/99-caelestia4-dgpu.rules` gives the discrete GPU a stable name.

## Updating

```bash
git pull
tools/install-main.sh
```

Maintainers merge upstream with `tools/sync-end4.sh` (end-4) and `tools/sync-upstreams.sh` (Caelestia).

## Undo

- Other desktops were not changed: log into them as usual.
- Restore from `~/.local/state/caelestia4/backup-*`, or delete
  `~/.config/{quickshell/ii,hypr,matugen,illogical-impulse,caelestia4}` and the `caelestia4-*` units in
  `~/.config/systemd/user/`.

## Sharing an account with KDE Plasma

| Shared thing | Risk | Protection |
|---|---|---|
| Secret Service (`org.freedesktop.secrets`) | end-4 starts gnome-keyring, so KWallet logins become unreachable | mask `gnome-keyring-daemon.socket/.service` for the user (the installer warns if it isn't); end-4's keyring start is skipped with the marker |
| `~/.config/kdeglobals` | `switchwall.sh` (kde-material-you-colors) rewrites it | skipped with the marker |
| GTK theme (`gsettings gtk-theme/color-scheme`) | set on every wallpaper change | skipped with the marker |
| `~/.config/gtk-{3,4}.0/gtk.css` | matugen GTK templates overwrite them | not in the installed matugen config; only a Thunar-only `@import "thunar.css"` is added |
| VS Code settings | end-4's colour script edits `settings.json` | skipped with the marker; the Caelestia extension themes it instead |
| fish, starship, mpv, Konsole, Dolphin, Kvantum, Darkly configs | end-4 ships them | not installed |
| Open terminals | `applycolor.sh` sends colour codes to every terminal, Plasma's too if both sessions run | cosmetic |
| kded6 | end-4's conflict killer could stop it (Plasma needs it; it also serves the tray) | disabled |
| File associations | | Thunar is the folder handler only in this session (`~/.config/hyprland-mimeapps.list`) |

KDE / Qt apps in this session use `QT_QPA_PLATFORMTHEME=kde`, so they keep Plasma's colours.
