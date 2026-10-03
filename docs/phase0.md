# Phase 0: Baseline (log)

Started 2026-10-03.

## 1. Hardware facts

| Item | Value |
|---|---|
| Monitor | 57" Samsung (SAM7475), **7680×2160 @ 240 Hz**, used at **1.5×** |
| Connector | `DP-2` on **card1** |
| card1 | `0000:01:00.0`, **NVIDIA RTX 5090** (`nvidia`), render node `renderD128` |
| card0 | `0000:0d:00.0`, AMD Granite Ridge iGPU (`amdgpu`), render node `renderD129` |
| Hyprland in repo | 0.56.2 (cachyos-extra-znver4 / extra) |

**What this means for Hyprland:** the screen hangs off the NVIDIA card, so Hyprland must use it as the primary GPU: `AQ_DRM_DEVICES=/dev/dri/card1`.

- `/dev/dri/cardN` numbering can change between boots. The stable path `/dev/dri/by-path/pci-0000:01:00.0-card` contains colons, and `AQ_DRM_DEVICES` uses colons as its separator, so it can't be used directly.
- **Phase 1 TODO:** add a udev rule for a colon-free symlink (e.g. `/dev/dri/nvidia-dgpu`).
- For Phase 0, `card1` is fine. If Hyprland starts on a black screen, the numbering flipped: use `card0`.

## 2. end-4 installer audit (upstream `main` @ `547836f1b0`)

Read before running: `setup`, `sdata/lib/*.sh`, `sdata/subcmd-install/*.sh`, `sdata/dist-arch/install-deps.sh`, metapackage PKGBUILDs.

### Changes that affect the whole system (not undone by deleting the test user)

| What | Where | Assessment |
|---|---|---|
| `sudo pacman -Syu` | unless `--skip-sysupdate` | Do the upgrade separately first, then pass `--skip-sysupdate` |
| `pacman -Rdd` of old `-git` packages (`quickshell-git`, `hyprland-git`, `matugen-bin`, …) | — | **None installed** on this machine (checked), so nothing is removed |
| Local metapackages `illogical-impulse-*` built with `makepkg`, deps via `yay` (yay is already installed) | pacman db | Pulls **AUR** packages: `adw-gtk-theme-git`, `breeze-plus`, `darkly-bin`, `ttf-material-symbols-variable-git`, `otf-space-grotesk`, `ttf-readex-pro`, … Read the PKGBUILDs when yay shows them |
| `illogical-impulse-quickshell-git` (pinned `7511545e`) | pacman db | Conflicts with `quickshell` / `quickshell-git`. Nothing installed today |
| `illogical-impulse-kde` → `gnome-keyring`, `bluedevil`, `plasma-nm`, `polkit-kde-agent`, `dolphin`, `systemsettings` | pacman db | **Watch item:** `gnome-keyring` is new here (Plasma uses `kwallet`). Both can claim `org.freedesktop.secrets`. Check that Plasma still unlocks KWallet after the install |
| `/etc/modules-load.d/uinput.conf`, `/etc/modules-load.d/i2c-dev.conf` | /etc | Harmless kernel modules (ydotool, ddcutil) |
| `/etc/udev/rules.d/99-uinput.rules` (uinput → group `input`, 0660) | /etc | Users in `input` can inject keystrokes. Only the user who runs the installer is added |
| `groupadd i2c`; `usermod -aG video,i2c,input <user>` | /etc/group | Applies to the user running the installer (`e4test`) |
| `ln -s /usr/lib/systemd/{system,user}/ydotool.service` | /usr/lib | Makes ydotool available as a user service |
| `systemctl enable bluetooth --now` | systemd | Probably already enabled |
| Fonts/icons to `/usr/local/share/{fonts,icons}`, MicroTeX to `/opt/MicroTeX` | /usr/local, /opt | Harmless, but not tracked by pacman |

### Changes limited to the user running it
`~/.config/*` files (hypr, quickshell/ii, fish, kitty, foot, fuzzel, matugen, `kdeglobals`, …), `kwriteconfig6 … widgetStyle Darkly`, Python venv in `~/.local/state/quickshell/.venv`, `chown -R ~/.local`. In the test user these are all thrown away with the account.

## 3. Steps

- [ ] **0.1** System upgrade (separately): `sudo pacman -Syu`
- [ ] **0.2** Snapshot: `sudo snapper create -d "caelestia_4 phase 0: before end-4 test"`
- [ ] **0.3** Test user: `sudo useradd -m -G wheel -s /bin/bash e4test` + `sudo passwd e4test`
- [ ] **0.4** Log in as `e4test` (Plasma session is fine), then in Konsole:
      `git clone https://github.com/end-4/dots-hyprland ~/dots-hyprland && cd ~/dots-hyprland && ./setup install --skip-sysupdate`
      (full upstream defaults otherwise: this is the baseline)
- [ ] **0.5** Add GPU env to `~/.config/hypr/custom/env.lua` (e4test): `AQ_DRM_DEVICES=/dev/dri/card1`
- [ ] **0.6** Log out → "Hyprland" session as `e4test`. Set the monitor: `hyprctl keyword monitor DP-2,7680x2160@240,0x0,1.5`
- [ ] **0.7** Checks:
  - bar, sidebars, overview, launcher, notifications, lock;
  - Dolphin, System Settings, polkit prompt (`pkexec true`), Wi-Fi/Bluetooth applets, screen share through the KDE portal;
  - Super+Alt+W → `waffle` and back;
  - 240 Hz + VRR.
- [ ] **0.8** Back in the main account: Plasma still Oxygen? `git -C ~/oxygen-plasma diff --stat` after copying the current config. KWallet still unlocks?
- [ ] **0.9** Caelestia reference (second throwaway user `caetest`, since it needs `quickshell-git`, which conflicts with end-4's build): snapshot, install, capture every drawer at 7680×2160 into `docs/reference/`, then roll back the snapshot or remove the packages.
- [ ] **0.10** Remove the test users (`sudo userdel -r e4test caetest`) once the references are saved.

## 4. Results

### 0.1–0.7: done (2026-10-03)
- `pacman -Syu`: 4 packages, no kernel/driver; snapper pre/post #79/#80.
- Manual snapshot created; `e4test` created (`wheel`), installer run with `--skip-sysupdate`.
- 14 `illogical-impulse-*` packages installed, plus `illogical-impulse-quickshell-git 0.1.0.r1-8`, `hyprland 0.56.2`, `gnome-keyring 1:50.0`, `darkly-bin`, `breeze-plus`.
- `e4test` groups: `wheel input video i2c`. `/etc/modules-load.d/i2c-dev.conf` added.
- **end-4 works in the `e4test` Hyprland session.**

### 0.8: main account check
- **Plasma Oxygen intact:** `widgetStyle=oxygen`, `ColorScheme=OxygenDark`, Plasma theme `oxygen`, decoration `org.kde.oxygen`. The only diffs against `oxygen-plasma` are expected: GTK sound theme `ocean→oxygen` (from Plan E) and desktop icon `screenMapping`.
- **Hyprland in the main account shows only stock Hyprland.** That is expected: end-4's config exists only in `e4test`'s home. Hyprland wrote its default `~/.config/hypr/hyprland.lua` (04:04) because no config existed. Harmless; replaced in later phases.
- ⚠️ **Problem: gnome-keyring took over the secrets service in the main Plasma session.**
  - Cause: the `gnome-keyring` package (pulled in by `illogical-impulse-kde`)
    1. enables `gnome-keyring-daemon.socket` for **all users** (`/etc/systemd/user/sockets.target.wants/`, 03:56), and
    2. ships `/usr/share/dbus-1/services/org.freedesktop.secrets.service` → `gnome-keyring-daemon`.
  - At the 04:10 Plasma login, gnome-keyring claimed `org.freedesktop.secrets` before KDE's `ksecretd`.
  - Effect: apps that use the Secret Service lost access to secrets stored in KWallet. **Confirmed: `gh auth status` → "token in default is invalid".**
  - Fix for the main account only, at user level (run by the user):
    - `systemctl --user mask gnome-keyring-daemon.socket gnome-keyring-daemon.service`
    - a user D-Bus override `~/.local/share/dbus-1/services/org.freedesktop.secrets.service` with `Exec=/usr/bin/ksecretd`
    - log out and back in.
    `e4test` keeps gnome-keyring, as upstream intends.
  - **Resolved 2026-10-03** after a full reboot: `ksecretd` owns `org.freedesktop.secrets`, and `gh auth status` is OK again. A PAM-started `gnome-keyring-daemon --daemonize --login` still runs at login but doesn't hold the secrets name, which is harmless.
  - **Plan impact:** caelestia_4 in the main account uses **KWallet (`ksecretd`) as the only secrets backend in both sessions.** end-4's `KeyringStorage` goes through libsecret, so this should work; verify in Phase 2. Don't let gnome-keyring run in the main account.

### 0.9: Caelestia reference (in progress)
- Conflicts met while installing Caelestia over end-4:
  - `adw-gtk-theme` (Caelestia) vs `adw-gtk-theme-git` (required by `illogical-impulse-fonts-themes`). Removed with `pacman -Rdd` for the test.
  - `pipewire-jack` replaced `jack2`.
- ⚠️ **`illogical-impulse-quickshell-git` declares `provides=quickshell-git`,** so yay treats Caelestia's `quickshell-git` dependency as already satisfied, and Caelestia ends up on end-4's pinned Quickshell (`7511545e`, reports "0.2.1").
- **Result: Caelestia v2.5.0 does not start on end-4's pin.** Headless load: `ERROR: Unrecognized pragma "DefaultEnv QS_NO_RELOAD_POPUP=1"` (shell.qml line 2). Hyprland runs with keybinds but no shell UI.
- **Phase 1 input:** end-4's pin is too old for Caelestia v2.5.0 as-is. Either move to a newer `quickshell-git` and re-test `ii`, or patch the Caelestia QML that needs newer APIs (`DefaultEnv` → `Env` is the first one; there may be more).
- Workaround for the test: `yay -S aur/quickshell-git` (replaces end-4's package).
