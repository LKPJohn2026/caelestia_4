# Removing Plasma (2026-10-27)

Plasma is no longer used; the session is Hyprland (uwsm) with the Caelestia shell. "Removing KDE" means removing
the Plasma desktop, not every KDE framework: kwallet (library), kio, kded and breeze-icons stay as libraries for the
apps that remain (Ark, Haruna, KDE Connect). Decisions: greetd + regreet as the login screen; Ark, Haruna and KDE
Connect kept; every KWallet key moved to gnome-keyring (it unlocks with the login password through PAM, is D-Bus
activated before apps start and has the Secret portal; KeePassXC was compared and not picked).

What Plasma provided here, and its replacement:

| Piece | Was | Now |
|---|---|---|
| Tray registry (org.kde.StatusNotifierWatcher) | kded6's statusnotifierwatcher module (plasma-workspace) | `caelestia4-sni-watcher` (scripts/caelestia4/sni-watcher.py), before the shell |
| Qt theme and colours | `QT_QPA_PLATFORMTHEME=kde` (plasma-integration), kde-material-you-colors -> plasma-apply-colorscheme | qtengine (`packaging/caelestia4-qtengine`), Darkly, colours from caelestia-cli (cli.json enableQt) |
| GTK theme and colours | Breeze-GTK, Plasma's static colors.css | adw-gtk3 + caelestia-cli's gtk.css (enableGtk) |
| App menu (KDE apps' "Open with") | plasma-applications.menu (`XDG_MENU_PREFIX=plasma-`) | archlinux-xdg-menu (`arch-`) |
| Portals | KDE: FileChooser fallback, Background, Clipboard, Usb, Wallpaper | FileChooser `wormhole;gtk`, the others `none` (no Flatpak apps here) |
| Login screen | plasmalogin (+ pam_kwallet5) | greetd + regreet (+ pam_gnome_keyring) |
| Secret Service | KWallet (ksecretd), Brave `--password-store=kwallet6` | gnome-keyring, Brave `--password-store=gnome-libsecret` |
| "Show in folder" (FileManager1) | dolphin --daemon | Thunar |
| Task manager, text editor fallbacks | plasma-systemmonitor, Kate | btop (kitty), Zed / micro |

## Phases

0. Safety net: a snapper snapshot (snap-pac also takes one per pacman run; limine-snapper-sync boots them); the
   plain session still starts from a TTY (`start-hyprland`); `~/.local/share/kwalletd/` stays until the end.
1. **Replace, with Plasma still installed** (done 2026-10-27, needs a re-login for the env part):
   - tray watcher: tested on a private bus (items by bus name and by object path, removal when the owner leaves,
     host registered / gone), then live: kded6 stopped, the watcher started before the shell, 5 of 7 tray icons
     re-registered by themselves (KDE Connect, Fcitx, EasyEffects, Steam, CoolerControl); the two Electron apps
     (Claude, one other) register once and come back when they restart. The list survived a shell restart. Order
     matters: with no watcher, Quickshell takes the name itself and a later watcher fails (it exits 1 then).
     Its unit first lacked `After=graphical-session.target`: systemd then ordered the target after it (WantedBy), and
     with session-graphical.slice that made a stop cycle, so "uwsm stop" (logout) failed until it was added.
   - cli.json enableGtk / enableQt with the Breeze icons (install-main migrates an older cli.json once).
   - switchwall.sh / scheme.py: the shared-desktop marker (account shared with Plasma) became "caelestia-cli themes
     GTK" (cli.json enableGtk); kde-material-you-colors and its matugen wrapper removed; VS Code's material-code
     colours only without caelestia-cli (Caelestia's extension does it otherwise). ConflictKiller no longer counts
     kded6 as a tray.
   - portals repointed (install-main changes only the old defaults; RemoteDesktop / Secret untouched).
   - env-hyprland: `QT_QPA_PLATFORMTHEME=qtengine`, `XDG_MENU_PREFIX=arch-` (installed by tools/uwsm-setup.sh once
     caelestia4-qtengine and archlinux-xdg-menu are installed).
   - end-4's illogical-impulse-kde (now gnome-keyring + networkmanager) and -portal (no KDE portal): rebuilt and
     installed in phase 4 only, gnome-keyring must not arrive before phase 3.
   - apps.taskManager btop (install-main migrates the old default), fallbacks without Kate / plasma-systemmonitor /
     Dolphin.
2. **greetd + regreet** (`tools/greetd-setup.sh`, templates in `dots-extra/greetd/`): ReGreet runs in a Hyprland of
   its own as "greeter" (`/etc/greetd/hyprland.lua`, the session's monitors and 1.5 scale, which cage can't set;
   `AQ_DRM_DEVICES` for the NVIDIA card the monitor is on), `regreet; hyprctl dispatch 'hl.dsp.exit()'` so greetd
   starts the session when it is done. ReGreet: adw-gtk3, Breeze icons, Bibata, Google Sans Flex (installed for every
   user), Caelestia's GTK 4 colours, a copy of the wallpaper. `/etc/pam.d/greetd` adds pam_kwallet5 as Plasma's login
   manager had, and pam_gnome_keyring lines that stay inert until gnome-keyring is installed: installing it now would
   let it take org.freedesktop.secrets from KWallet at the next login, and apps reading keys through the Secret Service
   (Claude, Zed, gh) would find an empty keyring. The script checks the greeter config (`Hyprland --verify-config`)
   and leaves the switch to you: `systemctl disable plasmalogin && systemctl enable greetd`.
3. **Keys to gnome-keyring** (`tools/keyring-switch.sh`, `tools/kwallet-to-keyring.py`), in two logins so KWallet
   stays the source until everything is checked:
   - `prepare`: KWallet's Secret Service API off (kwalletrc `[org.freedesktop.secrets] apiEnabled=false`; its own
     API, which Brave / Claude / Vesktop use, stays), gnome-keyring unmasked (it was masked while the account was
     shared with Plasma), the Secret portal on gnome-keyring. At the next login pam_gnome_keyring creates the login
     keyring with the login password and gnome-keyring serves org.freedesktop.secrets; no race with ksecretd.
   - `finish`: every KWallet item into the login keyring through the Secret Service API (a "plain" session; read
     back and compared byte for byte), values never printed. KWallet is read through ksecretd under its own name
     (org.kde.secretservicecompat): it lists all 14 items, native ones included; kwalletd6's own API lists each
     folder six times and misses the Secret Service ones (gh, Zed, keyring, the Assistant). Tested: with
     apiEnabled=false ksecretd drops org.freedesktop.secrets and keeps that name. A ksecretd started outside the
     login is locked; the script then shows KWallet's own unlock prompt (the password never passes through it). Secret Service items keep label, attributes and content
     type; native "<App> Keys/<App> Safe Storage" keys are also written as libsecret looks them up
     (chrome_libsecret_os_crypt_password_v2, application = the existing libsecret copy's name, else both the
     Electron form "Claude" and the browser form "brave"); the native one wins over an older libsecret copy and
     whether they match is printed; KWallet-only entries become org.kde.kwallet.entry items.
   - Chromium / Electron pick the store from XDG_CURRENT_DESKTOP: KDE -> KWallet, GNOME-like -> libsecret, an
     unknown desktop such as Hyprland -> the unencrypted "basic" store with a new key, which would lose their data.
     So the apps with a key get `--password-store=gnome-libsecret` explicitly: Brave (brave-origin-flags.conf),
     Vesktop (vesktop-flags.conf), Claude (its launcher copy in ~/.local/share/applications; session restore
     launches through .desktop entries, so it gets the flag too). Then `XDG_CURRENT_DESKTOP=Hyprland`.
   - What went wrong the first time (2026-10-28): the backup of each older libsecret key kept `application=...`.
     Chromium's libsecret schema is DONT_MATCH_NAME (it looks keys up by application alone), so Brave picked the
     backup: the cookies it couldn't decrypt were dropped (sites logged out), new ones were written with that key,
     its passwords (native key) didn't open. Found by decrypting copies of the profile's databases with each
     candidate key (counts only). Fix: the backups carry `replaced-application` instead; the 57 values Brave wrote
     with the old key (55 cookies, 2 search-engine url hashes) re-encrypted under the native key with Brave closed,
     each database backed up as `*.caelestia4-bak` first. Claude's cookies were on the right key; its sign-in was
     in the Secret portal's per-app secret, which gnome-keyring's portal doesn't read from KWallet's portal item.
   - Check after the next login: Brave's passwords and sessions, Claude, `gh auth status`, Zed, the Assistant's API
     keys, Python keyring. Undo: apiEnabled=true, the old flags, Hyprland:KDE, log out and in.
4. **Remove packages** (done 2026-10-28): first the profiles backed up to `~/caelestia4-backups/<date>/` (Brave's
   and Claude's, caches and Claude's VM bundles left out, SQLite files through sqlite3's online backup; KWallet's and
   gnome-keyring's files), end-4's illogical-impulse-kde 1.0-5 (gnome-keyring, networkmanager) and -portal 1.0-4
   (no KDE portal) installed, qt6-imageformats and kimageformats marked explicit (WebP / AVIF wallpapers; -s would
   have taken them), greetd's PAM without pam_kwallet5, KWallet's PAM unit no longer started (execs.lua). Then
   `pacman -Rsn` on the plasma group and the KDE apps except Ark, KDE Connect and Haruna (61 targets, 135 packages,
   ~657 MiB). Kept as libraries of what stays: breeze, breeze-cursors, kdecoration, libplasma, plasma-activities
   (Darkly and breeze need them), kwallet (kio needs it; it no longer holds org.freedesktop.secrets). Each blocker
   came from `pacman -Rsp` dry runs; the target list is one package per line, since fish splits `$(cat …)` by line
   only (a space-separated line failed as one name, harmlessly).
   - Missed: the removal took `syntax-highlighting`, whose QML module (org.kde.syntaxhighlighting, the Assistant's
     code blocks) the shell imports; nothing declares that dependency, so pacman couldn't know, and the earlier
     compile check ran while it was installed. After the reboot the shell didn't load at all (one missing import
     breaks the whole component tree). Reinstalled as explicit. The check that catches it: every `import` in the
     shell's QML against the qmldir files left on disk, after the removal (only that module was missing), and the
     removed packages' /usr/bin commands (from pacman.log + the package cache) against the repo: only
     switchwall.sh's kdialog file picker (its no-image path, not used by Nexus) is left.
5. **Clean up**: the shared-desktop marker file, the plasma-* units in execs.lua / uwsm-setup.sh, then (weeks later)
   `~/.local/share/kwalletd/` and Plasma's files in ~/.config.
