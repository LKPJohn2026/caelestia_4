# Feature comparison: Caelestia vs end-4 vs caelestia_4 (2026-10-13, reviewed 2026-10-27)

Upstreams checked (fresh clones, not the local copies):
- end-4/dots-hyprland `2f2a376` (2026-10-11): ii family + Waffle family, services, Hyprland config, keybinds
- caelestia-dots/shell `a3a8fe5` (2026-10-12): shell modules, services, plugin config
- caelestia-dots/caelestia `f4bb062` (2026-10-13): dotfiles (Hyprland, app themes, uwsm)
- caelestia-dots/cli `289e208` (2026-10-13): the `caelestia` command

end-4 is a vendored library since 2026-10-27 (reviewed up to 2f2a376, nothing newer; new commits are picked one by
one with tools/sync-end4.sh, not merged). Caelestia shell is vendored at
`4b1dae84` (2026-10-25, upstream main: 0 commits ahead, rechecked three times 2026-10-27); caelestia-cli is `5e804b1` (packaging/caelestia4-cli). Since 29fcf69a: sidebar
hover fixes + Nexus "Show on hover", `caelestia:toggleDnd`, CachingImage → Visual (file dialog icons stay on
Quickshell's IconImage), video previews play on hover, the plugin unloads idle media players. Equivalent: upstream's
Super+Shift+number silent move is Super+Alt+number here.

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
| Active window title + window-info popout | ✅ C | the title can be hidden (upstream PR #2097) |
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
| Dash tab: user/pfp, date-time, calendar, small weather, resources, media | ✅ C | Super+Alt+←/→ change tabs while open (upstream PR #2218) |
| Media tab: player controls, cover art, visualiser, lyrics | ✅ C | lyrics: local .lrc → LRCLIB (exact match, then search) → NetEase → Kugou → QQ Music (all synced), then untimed lyrics (LRCLIB plain, lyrics.ovh) as the last resort; Kugou / QQ Music added here |
| Performance tab: CPU, GPU, memory, storage, network | ✅ C | |
| Weather tab: 7-day forecast, sunrise/sunset, humidity, wind | ✅ C | |
| Todo tab, Timer tab (pomodoro + stopwatch) | ✅ E→C | end-4 features as dashboard tabs |

### Launcher
| Feature | Status | Notes |
|---|---|---|
| App search with frequency ranking | ✅ C | apps launched as their own uwsm units |
| Actions (`>`): wallpaper, random, settings, variant… | ✅ C | `>scheme` lists the preset schemes (utils/scripts/scheme.py instead of the CLI) |
| Calculator (`=`), emoji (`:`), clipboard (`;`) | ✅ C | clipboard from end-4's cliphist, with favourites (end-4 PR #3716) |
| Run commands (`$`) in a terminal | ✅ C | via uwsm -T |
| Web search (`?`) | ✅ C | |
| Wallpaper picker with live preview | ✅ C | folders (upstream PR #2135); image and colour preview: utils/scripts/wallpreview.sh (matugen dry run, end-4's colour style incl. auto) fills Colours.preview; picking keeps it until end-4's colours arrive. Not for video wallpapers |
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
| Wallpaper & style (wallpapers, colours) | ✅ C | a wallpaper per workspace (upstream PR #2210, stills only); wallpapers apply through end-4 (colours regenerate); end-4 Settings > Appearance still has more |
| Panels (bar: workspaces, clock, status icons, tray, active window; dashboard; launcher; sidebar; utilities) | ✅ C | writes ~/.config/caelestia/shell.json |
| Network: networks, saved networks, add network, add VPN, Ethernet details | ✅ C | Nmcli adapter extended with one-off nmcli calls (still one `nmcli monitor`, end-4's) |
| Bluetooth: pairing, device info | ✅ C | |
| Audio: devices, per-app volumes | ✅ C | |
| Apps: all apps, app info | ✅ C | |
| Notifications settings | ✅ C | Caelestia popups / toasts; end-4 settings keep its own options |
| Language & region | ✅ C | UI language here is the Caelestia part only; end-4 text follows Settings > Apps > Language |
| About | ✅ C | |
| Updates (upstream: placeholder) | ✅ added | Arch repo + AUR packages and new caelestia_4 commits (system.py); same data as the bar's updates icon and popout |
| Plugins (upstream: placeholder) | ✅ added | Quickshell, the Caelestia plugin and Hyprland plugins: versions, the Qt each was built with, rebuild needed |
| Hyprland (not in upstream) | ✅ added | end-4 Settings' Windows and Input pages (keyboard layouts, repeat, pointer, scrolling, focus, gaps, borders, opacity, blur, shadows, animations, layout) + cursor, rendering, middle-click paste (end-4's shell overrides, same keys as Settings); Super+S close-any switch (upstream dots b476a36) |
| Display (upstream: commented-out TODO) | ✅ added 2026-10-27 | per monitor resolution / refresh rate, scale, rotation with a 15 s keep-or-revert, saved to monitors.lua; VRR |
| Power & idle (not in upstream) | ✅ added 2026-10-27 | hypridle lock / screen off / sleep timers, lock before sleep, hyprlock, battery warning and hibernate levels (as end-4 Settings) |
| Wallpaper & style extras | ✅ added 2026-10-27 | panel / layer opacity, Caelestia's size scales (text, roundness, spacing, padding, animation), screen frame, fonts, desktop clock (Caelestia's or end-4's); Panels > On-screen display (osd.*). Upstream's Nexus has no rows for these keys |
| The rest of end-4 Settings | ✅ added 2026-10-27 | Panels > Assistant, Dock, Overview & overlay, Keybind cheatsheet; rows on the Taskbar, Dashboard, Launcher, Utilities, Notifications, Audio, Hyprland, Apps, Language & region, Services and Wallpaper & style pages. Every end-4 Settings row has a Nexus place (same keys); only "Use an image file" (switchwall.sh's picker) is left out |
| Plugin config coverage | ✅ | 136 of the plugin's 200 config keys have a Nexus row (upstream's Nexus: 101), none that upstream has is missing. Without rows: `lock.*` and `general.idle.*` (hyprlock / hypridle instead) and hand-edited lists (workspace icons, `launcher.actions`, tray `iconSubs`) |
| One Nexus window | ✅ 2026-10-27 | opening it again focuses the open window (upstream PR #2208 only blocks the second one) |

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
| `caelestia install` / `update` | 🔁 Equivalent | tools/install-main.sh; tools/sync-upstreams.sh (Caelestia), tools/sync-end4.sh (picks end-4 commits) |
| Hyprland config: animations, decoration, gestures, groups, input, rules | 🔁 Equivalent | end-4's Hyprland config + Settings > Windows / Input |
| Gestures: 4-finger workspace swipe, 4-finger up/down | ✅ | + 3-finger move / pinch fullscreen (end-4) |
| uwsm session files | ✅ | own setup (tools/uwsm-setup.sh), uwsm-only |
| App themes: foot, fish, starship, fastfetch, btop | ✅ | foot, fish, starship themed; btop + fastfetch now too (apptheme.py) |
| File manager: Thunar (manifest component) | ✅ 2026-10-27 | Atlas (AstraSuite, Caelestia's tokens, colours from scheme.json; `packaging/caelestia4-atlas`) opens folders, Super+E, Caelestia `apps.explorer`, dock pins; Thunar stays as the fallback |
| Open / Save dialogs (Caelestia: whatever portal the desktop has) | ✅ 2026-10-27 | Wormhole's FileChooser (`packaging/caelestia4-wormhole`) in the Hyprland session, KDE's as the fallback. Only that interface: Wormhole's Inhibit / GlobalShortcuts are stubs and its Camera grants access without asking; Background / Clipboard / Usb / Wallpaper are pinned to kde so its UseIn key doesn't pick them |
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
| Workspace overview | ✅ E→C | + Windows-style Alt+Tab; Super+Tab is a window switcher (end-4 PR #3693) |
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

New upstream Caelestia work since this comparison (checked 2026-10-22: shell `29fcf69a`, dotfiles `4f7407c`,
cli `c5f478d`; the vendored shell was `21a75375`, 19 commits behind; **vendored `29fcf69a` since 2026-10-22, backend step 2**):

- **Wallpaper transitions**: shader transitions between wallpapers (new Multimedia + Shaders plugin modules, shaders from
  skwd-paper). ✅ 2026-10-22: the background uses Caelestia's WallpaperImpl (27 transitions, picked in Nexus → Wallpaper
  & style; stills cached as compressed KTX, 16.6 MB instead of ~66 MB at 7680×2160).
- **Video wallpapers inside the shell** (Visual component), shown in Nexus too. 🔁 Hybrid by choice: videos are listed
  and previewed (first frame / launcher) by Caelestia's Visual, but play on mpvpaper. Measured on 7680×2160 H.264:
  mpvpaper 2.4 % of a core, QtMultimedia 18 % (CUDA) / 24 % (VAAPI) and +0.5 GB in the shell, since Qt copies every
  decoded frame through system memory.
- **Pause-wallpaper quick toggle** (utilities). ✅ Added 2026-10-22 for mpvpaper video wallpapers (mpv IPC; remembered across logins).
- **Picture-in-picture match anchored** (`^Picture…Picture$`). ✅ Applied 2026-10-22 (resizer and end-4's PiP rules).
- **Caps Lock state from the key code** (works with `caps:escape_shifted_capslock`-style options). ✅ Applied 2026-10-22.
- Smaller: session GIF hidden when its path is empty; settings can skip watching the config file; the Discord theme uses
  the Caelestia logo (no Discord theming here at all: it needs a client mod such as Vencord / Vesktop).

Backend (2026-10-22): notifications, network, brightness and battery now run on Caelestia's own services (step 1 of
moving the backend to Caelestia; colours / wallpapers / recorder / idle inhibitor still go through end-4). Step 2:
the vendored plugin is at 29fcf69a and the wallpaper is drawn by Caelestia's renderer (applying still goes through
end-4's switchwall.sh, videos through mpvpaper). Step 3: caelestia-cli makes the colours (wallpaper or preset), end-4 gets them
through its postHook (`scheme.py bridge`); btop / nvtop / Zed / Spotify are themed by caelestia-cli itself. end-4-only
features (assistant, overlay, region tools, dock, todo / timer, settings app…) keep their end-4 services.

Still open (review 2026-10-22):

1. ✅ 2026-10-22: **ClipRect everywhere** (upstream #2168; `StyledClippingRect` removed), session GIF only when set
   (#2166), and the clean upstream lint diffs since 21a75375 taken.
2. ✅ (merged into 1)
3. ✅ 2026-10-27, **caelestia-cli pinned at 5e804b1** (`packaging/caelestia4-cli`, 1.1.3 + 41): 858ecff (black
   wallpapers), 679af94 (Hyprland socket replies decoded after joining chunks: multi-byte titles split across chunks
   failed), the Discord theme's logo. Video wallpapers (#183) stay unused here (thumbnails are passed).
4. ✅ 2026-10-22, **settings unified**: transparency is one switch (Nexus and Settings write both halves; on); the
   end-4 desktop weather widget reads Caelestia's weather (Settings > Apps > Weather); Nexus > Apps > Terminal sets
   ~/.config/xdg-terminals.list like Settings; Nexus > Services > Smart colour scheme works (on: a new wallpaper picks
   light/dark and the variant; the light/dark switch and colour style still override). Workspaces shown stays
   Caelestia's 5 (end-4's 10 is only read by an unused model and unlisted settings pages); `nexus.networkRescanInterval`
   was live all along (the Nexus network pages' rescan timers).
5. **App themes**: ✅ 2026-10-26 Discord (Vesktop) via caelestia-cli's Midnight theme (cli.json enableDiscord; enable it once
   in Vesktop > Settings > Themes) and Brave / Brave Origin's frame colour. Firefox still not themed.
6. **Lock screen** cards are read-only (hyprlock): no media buttons, notifications not clickable. Kept on purpose.
7. **Upstream `refactor/adopt-lib`** (shell, 37 commits, not merged as of 2026-10-27): `Caelestia.Scheme` (C++ Colours
   and Wallpapers, smart scheme in the shell, random wallpaper), a blur controller (`appearance.transparency.blurEnabled`
   + Nexus switch), launcher wallpaper search, and `Caelestia.Images` removed for `VisualAnalyser`. When it merges the
   Colours adapter's ImageAnalyser has to move to VisualAnalyser, and the colours could come from the shell instead of
   the cli. Waiting for the merge: the branch's API still changes daily.

Review 2026-10-27: end-4 main `2f2a376` (nothing new since 2026-10-11, merged), Caelestia shell `4b1dae84` (vendored,
0 ahead), dotfiles `b476a36` (only specialWsCloseAny was new: ported), cli `5e804b1` (packaged). Every end-4 ii module
has a Caelestia-style place here except ScreenCorners, covered by Caelestia's frame (rounded border; the sidebars open
on hover; scrolling the bar sets volume / brightness).

Second review 2026-10-27 (same upstream heads; open PRs checked). Upstream fixes still in review, taken here:
- dots #531: `resize_by_screen` (resizer.lua) used physical pixels, so at scale 1.5 the float_* tags and
  Ctrl+Super+Alt+Backslash made windows 1.5x too big (55% x 70% came out as 82% x 105%)
- shell #2178: finished nmcli commands (Nmcli adapter's CommandProcess) are destroyed instead of living until restart
- shell #2208: one Nexus window (see §1 Nexus)
- shell #2211: when LRCLIB `/get` has only plain lyrics (or fails), its `/search` is tried for a synced entry within
  2 s of the track's length before NetEase; the plain lyrics are still kept as the last resort
- shell #2129: the active window popout opens at its final size (the preview is sized from the window before its
  first frame)
- shell #2218: Super+Alt+←/→ change the dashboard tab while it is open (`caelestia:dashNext` / `dashPrev`), over
  the tabs shown here including Todo / Timer (upstream stops at tab 4)
- shell #2097: `bar.activeWindow.showTitle` (Nexus > Panels > Taskbar > Active window > Show title); off leaves the
  app icon only

- shell #2210: a wallpaper per workspace (Nexus > Wallpaper & style > Workspace wallpapers, off by default; state in
  ~/.local/state/caelestia/state.json, IPC `wallpaper clearWorkspace NAME` / `clearWorkspaces`). Picks from the
  launcher, Nexus, end-4's selector or random go to the focused workspace; the overview's tiles show each
  workspace's own. Videos stay global (one mpvpaper): picking one clears the workspace's still so it shows the video
- shell #2135: folders in the launcher's wallpaper list (folders first, `..` back, hidden ones such as `.git` left
  out); it opens in the folder of what the screen shows. Unlike the PR, a search still looks through every folder

- dots #484: media seek keys, Super+Shift+, / . (5 s) and Ctrl+Super+Shift+, / . (10 s), locked and repeating. The
  PR only binds `caelestia:mediaSeek*` (its key variables are undefined and the shell has no such shortcuts), so the
  four shortcuts are added here too (Players adapter, MPRIS `seek()`)

Lock, lid, UPS, iGPU and multi-GPU PRs don't apply here.

Third review 2026-10-27: no new commits in end-4, the Caelestia shell, dotfiles or cli. end-4's open PRs:
- Taken: #3713 (OpenAI-compatible requests no longer send `"tools": []` in the search / no-tools modes, which
  strict providers reject), #3721 (no size rule for the KDE portal: it forced the picker's Rename / New Folder
  dialogs to 60% x 65%; KDE's picker is the fallback here, Wormhole's comes first)
- #3712 the way it applies here: XDG_DATA_DIRS doesn't grow on reloads (set once per session in
  uwsm/env-hyprland), but each system dir was in it twice; env-hyprland now drops duplicates (from the next login)
- #3693 as a Super+Tab window switcher in Caelestia style (windowSwitcher/WindowSwitcher.qml): hold Super, Tab /
  Shift+Tab step through every workspace's windows (live previews, the workspace's name on others), release Super
  to switch; it opens on the previous window. Alt+Tab stays the workspace switcher; Super+Tab no longer opens the
  overview (4-finger swipe and `qs ipc call search toggle` still do)
- #3716: clipboard favourites (end-4's Cliphist, `~/.cache/cliphist/fav.db`): the launcher's `;` rows show their
  actions as buttons on the selected or hovered row (pin / unpin, copy, delete); favourites stay at the end and
  `;#fav` lists only them. No error before the first pin (the PR logs one on every refresh)
- Don't apply: #3720 (startup speed: only the Caelestia family loads here, the config is read in under 1 s),
  #3714 (802.1X Wi-Fi: no Wi-Fi on this machine), #3718 (Super+P projector flyout: one monitor, Nexus > Display)

Fourth review 2026-10-27: still no new commits anywhere, no PR updated since. Open PRs looked at again:
- Taken: shell #2100 (the file dialog's sidebar pins and folder icons follow the XDG user dirs: this machine's are
  Vietnamese, ~/Ảnh, ~/Bản tải về..., and every English-named pin opened a missing folder), shell #2131 (saved
  notifications restored in one assignment), dots #482 (btop's GPU pane: shipped btop.conf, and `apptheme.py setup`
  adds gpu0 to a btop.conf whose boxes are still the old default)
- Optional: shell #2095 (no title cross-fade flicker on rapid title changes), #2214 (app icons in the bar's
  workspaces), #2090 (splash text on the desktop)
- Not here: #2149 (popout redesign, 975 lines, still in review), #2099 (drawer collision manager, 620 lines),
  #2110 (weather off switch), dots #507 (browsers opaque: windows are opaque here), #509 / #506 / #503 (keybind
  layout and descriptions: the keybinds here are end-4's)

Done since the last review: wallpaper transitions, colours from caelestia-cli with presets paired for light/dark
(`counterpart()`), pause-wallpaper toggle, PiP / Caps Lock fixes, backend steps 1-3.

Waiting on a one-time step: Zen and Cursor/Zed need their theme picked once, Vesktop its Caelestia theme (see install notes).
