# Feature comparison: Caelestia vs end-4 vs caelestia_4 (2026-10-13, reviewed 2026-10-14)

Upstreams checked (fresh clones, not the local copies):
- end-4/dots-hyprland `2f2a376` (2026-10-11): ii family + Waffle family, services, Hyprland config, keybinds
- caelestia-dots/shell `a3a8fe5` (2026-10-12): shell modules, services, plugin config
- caelestia-dots/caelestia `f4bb062` (2026-10-13): dotfiles (Hyprland, app themes, uwsm)
- caelestia-dots/cli `289e208` (2026-10-13): the `caelestia` command

caelestia_4 is in sync with end-4 (0 upstream commits not merged). Caelestia shell is vendored at `21a75375` (2026-10-11).

Status legend:
- ✅ **C**: Caelestia feature, working here as in Caelestia
- ✅ **E→C**: end-4 feature, working here in Caelestia style
- ✅ **E**: end-4 feature, working here in end-4 style (settings app)
- 🔁 **Equivalent**: the other project's version covers it
- ⚠️ **Partial**: works, but something from upstream is missing
- ❌ **Missing**: not available here
- 🚫 **Dropped**: removed on purpose

---

## 1. Caelestia shell (caelestia-dots/shell)

### Bar
| Feature | Status | Notes |
|---|---|---|
| Vertical bar with OS icon, clock, power button | ✅ C | |
| Workspaces with window glyphs, active-workspace pill, occupied background | ✅ C | Super held shows workspace numbers (end-4 behaviour added) |
| Special workspace indicator | ✅ C | |
| Active window title + window-info popout | ✅ C | |
| Status icons: audio, mic, keyboard layout, network, Bluetooth, battery, Caps/Num lock | ✅ C | Volume icon enabled by default here |
| Privacy (mic / screen in use) and updates icons | ✅ E→C | end-4 features added to Caelestia's status icons |
| Popouts: audio (devices + per-app mixer), network (+ Wi-Fi password), Bluetooth, battery, keyboard layout, lock status, tray menus | ✅ C | per-app mixer is end-4's, in the audio popout |
| System tray (compact mode, recolour, icon substitutions) | ✅ C | kded6 owns the tray watcher so icons survive shell restarts |
| Scroll actions on the bar (workspaces, volume, brightness) | ✅ C | |
| Hide / show bar (Super+J), persistent or edge-reveal | ✅ C | |
| "Open settings" from popouts → Nexus control centre | ✅ C | real Nexus, ported 2026-10-12 (see §1 Nexus) |

### Drawers / frame
| Feature | Status | Notes |
|---|---|---|
| Screen frame (border) with drawers that grow out of it | ✅ C | |
| Edge hover: top = dashboard, right = sidebar, left = launcher/assistant | ✅ C | |
| Background blur, transparency, rounding tokens | ✅ C | |

### Dashboard (top)
| Feature | Status | Notes |
|---|---|---|
| Dash tab: user/pfp, date-time, calendar, small weather, resources, media | ✅ C | |
| Media tab: player controls, cover art, visualiser, lyrics | ✅ C | lyrics: local .lrc → LRCLIB → NetEase → Kugou → QQ Music (all synced), then untimed lyrics (LRCLIB plain, lyrics.ovh) as the last resort; Kugou / QQ Music added here |
| Performance tab: CPU, GPU, memory, storage, network | ✅ C | |
| Weather tab: 7-day forecast, sunrise/sunset, humidity, wind | ✅ C | |
| Todo tab, Timer tab (pomodoro + stopwatch) | ✅ E→C | end-4 features as dashboard tabs |

### Launcher
| Feature | Status | Notes |
|---|---|---|
| App search with frequency ranking | ✅ C | apps launched as their own uwsm units |
| Actions (`>`): wallpaper, random, settings, variant… | ✅ C | `>scheme` lists the preset schemes (utils/scripts/scheme.py instead of the CLI) |
| Calculator (`=`), emoji (`:`), clipboard (`;`) | ✅ C | clipboard from end-4's cliphist |
| Run commands (`$`) in a terminal | ✅ C | via uwsm -T |
| Web search (`?`) | ✅ C | |
| Wallpaper picker with live preview | ⚠️ Partial | image preview works; the colour preview while browsing doesn't (needs caelestia-cli; colours change once a wallpaper is applied) |
| Colour scheme picker (preset schemes: catppuccin, gruvbox, nord, rosepine, tokyonight… 14 schemes) | ✅ C | Nexus > Wallpaper & style > Colours and launcher `>scheme`; 29 presets from the CLI repo, applied through end-4's matugen templates + terminal colours; "Follow the wallpaper" keeps end-4's colour styles |
| Variant picker (tonal spot, fruit salad…) | ✅ E→C | mapped to end-4's palette type |

### Utilities drawer (bottom right)
| Feature | Status | Notes |
|---|---|---|
| Quick toggles (Wi-Fi, Bluetooth, mic, game mode, DND, VPN, settings) | ✅ C | + 12 end-4 toggles, edit mode (order / hide) |
| Speaker mute toggle | ✅ E→C | end-4 parity, added 2026-10-12 |
| Right-click Wi-Fi / Bluetooth / sound / mic → detailed page | ✅ C | opens the Nexus network / Bluetooth / audio page |
| Keep awake (idle inhibit) card | ✅ C | one control; end-4's idle toggle merged into it |
| Screen recorder card + recordings list (play, open folder, delete) | ✅ C | |
| Eye protection: night light, schedule, warmth, gamma, anti-flashbang | ✅ E→C | |
| Sliders: brightness, volume, mic | ✅ E→C | |
| System card: uptime, reload, settings, session | ✅ E→C | reload now restarts the unit |

### Sidebar (right) and notifications
| Feature | Status | Notes |
|---|---|---|
| Notification popups, actions, inline images | ✅ C | |
| Notification history grouped by app, clear all, DND | ✅ C | |
| Inline notification replies | ❌ Missing | neither project has it |

### OSD, session, window info, misc
| Feature | Status | Notes |
|---|---|---|
| OSD for volume, brightness, mic | ✅ C | + gamma slider (end-4) |
| Session menu: logout, shutdown, reboot, hibernate | ✅ C | + lock, sleep, firmware reboot, task manager, warnings (end-4) |
| Window info (Super+Alt+… / active window popout): preview, details, actions | ✅ C | |
| Battery monitor (low / critical warnings, auto-hibernate) | ✅ C | |
| Desktop clock + background visualiser | ✅ C | + weather beside the clock (end-4) |
| Shell-side idle timers (IdleMonitors: lock / screen off / suspend) | 🔁 Equivalent | hypridle with Settings > Power & idle |
| Game mode (disables Hyprland animations, blur, gaps, shadows) | ✅ C | |
| VPN service (WireGuard / NetworkManager VPNs) | ✅ C | |

### Caelestia lock screen (modules/lock, 18 files)
| Feature | Status | Notes |
|---|---|---|
| PAM lock with clock, profile picture, password field | 🔁 Equivalent | hyprlock with the Caelestia theme (survives monitor drop on wake) |
| Lock screen extras: notifications, media, weather, resources, fetch | 🔁 Equivalent | hyprlock (Caelestia layout) has weather, system, media, resources and, since 2026-10-14, notifications (app + summary, newest 4); read-only, no media buttons. Kept hyprlock over the in-shell lock: it survives the G95NC dropping off DP on wake |

### Area picker (modules/areapicker)
| Feature | Status | Notes |
|---|---|---|
| Region / window screenshot picker, freeze | 🔁 Equivalent | end-4 region selector in Caelestia style: screenshot, Lens, OCR, record, circle, freeze |

### Nexus control centre (modules/nexus, 65 files, ported 2026-10-12)
| Page | Status | Notes |
|---|---|---|
| Wallpaper & style (wallpapers, colours) | ✅ C | wallpapers apply through end-4 (colours regenerate); end-4 Settings > Appearance still has more |
| Panels (bar: workspaces, clock, status icons, tray, active window; dashboard; launcher; sidebar; utilities) | ✅ C | writes ~/.config/caelestia/shell.json |
| Network: networks, saved networks, add network, add VPN, Ethernet details | ✅ C | Nmcli adapter extended with one-off nmcli calls (still one `nmcli monitor`, end-4's) |
| Bluetooth: pairing, device info | ✅ C | |
| Audio: devices, per-app volumes | ✅ C | |
| Apps: all apps, app info | ✅ C | |
| Notifications settings | ✅ C | Caelestia popups / toasts; end-4 settings keep its own options |
| Language & region | ✅ C | UI language here is the Caelestia part only; end-4 text follows Settings > Apps > Language |
| About | ✅ C | |

---

## 2. Caelestia dotfiles and CLI (caelestia-dots/caelestia, caelestia-dots/cli)

| Feature | Status | Notes |
|---|---|---|
| `caelestia shell` (start / restart / IPC / log) | 🔁 Equivalent | systemd unit `caelestia4-shell` (uwsm), `qs ipc` |
| `caelestia toggle <special workspace>`: communication (Discord…), music (Spotify…), sysmon (btop), todo (Todoist) | ✅ | hyprland/specialws.lua (upstream's Lua toggle): Ctrl+Shift+Esc sysmon (btop), Ctrl+Super+M music, Super+Alt+D communication, Super+R todo; apps start on first use, strays are gathered; apps from ~/.config/caelestia/cli.json `toggles` |
| `caelestia scheme`: 14 preset schemes × flavours × light/dark × variants | ✅ | `scheme.py set NAME FLAVOUR` / `set dynamic`; a preset survives wallpaper changes; single-mode presets keep their mode |
| `caelestia screenshot` (region, freeze) | 🔁 Equivalent | region selector |
| `caelestia record` (region, sound, pause, path to clipboard) | ✅ | record.sh uses gpu-screen-recorder like Caelestia (NVENC, HEVC at 7680x2160): pause/resume (SIGUSR2); region, sound, full screen; stopping copies the file to the clipboard (text/uri-list) |
| `caelestia clipboard` (pick / delete entries) | ✅ C | launcher `;` |
| `caelestia emoji` (+ fetch glyph data) | ✅ C | launcher `:` |
| `caelestia wallpaper` (set / random / size filter / preview) | 🔁 Equivalent | switchwall.sh, random wallpaper fetch with size + shape filters |
| `caelestia resizer`: auto-resize / float / centre / PiP rules per window | ✅ | hyprland/resizer.lua (upstream's Lua listeners): picture-in-picture floated, pinned, ¼ screen height, bottom-right (also when the title comes late); Bitwarden popups; float_50_60/60_70/70_80 tags; Super+Alt+Backslash PiP, Ctrl+Super+Alt+Backslash reset size |
| `caelestia install` / `update` | 🔁 Equivalent | tools/install-main.sh, tools/sync-end4.sh |
| Hyprland config: animations, decoration, gestures, groups, input, rules | 🔁 Equivalent | end-4's Hyprland config + Settings > Windows / Input |
| Gestures: 4-finger workspace swipe, 4-finger up/down | ✅ | + 3-finger move / pinch fullscreen (end-4) |
| uwsm session files | ✅ | own setup (tools/uwsm-setup.sh), uwsm-only |
| App themes: foot, fish, starship, fastfetch, btop | ✅ | foot, fish, starship themed; btop + fastfetch now too (apptheme.py) |
| App themes: Firefox, Zen, spicetify (Spotify), VS Code, Zed, Thunar, micro, nvim | ✅ partly | apptheme.py after every colour change: btop, cava, Zed, Zen, Brave, Cursor/VS Code/VSCodium (scheme.json), Thunar (gtk-3.0/thunar.css), Spotify (spicetify color.ini, live via `spicetify watch -s`), nvim (colorscheme watches scheme.json), micro ("simple" = terminal palette). Not here: Firefox (no profile yet) |

---

## 3. end-4 ii family (end-4/dots-hyprland)

| Feature | Status | Notes |
|---|---|---|
| Bar (horizontal / vertical) | 🔁 Equivalent | Caelestia bar |
| Bar extras: resources, media, weather, utility buttons, clock & battery popups, unread count | 🔁 Equivalent | dashboard tabs, utilities drawer, status icons |
| Screen corners + hot corners | 🔁 Equivalent | Caelestia frame + edge hover |
| Background widgets: cookie / digital clock, quote, parallax wallpaper | ✅ E→C | end-4's widgets (modules/caelestia/background/e4widgets) on the Caelestia background: Settings > Desktop > Desktop clock (Caelestia / Cookie / Digital / Off), placement free / least busy / most busy, quote, weather card; workspace parallax with zoom and widget factor |
| Dock (pinned apps, open windows, previews) | ✅ E→C | Caelestia-style dock with end-4's features |
| Lock screen (QML) | 🔁 Equivalent | hyprlock (end-4 option `useHyprlock`) |
| Media controls popup | 🔁 Equivalent | dashboard media tab |
| Notification popups | 🔁 Equivalent | Caelestia notifications |
| On-screen display | 🔁 Equivalent | Caelestia OSD |
| On-screen keyboard | ✅ E→C | |
| Overlay widgets (Super+G): crosshair, FPS limiter, floating image, notes, recorder, resources, volume mixer | ✅ E→C | |
| Workspace overview | ✅ E→C | + Windows-style Alt+Tab |
| Polkit dialog | ✅ E→C | |
| Region selector: screenshot, Google Lens, OCR, record, circle-to-search, annotate | ✅ E→C | |
| Screen translator | ✅ E→C | |
| Session screen | 🔁 Equivalent | Caelestia session + end-4 extras |
| Left sidebar: AI chat (Gemini Interactions API, OpenAI-compatible, Mistral, Ollama/LM Studio), tools, attachments, LaTeX, think blocks | ✅ E→C | Assistant drawer, detachable |
| Left sidebar: translator, Anime (8 image boards) | ✅ E→C | |
| Right sidebar: quick toggles, sliders, notifications, calendar, todo, timer, Wi-Fi/Bluetooth/volume/night-light dialogs | ✅ E→C | utilities drawer + dashboard + sidebar; dialogs open the Nexus pages |
| Wallpaper selector (Ctrl+Super+T) | ✅ E→C | + videos listed |
| Cheatsheet (keybinds + periodic table) | ✅ E→C | |
| Settings app | ✅ E | rebuilt pages, Vietnamese |
| Welcome / first-run app | ✅ E | Super+Shift+Alt+/ |
| Clipboard history (cliphist) | ✅ | launcher `;` and Super+V |
| Emoji picker | ✅ | launcher `:` and Super+. |
| Music recognition (SongRec) | ✅ E→C | toggle |
| Colour picker, screenshot, record keybinds | ✅ | |
| AI summary of selected text | ✅ | Super+Shift+Alt+mouse |
| Screen zoom in / out | ✅ | keybinds |
| Light/dark switch, material colours from wallpaper (matugen), terminal / KDE / GTK colouring | ✅ | |
| Video wallpapers (mpvpaper) | ✅ | |
| Random wallpaper from Wallhaven / Konachan / yande.re | ✅ | + size and screen-shape filters |
| Auto styling with Gemini (pick a palette from the wallpaper) | ✅ E | settings |
| Translations: generate with Gemini | ✅ E | + full Vietnamese (end-4 and Caelestia parts) |
| Conflict killer (other trays / notification daemons) | ✅ | |
| Keyring storage of API keys | ✅ | KWallet |
| Battery warnings, updates check, privacy indicator | ✅ | |
| Hyprsunset night light + gamma, anti-flashbang shader | ✅ | |
| EasyEffects integration | ✅ | |
| Tray: pin items | ✅ E→C | end-4's tray.pinnedItems / invertPinnedItems (TrayService): pinned icons stay on the bar, the rest behind the expand arrow; middle-click an icon or use "Ghim lên thanh" at the top of its menu |
| Background-mute games | ✅ | caelestia4 addition |
| Panel family switch (Ctrl+Super+P) | 🚫 Dropped | ii family removed 2026-10-12 |

## 4. end-4 Waffle family (Windows 11 style)

| Feature | Status | Notes |
|---|---|---|
| Waffle bar, start menu, search, task view, action centre, notification centre, screen snip, Fluent widgets | 🚫 Dropped | removed 2026-10-11 by decision |

---

## Gaps, most useful first

Still partial (review 2026-10-14):

1. **Wallpaper colour preview**: browsing wallpapers previews the image, not the colours it would give.
2. **App themes not covered**: Firefox (installed, no profile yet).
3. **Preset schemes with one mode** keep it when switching light/dark (no flavour pairing yet: `counterpart()` in scheme.py).
4. **Lock screen** cards are read-only (hyprlock): no media buttons, notifications not clickable. Kept on purpose.

Waiting on a one-time step: Brave's frame colour needs `sudo install -d -o "$USER" /etc/brave/policies/managed`; Zen and Cursor/Zed need their theme picked once (see install notes).
