# Scope

caelestia_4 is one person's fork, maintained in spare time. This page says what it covers, so that issues and pull
requests go where they can be fixed, and so that nobody spends a weekend on a pull request that can't be merged.

## In scope

- **The shell**: Caelestia's UI on end-4's services (`dots/.config/quickshell/ii`), the adapters between them, the
  Nexus control centre, the colour pipeline, the lock screen, and the Vietnamese and English translations.
- **The Hyprland config** in `dots/.config/hypr` (the Lua config, Hyprland 0.55 or newer).
- **The session**: uwsm, the systemd user units, the tools in `tools/` that install them (`install-main.sh`,
  `uwsm-setup.sh`, `greetd-setup.sh`, `fonts-install.sh`) and the update script
  (`scripts/caelestia4/system-update.sh`, run from Nexus).
- **The packages** built from `packaging/` and the dependency metapackages in `sdata/dist-arch`.
- **Arch-based systems with systemd**: Arch, CachyOS, EndeavourOS and similar.
- **NVIDIA, AMD and Intel GPUs, one or several monitors, laptops.** These get less testing than the maintainer's own
  setup, so reports about them are especially welcome.

## Out of scope

- **Other distributions.** The `sdata/dist-*` folders other than `dist-arch` come from end-4 and don't install what
  this fork adds. Pull requests that make the fork work elsewhere can be discussed first in Discussions.
- **Other compositors, and Hyprland's old `.conf` syntax.**
- **Sessions without uwsm.**
- **Login.** The supported login screen is greetd with ReGreet (`tools/greetd-setup.sh`), or any display manager you
  already use. Autologin, logging in through the lock screen, disk encryption and Secure Boot are your system's
  business: this repository will not set them up for you.
- **Bugs that also happen upstream.** If it also happens on [end-4's dots](https://github.com/end-4/dots-hyprland) or
  in [Caelestia](https://github.com/caelestia-dots/shell), please report it there: a fix upstream reaches everyone,
  this fork included. If you aren't sure, report it here and say so.
- **Bugs in Hyprland, Quickshell, Qt or a driver.** Those go to their own projects. A *workaround* in this fork is in
  scope.
- **Personal taste in defaults.** Keybinds, gaps, fonts and animations that you prefer belong in your own overrides
  (`~/.config/hypr/custom/`, the shell's settings), not in a pull request that changes them for everyone.
- **Support for old installs.** Bugs are only looked at on the latest `main`. Please update before reporting.

## Before a big change

Open a [Discussion](https://github.com/LKPJohn2026/caelestia_4/discussions) or a feature request first, and wait for an
answer before writing a new module, a new dependency or a change to how install works. The questions it will be asked:

1. Does it need to be in the shell itself, or could it be a script or a setting?
2. Does it fit Caelestia's design and end-4's services, or does it bring a third style?
3. Will someone be around to fix it when Hyprland or Quickshell changes?
4. Does it touch anything outside `$HOME` (sudo, `/etc`, PAM, a system service)? If so, it has to be opt-in, shown
   before it runs, and reversible.

Requests declined because of this page are labelled `wontfix` with a link here. That is about this fork's size, not
about the idea.
