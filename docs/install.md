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

## Main-account extras (2026-10-03)
- **VRR:** `~/.config/hypr/custom/general.lua` → `misc.vrr = 2` (fullscreen only). Applied live with `hyprctl reload`; no config errors.
- **gnome-keyring removed:** `sdata/dist-arch/illogical-impulse-kde/PKGBUILD` pkgrel 4 drops the `gnome-keyring` dependency (KWallet `provides=org.freedesktop.secrets`, which satisfies `qtkeychain-qt6`). `pacman -Rns gnome-keyring` also removes `gcr` (only needed by gnome-keyring). The user-level mask + D-Bus override stay as a guard.
- **fcitx5 + Bamboo (Vietnamese):**
  - Hyprland: `custom/env.lua` sets `XMODIFIERS=@im=fcitx`, `QT_IM_MODULE=fcitx`, `QT_IM_MODULES=wayland;fcitx`, `SDL_IM_MODULE=fcitx` (no `GTK_IM_MODULE`: GTK uses Wayland text-input); `custom/execs.lua` runs `fcitx5 -d --replace`.
  - Plasma: KWin "Virtual Keyboard" = Fcitx 5.
  - Shared profile `~/.config/fcitx5/profile` (keyboard-us + bamboo, `DefaultIM=bamboo`) and `~/.config/fcitx5/config` (trigger = `Super+space`, `ShareInputState=All`).
  - **Super+Space** toggles US ⇄ Bamboo. Plasma: fcitx5's own trigger key (KWin `[Wayland] InputMethod` = `org.fcitx.Fcitx5.desktop`). Hyprland: `custom/keybinds.lua` binds `SUPER + Space` → `fcitx5-remote -t` (works in every window) plus `quickshell:searchToggleReleaseInterrupt` so the Super-tap launcher does not open.
  - Chromium/Electron apps need `--enable-wayland-ime` (set for Brave and Obsidian in their flags files).
- **KDE Connect in Hyprland:**
  - `custom/execs.lua` runs `kdeconnectd` + `kdeconnect-indicator` (tray) (Hyprland has no XDG autostart; pairings shared with Plasma).
  - Remote input via AUR `hypr-kdeconnect-fix-git`, routed only in `~/.config/xdg-desktop-portal/hyprland-portals.conf` (`org.freedesktop.impl.portal.RemoteDesktop = hypr-kdeconnect`).
  - **Caveats (from its README):** no permission dialog (any portal client can inject input in the Hyprland session); "99% vibe coded … manually audited".
- **KWallet unlock + logins kept across sessions:**
  - Cause 1, password prompts in Hyprland: Plasma Login Manager's PAM (`/usr/lib/pam.d/plasmalogin`) already runs `pam_kwallet5`, but the session must then run `/usr/lib/pam_kwallet_init` (Plasma autostarts it). Hyprland didn't, so a second D-Bus-activated `ksecretd` asked for the password. Fixed: `custom/execs.lua` runs it first. The wallet password must equal the login password, or PAM can't unlock it.
  - Cause 2, logged out after switching: Chromium/Electron apps get their cookie key from the Secret portal (KWallet in Plasma), but Hyprland had no Secret backend. They fell back to a different libsecret key, and cookies from the other session couldn't be decrypted. Fixed: `hyprland-portals.conf` adds `org.freedesktop.impl.portal.Secret = kwallet`, and the fallback backend is pinned with `--password-store=kwallet6` (`~/.config/brave-origin-flags.conf`, `~/.config/obsidian/user-flags.conf`, `~/.cursor/argv.json`). Claude Desktop relies on the portal.
- **Brave Sync broken after switching sessions (follow-up):** not the profile lock (`SingletonLock` → `<host>-<pid>` of the running Brave is normal; it only matters if Brave is still running in another session). Cause: Brave's web-app shortcuts in `~/.local/share/applications/brave-*-Default.desktop` run `/opt/brave-origin-bin/brave-origin`. That skips `/usr/bin/brave-origin` and therefore `~/.config/brave-origin-flags.conf` (`--password-store=kwallet6`). Brave started from them in Hyprland used the libsecret key instead of KWallet. The Sync encryption token in `Default/Preferences` (`sync.encryption_bootstrap_token_per_account`, `v11` = os_crypt) written in one session then can't be decrypted in the other. Fixed: the shortcuts' `Exec` now points to `/usr/bin/brave-origin` (backup in `~/.local/state/caelestia4/backup-brave-pwa-*`). New web apps installed later get the `/opt` path again and need the same edit.
- **Logins still lost after switching + Brave Sync still rejected (follow-up 2, 2026-10-04):** measured by decrypting with each wallet key (`tools/brave-rekey.py` reports and fixes it):
  - Brave cookies were on the KWallet key, but the sync chain seed (`brave_sync_v2.seed`), the sync token, 39 saved passwords and a few hashes were still on the libsecret key, written by Hyprland Brave launches without the flag. So sync was rejected and saved passwords were unreadable.
  - Claude Desktop (no flags file) used the libsecret key in Hyprland and the KWallet key in Plasma, so it was logged out on every switch.
  - Root fix, no per-app flags: Chromium/Electron choose the key store from `XDG_CURRENT_DESKTOP`, read as a list. `custom/env.lua` now sets `XDG_CURRENT_DESKTOP=Hyprland:KDE` + `KDE_SESSION_VERSION=6`. Verified with a throwaway Brave profile: with `Hyprland` it never contacts KWallet; with `Hyprland:KDE` it uses `org.kde.kwalletd6`. Portals still read `hyprland-portals.conf` first; Qt already used `QT_QPA_PLATFORMTHEME=kde`.
  - Data repair: `tools/brave-rekey.py --apply` (Brave closed) re-encrypted those 52 items from the libsecret key to the KWallet key. Backup in `~/.local/state/caelestia4/backup-brave-rekey-*`; a re-scan finds 0 left. Claude Desktop needs one more sign-in after the next Hyprland login.
- **Test user `e4test` removed.** To test builds before the main account again, create a throwaway user and use `tools/stage-for-test.sh`.

## Session restore (2026-10-03)
KDE-style "reopen my apps on the same workspaces" for the Hyprland session: `dots/.config/hypr/hyprland/session.lua`
(loaded from `hyprland.lua`), all inside Hyprland's Lua config, with no extra daemon or package.
- Why not an AUR tool: hyprsession / hyprdrover / hyprflow (0–1 votes) predate Hyprland 0.56's Lua config and use
  `hyprctl dispatch <legacy-dispatcher>`, which 0.56 rejects (`dispatch` is now `hl.dispatch(...)`).
- **Save:** every 10 s, `hl.get_windows()` → class + workspace + title, plus a launch command: the `.desktop`
  entry, matched by `StartupWMClass` or file name and run with `gtk-launch` so flags files and wrappers apply, or else
  `/proc/<pid>/cmdline`. A layout is only written after it stayed the same for one tick, so the windows closing during
  logout/shutdown are never saved. File: `~/.local/state/caelestia4/hypr-session.lua`.
- **Restore** (2.5 s after login): launch each saved app with `hl.exec_cmd(cmd, { workspace = "N silent" })`.
  For 60 s, every new window of a saved class is moved to its saved workspace (title match preferred). Apps
  already open (autostarted) are moved, not relaunched. Browsers/Electron apps are launched once and restore their
  own windows; terminals and file managers (`MULTI_INSTANCE`) are launched once per saved window.
- `misc.focus_on_activate` is switched off during the 60 s window; otherwise each launched app's activation
  request pulls the view to its workspace.
- Manual: `hyprctl dispatch 'function() C4_SESSION.save() end'` (or `.restore()`). Opt out:
  `touch ~/.config/caelestia4/no-session-restore`.
- Tested live: a kitty pair saved on workspaces 4 and 5, closed, then restored to 4 and 5, with the active workspace unchanged.
- Limits: restores which apps are open and their workspaces, not window sizes or positions, and not documents/tabs
  (apps do that themselves, e.g. Brave "Continue where you left off").
