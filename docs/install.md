# Installing caelestia_4

The result is a **Hyprland (uwsm-managed)** session on the login screen running the Caelestia-design shell on end-4's
illogical-impulse. It doesn't need KDE Plasma: it brings its own login screen, key store, tray and Qt / GTK theming
(see [Without Plasma](#without-plasma)).

**Arch-based systems with systemd only** (Arch, CachyOS, EndeavourOS…, x86_64). The `sdata/dist-*` folders for other
distros come from end-4 and don't cover this fork.

> [!WARNING]
> Read the scripts before running them. Take a snapshot first if your system supports it (`snapper`, Timeshift…).

## 1. Install

One command, as your user (not root; it asks for sudo when it needs it):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LKPJohn2026/caelestia_4/main/install.sh)
```

It clones the repo to `~/.local/share/caelestia_4` (`C4_DIR=… ` before the command to put it elsewhere) and runs its
`install.sh`. Or clone it yourself, with its submodule (a zip of the repo won't work):

```bash
git clone --recursive https://github.com/LKPJohn2026/caelestia_4.git
cd caelestia_4
./install.sh
```

`./install.sh --dry-run` prints every command without running any, `./install.sh --list-deps` the packages it would
install, `./install.sh -h` the other options. Everything it prints goes to `~/.local/state/caelestia4/install-*.log`.

What it does, in order, asking before anything you might not want:

1. Checks the system (Arch-based, systemd, x86_64, 8 GB free, your user session) and updates it (`pacman -Syu`), with
   `base-devel` and `git`.
2. Uses `yay` or `paru` for the AUR packages; with neither, asks to build `yay-bin`.
3. Asks to remove what would conflict: other builds of the packages it makes itself (end-4's
   `illogical-impulse-quickshell-git` or another Quickshell, caelestia-cli, qtengine, Atlas, Wormhole, the Bibata cursor),
   PulseAudio and its modules (PipeWire replaces it), and what the AUR packages conflict with (`darkly` for
   `darkly-bin`, `yq` for `go-yq`…). pacman replaces each in the same transaction that installs what replaces it, so a
   build or download that fails leaves it in place, and pacman refuses when another package still needs the old one.
4. Installs the dependencies (below) and builds this repo's packages. A re-run skips the ones already at their version,
   except the ones using Qt's private API when Qt moved to a new minor release (those are built again).
5. Turns on Bluetooth and NetworkManager. If another network service runs here (systemd-networkd, iwd alone, dhcpcd,
   connman), NetworkManager stays off and it tells you how to switch: Nexus and the bar show no networks without it.
6. Installs the fonts no package has (`tools/fonts-install.sh`) and the configs (`tools/install-main.sh`, no sudo,
   backs up what it replaces to `~/.local/state/caelestia4/backup-*`).
7. The login screen: if you have one (SDDM, GDM, LightDM…), it stays. With none, it asks to set up **greetd +
   ReGreet** (`tools/greetd-setup.sh`). `--no-login` skips this step.

Reboot (or log out) and pick **Hyprland (uwsm-managed)**. The shell runs as the `caelestia4-shell` user unit
(`systemctl --user restart caelestia4-shell`, or Ctrl+Super+R). After the first login, `tools/greetd-setup.sh` again
gives the login screen your colours and wallpaper.

The configs have to be in `~/.config`: with `XDG_CONFIG_HOME` set to anywhere else the installers stop without changing
anything. `XDG_CACHE_HOME` can be anywhere, and so can `XDG_STATE_HOME`, set the same in the session and for the
installer, which links `~/.local/state/quickshell` and `caelestia` to it for what can only name those.

`install-main.sh` never overwrites your own files: `~/.config/hypr/custom/`, `monitors.lua`, `workspaces.lua` and the
configs of apps it themes (btop, cava, fastfetch, Zen…) are only created when missing.

## 2. What gets installed

All of it comes from PKGBUILDs in this repo, which you can read first. `./install.sh --list-deps` prints the exact list.

| | What | From |
|---|---|---|
| **Session** | Hyprland ≥ 0.55 (the config is Lua), uwsm, hypridle, hyprlock, hyprpicker, hyprsunset, xdg-desktop-portal-hyprland | repos |
| **end-4's dependencies** | metapackages in `sdata/dist-arch/illogical-impulse-*`: audio (PipeWire, cava…), backlight, basic tools, fonts and themes, hyprland, kde (`gnome-keyring`, NetworkManager), portals, Python, screen capture (grim, slurp, gpu-screen-recorder…), toolkit, widgets, MicroTeX, the Bibata cursor | repos + AUR |
| **This fork's** | `sdata/dist-arch/illogical-impulse-caelestia4`: the plugin's build tools, `bluez`, `btop`, `ddcutil`, `socat`, `uwsm`… | repos + AUR |
| **Built here** | `packaging/caelestia4-*`: Quickshell pinned to a known-good commit, the Qt theme (qtengine), the Open / Save dialogs (Wormhole), the file manager (Atlas), caelestia-cli (colour schemes, app themes); and the Caelestia QML plugin, into `~/.local/lib/qt6/qml` | built with `makepkg` |
| **From the AUR** | `breeze-plus`, `darkly-bin`, `libcava`, `otf-space-grotesk`, `python-materialyoucolor`, `qt6-m3shapes-git`, `ttf-readex-pro`, `ttf-rubik-vf`, `ttf-twemoji` (and `wlogout` on plain Arch; CachyOS has it) | yay / paru |
| **Login screen** (only without one) | `greetd`, `greetd-regreet` | repos |
| **Services** | `bluetooth`, `NetworkManager` | enabled |

About 1.5 GB of downloads and 6 GB of disk (it checks for 8 GB free). Quickshell and the Caelestia plugin use Qt's private API: **after every Qt minor
update, both are built again**: `./install.sh` notices it (as does Nexus > Updates, see [Updating](#updating));
`./install.sh --rebuild` builds everything of this repo again regardless.

Optional, enables the matching features:

- `mpvpaper` — video wallpapers
- `thunar thunar-volman tumbler gvfs` — a file manager to fall back on without Atlas
- `spotify-launcher` + `spicetify-cli` (AUR) — Spotify with the Caelestia theme

### Install by hand

What `install.sh` runs, for when you'd rather do each step yourself. The AUR packages (the row above) can't be fetched
by `makepkg -s`: install them with an AUR helper first. `./install.sh --list-deps` lists them for this system.

```bash
sudo pacman -Syu --needed base-devel git
yay -S --needed --asdeps $(./install.sh --list-deps | sed -n '/^# from the AUR/,/^# built/{/^#/d;p}')
for m in audio backlight basic fonts-themes kde portal python screencapture toolkit widgets hyprland caelestia4 \
         microtex-git bibata-modern-classic-bin; do (cd "sdata/dist-arch/illogical-impulse-$m" && makepkg -Csi); done
for p in quickshell qtengine wormhole atlas cli; do (cd "packaging/caelestia4-$p" && makepkg -Csi); done
sudo systemctl enable --now bluetooth NetworkManager
tools/fonts-install.sh            # sudo: fonts no package provides (the lock screen's, the presets')
tools/install-main.sh             # no sudo: the plugin, the configs and the uwsm session
tools/greetd-setup.sh             # optional, sudo: the login screen (greetd + ReGreet)
```

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

**Packages:** Nexus > Updates > *Update everything* (or the bar's updates popout) runs
`~/.config/quickshell/ii/scripts/caelestia4/system-update.sh` in a terminal, with no questions: repo packages, then AUR
packages, then this repo's Qt packages and the Caelestia plugin if Qt moved to a new minor release. After such a rebuild
it restarts the shell, unless a window is fullscreen, the screen is locked or your clone has local changes, when a
notification tells you to. The terminal closes by itself on success and stays open on a failure; the log is `~/.local/state/caelestia4/update.log`. For
no password either, once:

```bash
sudo tools/update-sudo-rule.sh enable
```

> [!WARNING]
> Both skip a safeguard. AUR packages are built and installed without you seeing their build scripts, and a malicious one
> can run code as root. The password rule is close to root for every program under your account, because `pacman -U`
> installs any package. `sudo tools/update-sudo-rule.sh disable` turns the rule off.

Some things still stop the update for you to look at, like a package conflict that would need removing something.

**caelestia_4 itself:**

```bash
cd ~/.local/share/caelestia_4   # or your clone
git pull --recurse-submodules
./install.sh
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
  ./install.sh
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
| Login screen (plasmalogin) | greetd + ReGreet in a Hyprland of its own: `tools/greetd-setup.sh` (re-run it to refresh its colours / wallpaper), or the login screen you already have |
| KWallet (Secret Service, unlocked at login) | gnome-keyring, unlocked by the login screen's PAM; `tools/keyring-switch.sh` moves an existing KWallet's keys |
| Tray registry (kded6) | `caelestia4-sni-watcher` (docs/uwsm.md) |
| Qt theme / colours | qtengine (`packaging/caelestia4-qtengine`) + Darkly, colours from caelestia-cli (cli.json enableQt) |
| GTK theme / colours | adw-gtk3 + caelestia-cli's gtk.css (enableGtk) |
| KDE portal | Wormhole's Open / Save dialogs, GTK's as the fallback |

Chromium-based browsers and Electron apps read their keys with `--password-store=gnome-libsecret` (`install-main.sh`
writes the flags files you don't have; Claude's is its launcher, by `tools/keyring-switch.sh`): Chromium and Electron pick the key store from `XDG_CURRENT_DESKTOP`, and an unknown desktop (Hyprland) would give them
the unencrypted "basic" store. Before removing packages, check what pacman can't see: QML imports
(org.kde.syntaxhighlighting is one), commands the scripts call, Qt image plugins.
