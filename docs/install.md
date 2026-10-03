# Installing caelestia_4 on an account that also uses Plasma

Result: a **"Hyprland" session** on the login screen running end-4 + the caelestia family, next to Plasma (Oxygen),
on the same user account. Plasma's settings are not touched.

## What is shared between Plasma and the Hyprland session (and how it's protected)
| Shared thing | Risk | Protection |
|---|---|---|
| Secret Service (`org.freedesktop.secrets`) | end-4 starts gnome-keyring → KWallet logins (e.g. `gh` token) unreachable | `gnome-keyring-daemon.socket/.service` masked for the user + D-Bus override → `ksecretd` (docs/phase0.md); end-4's `gnome-keyring --start` skipped when the marker exists (`hypr/hyprland/execs.lua`) |
| `~/.config/kdeglobals` | end-4 installer + `switchwall.sh` (kde-material-you-colors) rewrite it | installer not used; `switchwall.sh` skips it when the marker exists |
| GTK theme (`gsettings gtk-theme/color-scheme`) | `switchwall.sh` sets `adw-gtk3(-dark)` on every wallpaper change | skipped when the marker exists |
| `~/.config/gtk-{3,4}.0/gtk.css` | matugen GTK templates overwrite them | removed from the installed `matugen/config.toml` |
| VS Code / VSCodium `settings.json` | `material-code-set-color.sh` edits colours | skipped when the marker exists |
| fish, starship, fontconfig, mpv, Konsole, Dolphin, Kvantum, Darkly | end-4 ships configs for these | **not installed** |
| Open terminals (`/dev/pts/*`) | `applycolor.sh` sends colour escape codes to every terminal, incl. Plasma's if both sessions run at once | not patched: cosmetic, transient |
| kded6 | end-4 `ConflictKiller` can kill it (Plasma needs it) | `autoKillTrays: false` (shows a dialog at most) |

**Marker file:** `~/.config/caelestia4/shared-desktop` (created by the installer). Delete it on a Hyprland-only account to get end-4's normal behaviour back.

**KDE/Qt apps in Hyprland** use `QT_QPA_PLATFORMTHEME=kde`, so they show your **Plasma (Oxygen) colours**, not the wallpaper colours. That's by design (PLAN §7 open question 1, option a).

## Steps
1. **Snapshot:** `sudo snapper create -d "caelestia_4: before main-account install"`
2. **Stable GPU name (recommended):**
   `sudo install -m644 system/udev/99-caelestia4-dgpu.rules /etc/udev/rules.d/ && sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=drm`
   then `ls -l /dev/dri/nvidia-dgpu` should point at card1 (RTX 5090).
3. **Packages** are already present from the e4test install: `hyprland`, end-4's `illogical-impulse-*`, `caelestia4-quickshell`, `qt6-m3shapes-git`, `aubio`, `libcava`.
4. **Install (no sudo):** `tools/install-main.sh`. Backups go to `~/.local/state/caelestia4/backup-*`.
5. Log out → login screen → **Hyprland** session. The shell starts in the caelestia family (Ctrl+Super+P cycles).

## Updating
`git pull` (or merge upstream with `tools/sync-upstreams.sh`), then `tools/install-main.sh` again. Your `hypr/custom/`, `monitors.lua` and `workspaces.lua` are kept.

## Undo
- Log into Plasma as usual: nothing there was changed.
- To remove the Hyprland setup: restore from `~/.local/state/caelestia4/backup-*`, or delete `~/.config/{quickshell/ii,hypr,matugen,illogical-impulse,caelestia4}`.
- The snapshot from step 1 covers system-level changes (udev rule).

## Install log: main account (2026-10-03) ✅
- Snapshot taken; udev rule installed → `/dev/dri/nvidia-dgpu -> card1` (nvidia, PCI 0000:01:00.0). It applied on install; the reload/trigger was a no-op.
- `tools/install-main.sh`: no warnings. Only the old auto-generated `~/.config/hypr/hyprland.lua` needed a backup. Plasma files (`kdeglobals`, `kwinrc`, `plasmarc`, GTK `settings.ini`) are byte-identical to the `oxygen-plasma` backup.
  - `kdeglobals` mtime changed to 08:17:17 during the install with identical content. Most likely KDE re-saved it after the new icon in `~/.local/share/icons` appeared; the script doesn't open it.
- **First Hyprland login:**
  - Hyprland: Lua config loaded, `hyprctl configerrors` empty; `drm: Explicit device list /dev/dri/nvidia-dgpu` → card1 / nvidia-drm; DP-2 7680×2160@240, scale 1.5. VRR off (end-4 default `misc:vrr = 0`).
  - Shell: config loaded first time; probe 18/18; only end-4 upstream warnings (`Notifications.qml[70] isTransient`, Hyprland IPC "openwindow for workspace 1 not tracked").
  - Shell env: `AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu`, `QML_IMPORT_PATH=~/.local/lib/qt6/qml`, `QT_QPA_PLATFORMTHEME=kde`.
  - Secrets: `org.freedesktop.secrets` owned by **ksecretd**; `gh auth status` OK in the Hyprland session. The only gnome-keyring process belongs to `e4test`.
