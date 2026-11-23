# Installing caelestia_4

The result is a **Hyprland (uwsm-managed)** session on the login screen running the Caelestia-design shell on end-4's
illogical-impulse. It doesn't need KDE Plasma: it brings its own login screen, key store, tray and Qt / GTK theming
(see [Without Plasma](#without-plasma)).

**Arch-based systems with systemd only** (Arch, CachyOS, EndeavourOS…, x86_64). Other distros aren't supported.

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
configs of apps it themes (btop, cava, fastfetch, Zen…) are only created when missing. [Who owns which
file](#who-owns-which-file) has the full list.

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

**NVIDIA with a monitor that drops off its link on wake** (seen on DisplayPort 2.1): set suspend to "Never".
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
`~/.config/quickshell/ii/scripts/caelestia4/system-update.sh` in a terminal, with no questions besides the password: repo
packages, then AUR
packages, then this repo's Qt packages and the Caelestia plugin if Qt moved to a new minor release. After such a rebuild
it restarts the shell, unless a window is fullscreen, the screen is locked or your clone has local changes, when a
notification tells you to. The terminal closes by itself on success and stays open on a failure; the log is
`~/.local/state/caelestia4/update.log`. Without a password rule it asks for the password once, at the start. For the
repo upgrade with no password, once:

```bash
sudo tools/update-sudo-rule.sh enable
```

The rule names two commands exactly, with no wildcards: `pacman -Syu --noconfirm` (the repo upgrade) and
`pacman -Sy --needed --noconfirm` with the keyrings the update refreshes first (`archlinux-keyring`, `cachyos-keyring`,
when installed), each also as `systemd-run --scope --quiet --collect /usr/bin/pacman …`, which is how the update runs
them. These install only signed packages from the repos in `/etc/pacman.conf`, so nothing under your account can
become root through the rule. Everything else still asks: the update asks for the password right before the AUR step
(yay, paru) or a rebuild of this repo's Qt packages, and only when that step has something to do. Refused, the AUR
packages are left for next time, a rebuild that couldn't install is reported like a failed one, and that run doesn't ask
again.

> [!WARNING]
> *Update everything* skips a safeguard: AUR packages are built and installed without you seeing their build scripts,
> and a malicious one can run code as root. Turn the rule off with `sudo tools/update-sudo-rule.sh disable` or the
> *Repo upgrades without a password* switch in Nexus > Updates. `tools/update-sudo-rule.sh status` says `on (split)`,
> `off`, or `on (pacman-wide, …)` when pacman runs with any arguments: that is close to root for every program under
> your account, as `pacman -U` installs any package. If it names the older rule this tool made, run
> `sudo tools/update-sudo-rule.sh enable` again (or turn the switch off and on) to replace it. If it names another
> sudoers file, neither can change that file: edit it with `sudo visudo -f <file>`. Until then the update works as
> before, asking nothing. When sudo doesn't say (it lists rules only with a password, `Defaults listpw`, or it isn't
> sudo 1.9's format, such as sudo-rs), status says `can't tell (…)` and the update asks for the password at the start;
> `sudo tools/update-sudo-rule.sh status` also says whether the rule file is there, and whether it is the older one.

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
applies the chosen ones (changes to files removed here stay removed; one that adds or changes anything under
`.github/`, `tools/`, `packaging/` or `sdata/`, or any executable or link, is left staged and listed until you say yes,
and no hook runs while it picks), `mark` records the review.

To stop personal data reaching a public push: run `tools/git-hooks/install.sh`, and list one regex per line in
`${XDG_CONFIG_HOME:-~/.config}/caelestia4/push-denylist`, never in the repo. The script copies `tools/git-hooks/pre-push`
into the clone's `.git/hooks/` (and unsets a `core.hooksPath` that points into the tree, as these docs once said to set:
hooks run from the tree are whatever the checked-out commit holds, so a PR branch or an upstream pick could run its own
on checkout, or switch the check off). The copy then checks what the remote's tracking refs don't have yet: names,
emails, messages, tags, file names and added lines. It covers this clone only, says in its header what it can't see, and
changes only when the script is run again: do that after reading a change to the hook. Never point `core.hooksPath` at
a folder in the tree.

## Who owns which file

What `tools/install-main.sh` (and `tools/uwsm-setup.sh`, which it runs) does to your home folder on every install and
update. It first copies `~/.config/quickshell/ii`, `~/.config/hypr`, `~/.config/matugen` and the browsers'
flags files it edits to `~/.local/state/caelestia4/backup-*`; nothing else it changes is backed up.

**Replaced every time** (edits there are lost, and files you add are deleted):

- `~/.config/quickshell/ii/`: the shell.
- `~/.config/hypr/` (`hyprland.lua`, `hyprland/`, `hypridle.conf`, `hyprlock.conf`, `hyprlock/`…), except the files
  listed under "Created when missing" below.
- `~/.config/matugen/`, with its GTK templates taken out.
- `~/.config/uwsm/env-hyprland`, `~/.config/systemd/user/caelestia4-*` and the `*.slice.d` drop-ins next to them.
- `~/.config/caelestia4/repo` (where your clone is), the Caelestia plugin in `~/.local/lib/qt6/qml/Caelestia` (when its
  source or Qt changed) and end-4's Python venv in `~/.local/state/quickshell/.venv` (when its requirements changed).
- `~/.config/hypr/hyprlock/strings.conf` and `layout.conf`, made again from the shell's language and your screens.

**Created when missing, then yours:**

- `~/.config/hypr/custom/` (put your own Hyprland settings and keybinds here), `monitors.lua`, `workspaces.lua`,
  `hyprland/shellOverrides/main.lua` and `hypridle-timeouts.conf` (both written by Nexus), `hyprland/colors.lua`,
  `hyprlock/colors.conf`, `hyprlock/lockwall.conf` (written by the colour scheme and the lock screen settings).
- `~/.config/{fuzzel,kitty,foot,wlogout}/` (a folder that is missing or empty), `~/.config/xdg-terminals.list`,
  `~/.config/uwsm/env-hyprland.d/*`, `~/.local/share/wayland-sessions/hyprland.desktop`, copies in
  `~/.config/autostart` of the entries a `caelestia4-*` unit replaces (hidden in this session), the configs of the apps
  Caelestia themes (btop, cava, fastfetch, Thunar, nvim, Zen's `userChrome.css`).
- `~/.config/caelestia/shell.json` and `cli.json`, `~/.config/illogical-impulse/config.json`,
  `~/.local/share/icons/illogical-impulse.svg`.

**Kept, with a line or a key added once when it's missing** (nothing you set is changed, except the old defaults
named here):

- `~/.config/hypr/custom/env.lua` gets `QML_IMPORT_PATH`, and `custom/general.lua` your keyboard layout from
  `localectl` (only when it isn't plain US and the file sets no `kb_layout`). Lines an older version wrote to
  `env.lua` are taken out again. `custom/keybinds.lua` is never written after it was created.
- `hyprlock/colors.conf` gets the colour variables an older version lacks.
- `~/.config/xdg-desktop-portal/hyprland-portals.conf` gets the portals it doesn't name; the old KDE defaults are moved
  to Wormhole / none. Its `RemoteDesktop` line is changed at every run, see below.
- `~/.config/hyprland-mimeapps.list` (an old `inode/directory=thunar.desktop` is replaced), Zen's `user.js`.
- The browsers' `*-flags.conf` get gnome-keyring when they name no key store. Then each other app with a key of its
  own and no store yet (`tools/keyring-switch.py set gnome --all --unset-only`) gets it: a line in its flags file
  (`obsidian/user-flags.conf`…) or `argv.json` (VS Code family), or else a copy of its desktop entry in
  `~/.local/share/applications`; your own entries in `~/.local/share/applications` and `~/.config/autostart` that start
  the app get the flag too.
- `~/.config/btop/btop.conf` gets the GPU pane, only while it still shows btop's default boxes.
- `shell.json`: the monospace font, the file manager and the log out / hibernate commands, when unset (the file manager
  also when it's Atlas and Atlas isn't installed). `cli.json`: GTK / Qt theming and the Breeze icons, when no icon
  theme is set. `config.json`: the task manager, when it's still Plasma's System Monitor.

**Changed every time, although you may have set it:**

- micro's `colorscheme` in `~/.config/micro/settings.json` is set to `simple` (when micro is installed).
- spicetify's `current_theme` and `color_scheme` are set to `caelestia`, and the Caelestia extension is installed again
  in Cursor, VS Code and VSCodium (when they are installed).
- The colour files: `~/.config/gtk-3.0/thunar.css` (and its import line in `gtk.css`), and without caelestia-cli
  `~/.config/btop/themes/caelestia.theme`, `~/.config/zed/themes/caelestia.json` and
  `~/.config/spicetify/Themes/caelestia/color.ini`. Each colour change writes them too.
- `~/.config/systemd/user/*.wants/` links of the `caelestia4-*` units (`systemctl --user reenable`).
- `org.freedesktop.impl.portal.RemoteDesktop` in `~/.config/xdg-desktop-portal/hyprland-portals.conf`: `none` becomes
  `hypr-kdeconnect` while `/usr/share/xdg-desktop-portal/portals/hypr-kdeconnect.portal` exists, and `hypr-kdeconnect`
  becomes `none` when it's gone. Any other value is left alone.

**Never touched:** `~/.config/caelestia/monitors/*/shell.json` (per-screen settings), `~/.config/caelestia4/` other than
`repo` (your `push-denylist`; an old `shared-desktop` marker is removed), the Nexus profiles in
`~/.local/share/caelestia4/profiles` and your wallpapers.
Outside your home, `./install.sh` installs packages (and, after asking, `yay-bin` and the packages that replace
conflicting ones such as PulseAudio), enables and starts NetworkManager and Bluetooth, puts fonts in
`/usr/local/share/fonts/caelestia4` and, if you agree, sets up greetd; the sudo rule for updates (the repo upgrade and its keyrings,
nothing else) is only made by `tools/update-sudo-rule.sh`. The full list is under [System-wide (sudo)](#system-wide-sudo).

### Settings kept in both files

The shell reads two settings files: Caelestia's `~/.config/caelestia/shell.json` and end-4's
`~/.config/illogical-impulse/config.json`. A few settings exist in both. Nexus shows the Caelestia one, and the running
shell copies it into end-4's (`end4Wanted` in `modules/caelestia/ServiceLoader.qml`) when it starts, when the value
changes and when `config.json` is loaded again. The copy is one way: change these in Nexus or in `shell.json`, since an
edit of the end-4 key alone is put back.

| `shell.json` (Caelestia) | `config.json` (end-4) |
|---|---|
| `appearance.transparency.enabled` | `appearance.transparency.enable` |
| `appearance.font.mono.family` | `appearance.fonts.monospace` (an empty family isn't copied) |
| `services.weatherLocation` | `bar.weather.city` |
| `services.weatherUnits` | `bar.weather.useUSCS` (true for Fahrenheit) |
| `services.clockFormat` | `time.format` (`h:mm AP` or `hh:mm`) |

Only the global `shell.json` is copied, not a screen's file. `tools/nexus-coverage.py --check-mirrors` (run by
`tools/ci-lint.sh`) checks that every such pair is in `end4Wanted` and that `nexus/registry/ignored.json` names the
Caelestia key it follows, and that no Nexus row, registry `mirrors` entry or direct write (`Config.options.<path> =`,
`setNestedValue("<path>", …)`) sets the end-4 key alone. A write with a key built at run time (the AI chat's
`set_shell_config` tool) isn't checked; the next sync puts it back.

## Undo: everything it changes

What `./install.sh` changes outside the clone, which script does it, and how to take it back. Other desktops on this
account keep working: log into them as usual. What they see of this setup is under
[Shared with your other desktops](#shared-with-your-other-desktops).

### System-wide (sudo)

- **Packages** (`install.sh` steps 2, 5, 6): a full `pacman -Syu` with `base-devel` and `git`; end-4's
  `illogical-impulse-*` metapackages and this repo's `caelestia4-*` packages, installed explicitly; their dependencies
  from the repos and the AUR, installed as dependencies. Undo:
  `sudo pacman -Rs $(pacman -Qq | grep -E '^(illogical-impulse|caelestia4)-')`, which takes the dependencies nothing
  else needs with them (packages you had before keep their install reason, so they stay). `base-devel` and `git` were
  installed explicitly, so they stay too: remove them by hand if you didn't have them.
- **Packages it replaced**, after asking (step 4): another Quickshell or caelestia-cli build, PulseAudio and its
  modules, what the AUR packages conflict with (`darkly`, `yq`…). Undo: install them again; pacman doesn't keep them.
- **`yay-bin`**, only with no AUR helper and after asking (step 3). Undo: `sudo pacman -Rs yay-bin`.
- **A pacman hook**, `/usr/share/libalpm/hooks/quickshell-check.hook`: after a Qt update it asks Quickshell whether it
  still matches. It comes with `caelestia4-quickshell` (`packaging/caelestia4-quickshell/PKGBUILD`) and goes with it.
- **System services** (step 7): `NetworkManager` and `bluetooth` enabled and started when they weren't already;
  NetworkManager not when another network service is enabled. Undo, only for a service that was off before (the
  install log, `~/.local/state/caelestia4/install-*.log`, shows whether step 7 ran `systemctl enable`):
  `sudo systemctl disable --now NetworkManager` or `bluetooth`.
- **Fonts** (`tools/fonts-install.sh`, step 8): `/usr/local/share/fonts/caelestia4/`; it removes the per-user copy
  older versions put in `~/.local/share/fonts/caelestia4`. Undo:
  `sudo rm -r /usr/local/share/fonts/caelestia4 && sudo fc-cache -f`.
- **Login screen**, only when none is set up and you agree (step 10, `tools/greetd-setup.sh`): `greetd` and
  `greetd-regreet` installed, `greetd.service` enabled; `/etc/greetd/config.toml`, `hyprland.lua`, `regreet.toml`,
  `regreet.css` and `background.*` (a copy of your wallpaper); `/etc/pam.d/greetd` with `pam_gnome_keyring`.
  greetd's own PAM file is kept as `/etc/pam.d/greetd.caelestia4-orig`, a config.toml from another setup as
  `/etc/greetd/config.toml.caelestia4-orig`. Undo: `sudo systemctl disable greetd` and enable your other login manager,
  `sudo mv /etc/pam.d/greetd.caelestia4-orig /etc/pam.d/greetd`, delete those files in `/etc/greetd` (or move the
  `.caelestia4-orig` config back), then `sudo pacman -Rs greetd-regreet greetd`.

It adds you to no group and changes no sudoers file, udev rule, boot loader or `/etc/pacman.conf`: only the opt-ins
under [Only when you run them](#only-when-you-run-them) do.

### Your account (no sudo)

`tools/install-main.sh` copies what it replaces to `~/.local/state/caelestia4/backup-<time>/` first. Files it only
creates when missing, or sets a few keys in, aren't copied there.

- **Configs replaced** (backed up): `~/.config/quickshell/ii`, `~/.config/hypr` (not `custom/`, `monitors.lua`,
  `workspaces.lua` or the files the shell writes there), `~/.config/matugen`. The keyboard layout from `localectl` and
  `QML_IMPORT_PATH` are added to `~/.config/hypr/custom/` once. Undo: restore the backup, or delete them.
- **Configs created when missing, a few keys set in existing ones**: `~/.config/illogical-impulse/config.json`,
  `~/.config/caelestia/shell.json` (session menu commands, the file manager, a monospace font) and `cli.json` (GTK and
  Qt theming on); the fuzzel, kitty, foot and wlogout configs. Undo: delete a file only if the install created it
  (you had none before). In one you already had, take out only the keys it set: `session.commands.logout` and
  `hibernate`, `general.apps.explorer` and `appearance.font.mono.family` in `shell.json`; `theme.enableGtk`,
  `enableQt`, `iconThemeDark` and `iconThemeLight` in `cli.json`; and in `config.json` set `apps.taskManager` back to
  `plasma-systemmonitor --page-name Processes`. The fuzzel, kitty, foot and wlogout configs you already had were
  never changed: leave them.
- **App themes** (`modules/caelestia/utils/scripts/apptheme.py setup`). Created when missing: `btop.conf`, fastfetch,
  cava, Zen's `userChrome.css`, Thunar's `uca.xml` and `thunar-volman.xml`, an nvim colorscheme (and an `init.lua`
  when there's no nvim config), spicetify's `user.css`. Set or rewritten each run: the GPU pane in a `btop.conf` that
  still has the old default boxes, a Zen `user.js` pref, micro's colorscheme (`simple`), spicetify's `current_theme`
  and `color_scheme`; the Caelestia extension installed in VS Code / Cursor / VSCodium. Rewritten at every colour
  change too: `~/.config/btop/themes/caelestia.theme`, `~/.config/zed/themes/caelestia.json`,
  `~/.config/gtk-3.0/thunar.css`, Zen's `chrome/caelestia.css`, spicetify's `Themes/caelestia/color.ini` and
  `~/.local/state/caelestia/scheme.json`. Undo: delete the files, uninstall the extension, set the btop, micro and
  spicetify options back.
- **Qt colours**: caelestia-cli writes `~/.config/qtengine/caelestia.colors` and `config.json` at each colour change
  (`"enableQt"` in `cli.json`). Only a session with `QT_QPA_PLATFORMTHEME=qtengine` reads them. Undo: delete the
  folder.
- **Portals**: `~/.config/xdg-desktop-portal/hyprland-portals.conf`, created when missing (Open / Save dialogs from
  Wormhole, then GTK; the Secret portal on gnome-keyring). In an existing file, a `kde` FileChooser becomes
  `wormhole;gtk`, the KDE-only interfaces become `none` and missing keys are added. At every install and update,
  `RemoteDesktop = none` becomes `hypr-kdeconnect` while hypr-kdeconnect's `.portal` file is installed, and goes back
  to `none` when it isn't. Only a Hyprland session reads it. Undo: delete it, or edit those lines back (the next install
  or update sets `RemoteDesktop` again; any value other than `none` or `hypr-kdeconnect` stays).
- **File associations**: `~/.config/hyprland-mimeapps.list` gets folders opening in Atlas (then Thunar), merged with
  your entries. Only a Hyprland session reads it. Undo: delete that line.
- **The uwsm session** (`tools/uwsm-setup.sh`):
  - `~/.config/uwsm/env-hyprland` (replaced each run) and `~/.config/uwsm/env-hyprland.d/caelestia4-local.sh` (kept
    once there);
  - user units in `~/.config/systemd/user/`: `caelestia4-shell`, `caelestia4-sni-watcher`,
    `caelestia4-cliphist@text`, `caelestia4-cliphist@image`, `caelestia4-geoclue-agent`, and when the app is installed
    `caelestia4-fcitx5`, `caelestia4-easyeffects`, `caelestia4-kdeconnectd`, `caelestia4-kdeconnect-indicator`; enabled
    for `graphical-session.target` but started only in this session (`ConditionEnvironment=CAELESTIA4_UWSM=1`); and
    the drop-in `app-graphical.slice.d/caelestia4-oomd.conf`;
  - `~/.local/share/wayland-sessions/hyprland.desktop`, the entry `uwsm start hyprland.desktop` reads;
  - `~/.config/xdg-terminals.list`, when missing;
  - copies of the fcitx5, KDE Connect and GeoClue autostart entries in `~/.config/autostart/` with
    `NotShowIn=Hyprland`, when that unit is enabled and you had no copy.

  Undo: `systemctl --user disable caelestia4-shell caelestia4-sni-watcher caelestia4-cliphist@text caelestia4-cliphist@image caelestia4-geoclue-agent caelestia4-fcitx5 caelestia4-easyeffects caelestia4-kdeconnectd caelestia4-kdeconnect-indicator`,
  delete `env-hyprland`, the units and the drop-in, then `systemctl --user daemon-reload`. `caelestia4-local.sh`,
  `hyprland.desktop`, `xdg-terminals.list` and the autostart copies are only written when missing: delete them only if
  you had none before.
- **Built or fetched for you**: the Caelestia QML plugin in `~/.local/lib/qt6/qml/Caelestia`
  (`tools/build-caelestia-plugin.sh`); end-4's Python venv in `~/.local/state/quickshell/.venv` (uv may download
  Python 3.12 into `~/.local/share/uv`); the PGP keys the AUR sources are signed with, in your gpg keyring (step 5 names
  each one). Undo: delete the folders, `gpg --delete-keys KEYID`.
- **State and logs**: `~/.config/caelestia4/` (`repo`: the clone's path; `push-denylist` if you made one),
  `~/.local/state/caelestia4/` (install and update logs, backups), `~/.local/state/caelestia`, `~/.cache/caelestia`,
  `~/.local/share/icons/illogical-impulse.svg`; the clone itself in `~/.local/share/caelestia_4` (or `$C4_DIR`) after
  the one-line install. With `XDG_STATE_HOME` elsewhere, `~/.local/state/quickshell` and `~/.local/state/caelestia`
  become links to it. Undo: delete them (the icon only if you had none before: it isn't replaced).

### Shared with your other desktops

- **Which key store each browser and Electron app uses** (`tools/install-main.sh`, `tools/keyring-switch.py`, at every
  install and update):
  - `~/.config/chrome-flags.conf`, `code-flags.conf` and `thorium-flags.conf` are copied whole when missing. Besides
    `--password-store=gnome-libsecret` they carry flags that have nothing to do with the key store (Wayland, GTK 4,
    `--ignore-gpu-blocklist`, touchpad history and IME features) and no mark. Undo: delete the file if you had none
    before (a created one is the same as `dots/.config/<name>-flags.conf` in the clone).
  - `chromium-`, `brave-` and `brave-origin-flags.conf` get a `--password-store=gnome-libsecret` line, marked
    `caelestia4 (tools/keyring-switch.py)`, when they name no store; a missing one is created, even for a browser
    that isn't installed. On an account with a KWallet, files that are already there are left alone, and when neither
    `brave-` nor `chrome-flags.conf` exists no flags file is written or created.
  - Then, also on an account with a KWallet, for each other app with a key and no store set, unless its key is in
    KWallet (or KWallet is locked) and not in gnome-keyring: its `~/<data folder>/argv.json`, its
    launcher's flags file, or a copy of its desktop entry in `~/.local/share/applications`, or
    `~/.config/python_keyring/keyringrc.cfg`. Your own entries in `~/.local/share/applications` and
    `~/.config/autostart` that start such an app directly (web apps, autostart) get the flag in their Exec line,
    edited in place and not backed up. These are marked the same way.

  Undo: `tools/keyring-switch.sh set kwallet --all` moves the apps to KWallet with their keys. Deleting a marked line
  alone puts the app on its desktop's default store, which may not have its key.
- **GTK**: at every colour change the GTK theme (`adw-gtk3` or `adw-gtk3-dark`) and colour scheme are set in dconf,
  which GNOME, Plasma's GTK apps and others read: by caelestia-cli with `"enableGtk": true` in
  `~/.config/caelestia/cli.json`, otherwise by `scripts/colors/switchwall.sh` itself. With `enableGtk`, caelestia-cli
  also writes `gtk.css` in `~/.config/gtk-3.0` and `gtk-4.0`; `apptheme.py` adds Thunar's import to
  `gtk-3.0/gtk.css`. Undo, once you stop using this session: delete those `gtk.css` files,
  `gsettings reset org.gnome.desktop.interface gtk-theme` and `color-scheme`. Setting `enableGtk` to `false` only
  stops the `gtk.css` files.

### Only when you run them

- `sudo tools/update-sudo-rule.sh enable` (or the *Repo upgrades without a password* switch in Nexus > Updates, which
  runs it): `/etc/sudoers.d/zz-caelestia4-update`, the repo upgrade and the keyrings with no password (the commands
  are under [Updating](#updating)). Running it again replaces the file, an older pacman-wide one too. Undo:
  `sudo tools/update-sudo-rule.sh disable`, or the same switch; `tools/update-sudo-rule.sh status` then says `off`,
  unless another sudoers rule still allows it.
- Brave's frame colour ([step 3](#3-one-time-choices-after-the-first-login)): you create
  `/etc/brave/policies/managed`, then `apptheme.py` writes `caelestia.json` in it. Undo:
  `sudo rm /etc/brave/policies/managed/caelestia.json && sudo rmdir /etc/brave/policies/managed` (`rmdir` keeps a
  folder that holds other policies).
- `system/udev/99-caelestia4-dgpu.rules`, copied to `/etc/udev/rules.d/` by hand (its header says how). Undo: delete
  it, `sudo udevadm control --reload`.
- Hiding the plain "Hyprland" login entry, the two commands `tools/uwsm-setup.sh` prints: a `NoExtract` line in
  `/etc/pacman.conf`, and `/usr/share/wayland-sessions/hyprland.desktop` removed. Undo: delete that line, then
  `sudo pacman -S hyprland`.
- `tools/keyring-switch.sh prepare` / `finish`: KWallet's Secret Service off (`kwalletrc`), gnome-keyring's socket
  unmasked and enabled, the Secret portal on gnome-keyring, every KWallet entry copied to the login keyring, every app
  moved, `XDG_CURRENT_DESKTOP=Hyprland` in your `caelestia4-local.sh`. KWallet keeps everything. Undo:
  `kwriteconfig6 --file kwalletrc --group org.freedesktop.secrets --key apiEnabled true`,
  `tools/keyring-switch.sh set kwallet --all`, `systemctl --user disable --now gnome-keyring-daemon.socket` (and
  `systemctl --user mask gnome-keyring-daemon.socket gnome-keyring-daemon.service` if they were masked before),
  `org.freedesktop.impl.portal.Secret = kwallet` in `hyprland-portals.conf`, and `XDG_CURRENT_DESKTOP=Hyprland:KDE`
  back in `caelestia4-local.sh`. The login screen's PAM (`pam_gnome_keyring` in `/etc/pam.d/greetd`) still starts
  gnome-keyring at each login, so it serves `org.freedesktop.secrets` first and gh, Zed, the shell's API keys and
  Flatpak apps stay on it until that line is taken out (root). Only the apps `set kwallet` moved use KWallet without
  that.
- `./setup install-setups`, end-4's step, which `./install.sh` doesn't run: adds you to the `video`, `i2c` (created)
  and `input` groups, writes `/etc/modules-load.d/i2c-dev.conf`, enables the `ydotool` user unit and `bluetooth`, sets
  the GNOME font and colour scheme with gsettings and Darkly in `~/.config/kdeglobals`. Undo:
  `sudo gpasswd -d "$USER" input` (and `i2c`, `video`), `sudo rm /etc/modules-load.d/i2c-dev.conf`,
  `systemctl --user disable --now ydotool`, `sudo systemctl disable --now bluetooth` (if it was off before),
  `gsettings reset org.gnome.desktop.interface font-name`, `gsettings reset org.gnome.desktop.interface color-scheme`
  and `kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle --delete` (or set your old style).

No script installs the rest of `dots-extra/` (emacs, fcitx5, fontsets, swaylock, an ollama unit, a tmpfiles rule).

## Without Plasma

What Plasma provided, and what does it here:

| Plasma had | Here |
|---|---|
| Login screen (plasmalogin) | greetd + ReGreet in a Hyprland of its own: `tools/greetd-setup.sh` (re-run it to refresh its colours / wallpaper), or the login screen you already have |
| KWallet (Secret Service, unlocked at login) | gnome-keyring, unlocked by the login screen's PAM; `tools/keyring-switch.sh` moves an existing KWallet's keys, and puts each browser / Electron app on KWallet or gnome-keyring |
| Tray registry (kded6) | `caelestia4-sni-watcher` (docs/uwsm.md) |
| Qt theme / colours | qtengine (`packaging/caelestia4-qtengine`) + Darkly, colours from caelestia-cli (cli.json enableQt) |
| GTK theme / colours | adw-gtk3 + caelestia-cli's gtk.css (enableGtk) |
| KDE portal | Wormhole's Open / Save dialogs, GTK's as the fallback |

Chromium and Electron pick their key store from `XDG_CURRENT_DESKTOP`, and an unknown desktop (Hyprland) would give
them the unencrypted "basic" store, so each app with a key is told its store. `tools/keyring-switch.sh status` lists
them (found from the desktop entries, on any install) with where that's set: `~/<data folder>/argv.json` for the
VS Code family, the flags file the app's launcher reads, or else a copy of its desktop entry in
`~/.local/share/applications`. `tools/keyring-switch.sh set gnome|kwallet APP...` (or `--all`) moves apps either way,
their key with them, read back first; `install-main.sh` puts the apps with no store and no key yet on gnome-keyring.
gh, Zed and the shell's API keys follow whoever serves `org.freedesktop.secrets` (gnome-keyring here). Before removing packages, check what pacman can't see: QML imports
(org.kde.syntaxhighlighting is one), commands the scripts call, Qt image plugins.
