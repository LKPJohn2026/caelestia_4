# Installing caelestia_4

The result is a **Hyprland (uwsm-managed)** session on the login screen running the Caelestia-design shell on end-4's
illogical-impulse. It doesn't need KDE Plasma: it provides the login screen, key store, tray and Qt / GTK theming itself
(see below). Nothing here needs root except installing packages, the fonts and the login screen.

**Arch-based systems with systemd only** (`sdata/dist-*` for other distros come from end-4 and don't cover this fork).

> [!WARNING]
> Read the scripts before running them. Take a snapshot first if your system supports it (`snapper`, Timeshift…).

Clone with its submodule (`tools/install-main.sh` fetches it if you didn't; a zip of the repo won't work):

```bash
git clone --recursive https://github.com/LKPJohn2026/caelestia_4.git
```

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
4. **The packages built from this repo**: the Qt theme (qtengine), the Open / Save dialogs (Wormhole), the file manager
   (Atlas) and caelestia-cli, which makes the colour scheme (wallpaper colours and preset schemes) and themes btop,
   nvtop, Zed and Spotify. Without Atlas the shell uses the file manager it finds; without the CLI, colours fall back to
   end-4's matugen.
   ```bash
   for p in qtengine wormhole atlas cli; do (cd "packaging/caelestia4-$p" && makepkg -Csi); done
   ```
5. Optional, enables the matching features:
   - `gpu-screen-recorder` — screen recording with pause
   - `mpvpaper` — video wallpapers
   - `thunar thunar-volman tumbler gvfs` — a file manager to fall back on without Atlas
   - `spotify-launcher` + `spicetify-cli` (AUR) — Spotify with the Caelestia theme

## 2. Install

```bash
tools/build-caelestia-plugin.sh   # the Caelestia QML plugin, into ~/.local/lib/qt6/qml (no sudo)
tools/install-main.sh             # the configs and the uwsm session (tools/uwsm-setup.sh: env, user units, login entry);
                                  # backs up what it replaces to ~/.local/state/caelestia4/backup-*
```

Two steps that need sudo (each says what it does first):

```bash
tools/fonts-install.sh            # fonts no package provides (the lock screen's, the presets')
tools/greetd-setup.sh             # optional: the login screen (greetd + ReGreet), once the session has its colours
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
- **NVIDIA with an iGPU, monitors on the NVIDIA card** (optional): Hyprland picks a GPU by itself. If it picks the wrong
  one, `system/udev/99-caelestia4-dgpu.rules` gives the NVIDIA card a stable name and the session then renders on it
  (not for a laptop whose panel is on the iGPU).
- **Monitors**: Nexus → Display saves your layout to `~/.config/hypr/monitors.lua`; until then Hyprland uses each
  monitor's preferred mode at scale 1.

## Lock screen and suspend

The lock screen is hyprlock, run by `scripts/caelestia4/hyprlock-guard.sh`, which starts it again if it dies while the
session is locked. Its output and exits are in `journalctl -t hyprlock -t hyprlock-guard`; after a failure, Hyprland's
log is copied to `~/.local/state/caelestia4/hyprland-lockfail.log`.

The machine suspends after 15 idle minutes by default (Nexus → Power & idle).

**NVIDIA with a monitor that drops off its link on wake** (seen with a Samsung G95NC on DP 2.1): set suspend to "Never".
The monitor comes back, and Hyprland 0.57 disconnects a client that was drawing with NVIDIA's explicit sync at that
moment (`wp_linux_drm_syncobj_surface_v1 error 3: Missing buffer`). The victim varies: hyprlock (the "lock screen
died" screen) or Xwayland (every X11 app, Steam included, until you log out and back in; Hyprland doesn't start
Xwayland again). Locking and turning the screen off are safe: DPMS keeps the DP link up. A manual suspend can still hit
this. DPMS off/on doesn't reproduce it; test with `loginctl lock-session; sleep 2; systemctl suspend`.

If the lock screen died, from a TTY (Ctrl+Alt+F3):

```bash
hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'
hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'
```

Keep awake (utilities drawer) stops the automatic lock, screen off and suspend, not a manual lock or suspend. It is
turned off again in each new Hyprland session.

## Updating

```bash
git pull --recurse-submodules
tools/install-main.sh
```

It rebuilds the Caelestia plugin when its source changed and updates the session's env and units (log out and in for
those). XDG autostart was masked for this session by earlier versions, and stays so until you run
`systemctl --user unmask wayland-session-xdg-autostart@hyprland.desktop.target`.

If `git pull` says the histories diverged, one of two things happened:

- You have commits of your own and the repo moved on: `git pull --rebase` as usual.
- Your clone is from before 2026-11-06, when this repo's history was rewritten. It can't fast-forward, and merging would
  bring the old history back, so don't merge. This list shows the commits that are really yours:

  ```bash
  git fetch origin
  git log --cherry-pick --left-only --no-merges --oneline HEAD...origin/main
  ```

  Keep them on a branch, stash any uncommitted edits as the reset drops those too, then move to the new history:

  ```bash
  git branch backup-before-reset
  git stash
  git reset --hard origin/main
  git submodule update --init --recursive
  tools/install-main.sh
  ```

If a pull or update fails asking for a sign-in, GitHub may be limiting anonymous downloads for a while: try again later,
or sign in with `gh auth login`.

Maintainers: Caelestia is merged with `tools/sync-upstreams.sh`. end-4 is a vendored library since 2026-10-27, not an
upstream to merge: `tools/sync-end4.sh` lists its new commits (and open PRs) since `tools/end4-reviewed`, `pick SHA`
applies the chosen ones (changes to files removed here stay removed), `mark` records the review.

To stop personal data reaching a public push: `git config core.hooksPath tools/git-hooks`, and list one regex per line
in `${XDG_CONFIG_HOME:-~/.config}/caelestia4/push-denylist`, never in the repo. `tools/git-hooks/pre-push` then checks
what the remote's tracking refs don't have yet: names, emails, messages, tags, file names and added lines. It covers
this clone only, and says in its header what it can't see.

## Undo

- Other desktops keep working: log into them as usual. What's shared by the account: the flags files
  (`~/.config/*-flags.conf`) that set the browsers' key store.
- Restore from `~/.local/state/caelestia4/backup-*`, or delete
  `~/.config/{quickshell/ii,hypr,matugen,illogical-impulse,caelestia4}` and the `caelestia4-*` units in
  `~/.config/systemd/user/`.

## Without Plasma

docs/dev/kde-removal.md has how Plasma was replaced. What it provided, and what does it here:

| Plasma had | Here |
|---|---|
| Login screen (plasmalogin) | greetd + ReGreet in a Hyprland of its own: `tools/greetd-setup.sh` (re-run it to refresh its colours / wallpaper) |
| KWallet (Secret Service, unlocked at login) | gnome-keyring, unlocked by greetd's PAM; `tools/keyring-switch.sh` moves an existing KWallet's keys |
| Tray registry (kded6) | `caelestia4-sni-watcher` (docs/uwsm.md) |
| Qt theme / colours | qtengine (`packaging/caelestia4-qtengine`) + Darkly, colours from caelestia-cli (cli.json enableQt) |
| GTK theme / colours | adw-gtk3 + caelestia-cli's gtk.css (enableGtk) |
| KDE portal | Wormhole's Open / Save dialogs, GTK's as the fallback |

Chromium-based browsers and Electron apps read their keys with `--password-store=gnome-libsecret` (`install-main.sh`
writes the flags files you don't have; Claude's is its launcher, by `tools/keyring-switch.sh`): Chromium and Electron pick the key store from `XDG_CURRENT_DESKTOP`, and an unknown desktop (Hyprland) would give them
the unencrypted "basic" store. Before removing packages, check what pacman can't see: QML imports
(org.kde.syntaxhighlighting is one), commands the scripts call, Qt image plugins.
