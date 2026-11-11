# caelestia_4

**[Caelestia](https://github.com/caelestia-dots/shell)'s design running on [end-4's illogical-impulse](https://github.com/end-4/dots-hyprland)** — one Quickshell config for Hyprland that combines the look of one with the services and depth of the other.

> [!IMPORTANT]
> This is an **unofficial, personal fork**. It is not affiliated with or endorsed by end-4 or the Caelestia project.
> Please **do not report problems of this fork upstream**: open an issue here instead. All the good ideas below are
> theirs; the bugs in how they were put together are mine.

## What it is

- **The Caelestia shell** (by soramane and contributors): the frame, vertical bar with popouts, drawers, dashboard,
  launcher, utilities, notifications, OSD, session menu, the **Nexus** control centre, Caelestia's preset colour
  schemes, special workspaces and window resizer, ported from upstream with their own components.
- **On top of end-4's illogical-impulse** (by end-4, clsty and contributors): its services (AI chat, translator,
  booru browser, todo / timer, clipboard, emoji, music recognition, screen tools, region selector with OCR / Lens /
  recording…), its matugen colour pipeline and terminal theming, its Hyprland (Lua) config, restyled
  where they show in the Caelestia UI.
- **Glue**: adapters so Caelestia's UI reads end-4's services (one network monitor, one notification server, one
  colour pipeline), Caelestia's app themes fed from end-4's colours, a uwsm-managed session where the shell and every
  app are systemd units.

A feature-by-feature comparison with both upstreams is in [docs/feature-comparison.md](docs/feature-comparison.md).

### Highlights

| | |
|---|---|
| **Colours** | wallpaper colours (end-4's matugen, all styles incl. auto) with live preview while browsing, or one of Caelestia's 14 preset schemes; applied to the shell, Hyprland, hyprlock, terminals, btop, cava, Zed, Zen, Brave, VS Code / Cursor, Thunar, Spotify (spicetify), nvim, micro |
| **Control centre** | Caelestia's Nexus: networks (saved, hidden, IPv4, VPN), Bluetooth pairing, audio, apps, panels, colours |
| **Workspaces** | Caelestia's special workspaces (music, communication, system monitor, todo) that start their apps on first use; overview, Alt+Tab, wallpaper parallax |
| **Desktop** | Caelestia's desktop clock or end-4's cookie / digital clock, quote and weather widgets; video wallpapers (mpvpaper) |
| **Recording** | gpu-screen-recorder (hardware encoding), pause / resume, region or full screen, path copied to the clipboard |
| **Lock screen** | hyprlock in Caelestia's layout: clock, weather, system, media, resources, notifications |
| **Localisation** | full Vietnamese translation of both shells (end-4's JSON catalogue + Caelestia's gettext catalogue) |

## Status and requirements

Supported on **Arch-based systems with systemd**, **Hyprland 0.55+** (the Lua config) and **uwsm**. It doesn't need KDE
Plasma (greetd + ReGreet, gnome-keyring, its own tray watcher and Qt / GTK theming). The `sdata/dist-*` folders for other
distros come from end-4 and don't cover what this fork adds, so they aren't a supported way to install it.

It was developed on one machine (NVIDIA with an AMD iGPU, one ultrawide monitor at 1.5× scale). Other GPUs, several
monitors, laptops and small screens are meant to work but are less tested: please report what doesn't.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LKPJohn2026/caelestia_4/main/install.sh)
```

or, from a clone (`git clone --recursive`), `./install.sh`. It installs the dependencies (repo and AUR, with yay or
paru; it offers to build yay-bin), builds this repo's packages (Quickshell, the Qt theme, Wormhole, Atlas, caelestia-cli,
the Caelestia plugin), installs the configs (no sudo, backs up what it replaces) and, if there's no login screen yet,
offers greetd + ReGreet. Then reboot and pick **Hyprland (uwsm-managed)**. `./install.sh --dry-run` shows every command
first, `--list-deps` the packages. Details, the steps by hand, updating and undoing:
**[docs/install.md](docs/install.md)**.

## Documentation

- [docs/install.md](docs/install.md) — install, update, undo
- [docs/uwsm.md](docs/uwsm.md) — how the uwsm session is set up
- [docs/feature-comparison.md](docs/feature-comparison.md) — what came from where, what's still partial
- [docs/dev/](docs/dev/) — development notes: the original plan, phase logs, end-4 parity notes, install log

## Help, bugs and contributing

- **Questions**: [Discussions](https://github.com/LKPJohn2026/caelestia_4/discussions).
- **Bugs**: [open an issue](https://github.com/LKPJohn2026/caelestia_4/issues/new/choose) with the output of
  `./diagnose`. If it also happens on end-4's dots or in Caelestia, report it to them instead.
- **What this fork covers**, and what it won't take: [SCOPE.md](SCOPE.md).
- **Pull requests**: [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md).
- **Security problems**: privately, see [.github/SECURITY.md](.github/SECURITY.md).

## Credits

This project exists only because of the people below. If you enjoy it, **support them**, not this fork.

### end-4 — illogical-impulse ([end-4/dots-hyprland](https://github.com/end-4/dots-hyprland))

The base of this repository: the Hyprland setup, the Quickshell services, the settings app, the install scripts, the
colour pipeline and much more. The full history of dots-hyprland, with every contributor, is kept in this repo's git log.

- [**@end-4**](https://github.com/end-4) — creator and maintainer · **[Sponsor on GitHub](https://github.com/sponsors/end-4)**
- [@clsty](https://github.com/clsty) — install scripts, packaging and the [illogical-impulse wiki](https://ii.clsty.link)
- [@midn8hustlr](https://github.com/midn8hustlr) — the colour generation system
- [Makrennel](https://github.com/Makrennel) — the local-PKGBUILD dependency system
- and [all contributors](https://github.com/end-4/dots-hyprland/graphs/contributors)
- Community: [illogical-impulse Discord](https://discord.gg/GtdRBXgMwq)

### soramane — Caelestia ([caelestia-dots](https://github.com/caelestia-dots))

The design and the shell: the frame, the bar, drawers, dashboard, launcher, Nexus, the QML plugin, preset schemes,
special workspaces, the window resizer and app themes. Vendored in [`third_party/caelestia-shell`](third_party/caelestia-shell)
and ported under `dots/.config/quickshell/ii/modules/caelestia`.

- [**@soramanew**](https://github.com/soramanew) (soramane) — creator and maintainer ·
  **[Sponsor on GitHub](https://github.com/sponsors/soramanew)** · **[Ko-fi](https://ko-fi.com/soramane)**
- and all contributors to [shell](https://github.com/caelestia-dots/shell/graphs/contributors),
  [dotfiles](https://github.com/caelestia-dots/caelestia/graphs/contributors) and
  [CLI](https://github.com/caelestia-dots/cli/graphs/contributors)
- Community: [Caelestia Discord](https://caelestiashell.com/discord)

### The foundations

- [Quickshell](https://quickshell.org) by [@outfoxxed](https://github.com/outfoxxed) — the toolkit both shells are built on
- [Hyprland](https://hyprland.org) by [@vaxerski](https://github.com/vaxerski) and the
  [hyprwm](https://github.com/hyprwm) contributors — and the Hyprland Discord community, thanked by both upstreams
- [matugen](https://github.com/InioX/matugen), [uwsm](https://github.com/Vladimir-csp/uwsm),
  [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/),
  [spicetify](https://spicetify.app), [m3shapes](https://github.com/soramanew/m3shapes),
  [rxi/json.lua](https://github.com/rxi/json.lua)

The **Sponsor** button of this repository ([.github/FUNDING.yml](.github/FUNDING.yml)) points to end-4 and soramane.

## License

**GPL-3.0**, the same as both upstreams ([LICENSE](LICENSE)). Code from other projects keeps its own notice; the extra
licence texts are in [licenses/](licenses/). Third-party code: [`third_party/caelestia-shell`](third_party/caelestia-shell)
(GPL-3.0), Caelestia's preset schemes and app templates from [caelestia-dots/cli](https://github.com/caelestia-dots/cli)
and [caelestia-dots/caelestia](https://github.com/caelestia-dots/caelestia) (GPL-3.0), rxi's json.lua (MIT).
