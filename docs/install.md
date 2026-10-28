# Installing caelestia_4

The result is a **Hyprland (uwsm-managed)** session on the login screen running the Caelestia-design shell on end-4's
illogical-impulse. It no longer shares an account with KDE Plasma: since 2026-10-28 it provides what Plasma did itself
(login screen, key store, tray, Qt / GTK theming; see below). Nothing here needs root except installing packages.

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
5. **caelestia-cli** (AUR), which makes the colour scheme (wallpaper colours and preset schemes) and themes btop,
   nvtop, Zed and Spotify: `yay -S caelestia-cli`. Without it, colours fall back to end-4's matugen.
6. Optional, enables the matching features:
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
configs of apps it themes (btop, cava, fastfetch, Zen…) are only created when missing.

## 3. One-time choices after the first login

- **Settings** (Super+I): Nexus, Caelestia's control centre; it has every row end-4's settings app had (that app
  was removed 2026-10-27).
- **Colours**: Nexus → Wallpaper & style → Colours: follow the wallpaper, or a preset scheme.
- **Editors / apps themed by Caelestia's integrations**: pick the theme named **Caelestia** once in VS Code / Cursor /
  VSCodium and Zed; restart Zen once.
- **Brave's frame colour** (Brave and Brave Origin) follows the scheme through a browser policy; allow it once:
  `sudo install -d -o "$USER" /etc/brave/policies/managed`
- **Discord**: with Vesktop (or Vencord / Equicord / Equibop / BetterDiscord / Legcord), enable the theme
  **Midnight (Caelestia)** once in its Settings > Themes; caelestia-cli keeps its colours in step (it needs `dart-sass`).
- **Spotify**: open it once and log in, then `spicetify config spotify_path ~/.local/share/spotify-launcher/install/usr/share/spotify prefs_path ~/.config/spotify/prefs`
  and `tools/install-main.sh` again (it sets the theme); after Spotify updates itself, run `spicetify backup apply`.
- **NVIDIA with an iGPU** (optional): `system/udev/99-caelestia4-dgpu.rules` gives the discrete GPU a stable name.

## Updating

```bash
git pull
tools/install-main.sh
```

Maintainers: Caelestia is merged with `tools/sync-upstreams.sh`. end-4 is a vendored library since 2026-10-27, not an
upstream to merge: `tools/sync-end4.sh` lists its new commits (and open PRs) since `tools/end4-reviewed`, `pick SHA`
applies the chosen ones (changes to files removed here stay removed), `mark` records the review.

## Undo

- Other desktops were not changed: log into them as usual.
- Restore from `~/.local/state/caelestia4/backup-*`, or delete
  `~/.config/{quickshell/ii,hypr,matugen,illogical-impulse,caelestia4}` and the `caelestia4-*` units in
  `~/.config/systemd/user/`.

## Without Plasma

Plasma was removed on 2026-10-28 (docs/dev/kde-removal.md has the plan, what went wrong and how it was checked). What
it provided, and what does it here:

| Plasma had | Here |
|---|---|
| Login screen (plasmalogin) | greetd + ReGreet in a Hyprland of its own: `tools/greetd-setup.sh` (re-run it to refresh its colours / wallpaper) |
| KWallet (Secret Service, unlocked at login) | gnome-keyring, unlocked by greetd's PAM; `tools/keyring-switch.sh` moved KWallet's keys |
| Tray registry (kded6) | `caelestia4-sni-watcher` (docs/uwsm.md) |
| Qt theme / colours | qtengine (`packaging/caelestia4-qtengine`) + Darkly, colours from caelestia-cli (cli.json enableQt) |
| GTK theme / colours | adw-gtk3 + caelestia-cli's gtk.css (enableGtk) |
| KDE portal | Wormhole's Open / Save dialogs, GTK's as the fallback |

Brave, Vesktop and Claude read their keys with `--password-store=gnome-libsecret` (their flags files / launcher):
Chromium and Electron pick the key store from `XDG_CURRENT_DESKTOP`, and an unknown desktop (Hyprland) would give them
the unencrypted "basic" store. Before removing packages, check what pacman can't see: QML imports
(org.kde.syntaxhighlighting is one), commands the scripts call, Qt image plugins.
