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
2. **greetd + regreet**: `/etc/greetd/config.toml` (regreet in cage, session `uwsm start hyprland-uwsm.desktop`),
   `/etc/pam.d/greetd` with both pam_kwallet5 and pam_gnome_keyring for the switch-over (the login keyring is created
   with the login password at the first login), `systemctl disable plasmalogin && systemctl enable greetd`.
3. **Keys to gnome-keyring**: a script reads every KWallet folder and entry over its D-Bus API (one KWallet access
   prompt; values stay in memory), a user D-Bus service override points org.freedesktop.secrets at
   gnome-keyring-daemon, ksecretd is stopped, the items are written to the login keyring with their attributes. Brave's
   libsecret item gets the value of `Brave Keys/Brave Safe Storage` (the key its data is encrypted with); the script
   compares it with the older libsecret copy without printing either. Then Brave `--password-store=gnome-libsecret`,
   `XDG_CURRENT_DESKTOP=Hyprland`, and a check of Brave's passwords and sessions, Claude, `gh auth status`, Zed, the
   Assistant's API keys and Python keyring. Undo: remove the override, put the Brave flag back.
4. **Remove packages** (`pacman -Rns -p` first): the plasma group (plasma-workspace, kwin, plasma-login-manager,
   xdg-desktop-portal-kde, kwallet-pam, polkit-kde-agent, spectacle...), Dolphin, Konsole, Kate, Gwenview, Filelight,
   KCalc, Partition Manager, KWallet Manager, kio-admin, kdialog, signon-kwallet-extension, kde-gtk-config,
   kinfocenter; the pam_kwallet5 lines in greetd's PAM. Kept: Ark, Haruna, KDE Connect, breeze-icons; kwallet stays
   as kio's dependency, without org.freedesktop.secrets (the override).
5. **Clean up**: the shared-desktop marker file, the plasma-* units in execs.lua / uwsm-setup.sh, then (weeks later)
   `~/.local/share/kwalletd/` and Plasma's files in ~/.config.
