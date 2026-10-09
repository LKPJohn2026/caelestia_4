# end-4 parity: dashboard (right sidebar) + dock in the Caelestia family (2026-10-05)

Review of end-4's right sidebar, left sidebar and dock against the Caelestia family, and what was added.

## Gap review (before)

| end-4 feature | Caelestia family before | Now |
|---|---|---|
| Dock | missing (end-4's dock only loads in the ii family) | **new Caelestia-style dock** |
| Quick toggles: 16 | 9 (wifi, bluetooth, mic, settings, game mode, night light, EasyEffects, DND, VPN) | **+ dark mode, power profile, keep awake, anti-flashbang, music recognition, on-screen keyboard, screen snip, colour picker, Cloudflare WARP (only if `warp-cli` exists)** |
| Edit quick toggles | fixed list | **edit mode**: click = show/hide, scroll = move; saved as `caelestia.quickToggles` |
| Quick sliders (brightness / volume / mic) | volume in popout/OSD only | **sliders card** in the utilities drawer; mic row hidden without an input device |
| Per-app volume mixer | popout had devices + master volume | **per-app streams** (icon = mute, slider, scroll) + **mic slider** in the audio popout |
| Night light dialog (Eye protection) | toggle only | **Eye protection panel**: right-click night light / anti-flashbang → now, automatic schedule (from/to), warmth, gamma, anti-flashbang shader + brightness adaptation |
| Uptime, reload, end-4 settings, session | session only | **System card**: uptime, Reload Hyprland & Quickshell, end-4 settings, session |
| Notifications, calendar, todo, timer, Wi-Fi/Bluetooth dialogs, audio devices | ✅ | ✅ (unchanged) |
| Left sidebar (AI chat, translator, anime) | ✅ Assistant drawer | ✅ |

## Files

- `modules/caelestia/dock/Dock.qml`, `DockPreview.qml`: the dock. Data from end-4's `TaskbarApps` (pinned apps = `dock.pinnedApps`, shared with the ii family). Features:
  - **Pin button:** keeps the dock shown and reserves space with an exclusive zone.
  - **Reveal:** on bottom-edge hover or on an empty workspace; hidden for fullscreen, launcher, session and lock.
  - **App:** click = launch or cycle its windows; middle-click = new instance; right-click = pin/unpin; dots = open windows (max 3).
  - **Hover preview:** live window thumbnails (ScreencopyView); click = focus, middle-click or ✕ = close.
  - **Apps button:** click = Caelestia launcher, right-click = workspace overview.
  - IPC: `qs -c ii ipc call dock togglePin`.
- `modules/caelestia/utilities/cards/Toggles.qml`: Caelestia toggles + end-4 toggle models (`modules/common/models/quickToggles/*`), tooltips, right-click (`altAction`), edit mode. Rows are balanced, with invisible spacers so buttons keep equal width.
- `utilities/cards/EyeProtection.qml`, `Sliders.qml`, `System.qml`; `utilities/Content.qml` (+ System, Sliders cards).
- `bar/popouts/AudioPopout.qml`: mic slider + per-app mixer (playback streams, `PwObjectTracker`).
- `modules/common/Config.qml` → `caelestia`:
  - `quickToggles`: list of `{id, enabled}`;
  - `utilitiesSystem` and `utilitiesSliders`;
  - `dock`: `enable`, `pinnedOnStartup`, `hoverToReveal`, `revealOnEmptyWorkspace`, `iconSize`.
- `panelFamilies/CaelestiaFamily.qml`: loads the dock when `caelestia.dock.enable`.

## Notes

- Caelestia `Tokens.rounding` has no `normal` (end-4 name); use `medium`. A `PopupWindow` needs `contentItem.Config/Tokens.screen` set by hand (`StyledWindow` does it for panels), and no `Tokens` in window-level bindings.
- After many hot reloads the running shell lost **theme** icons (file-path icons still worked, in the launcher too). A clean restart fixes it: `pkill -x qs; hyprctl dispatch 'hl.dsp.exec_cmd("qs -c ii")'`. A standalone test shell rendered the same icons fine, so it is a Quickshell icon-cache issue from reloads, not the code.
- Verified live: compile-check OK; the utilities drawer and the pinned dock render (screenshots); 1 warning in a fresh log (missing `vi_VN.json` translation, upstream).
- Not yet clicked through (needs the user's pointer): hover previews, right-click menus, edit mode, eye-protection controls, per-app mixer.

## Follow-up: audio popout had no button (2026-10-05)
Caelestia's default `bar.statusIcons` has `audio` (and `microphone`) **disabled**, so the speaker icon that opens the audio popout, and with it the per-app mixer, was not on the bar. `dots/.config/caelestia/shell.json` (installed only if missing) enables `audio`. Caelestia only picked up the newly created `~/.config/caelestia/shell.json` after a shell restart.

## Follow-up: mixer icons (2026-10-05)
Brave Origin's stream says `application.icon-name = brave-browser` (not installed) and `binary = brave`, and no desktop entry matches either. The old fallback rendered a broken image. `StreamIcon` (AudioPopout.qml) now resolves, best first:
1. `application.icon-name`, if it exists in the icon theme.
2. The owning window: walk `/proc/<pid>/stat` parents from `application.process.id` to a pid with a Hyprland window (`HyprlandData.windowList`). Among windows of that process, the shortest class wins (`brave-origin` over web-app classes). The icon is resolved with `AppSearch.guessIcon`, like the dock.
3. A desktop entry for the binary / app name.
4. A `music_note` symbol (never a broken image).

## Follow-up: default terminal (2026-10-06)
Caelestia's `general.apps.terminal` defaults to `["foot"]`, which isn't installed. So launcher entries with `Terminal=true` (btop) and terminal actions (calculator `qalc`) silently did nothing. `shell.json` now sets `["kitty"]`, the same terminal as Super+Enter (Hyprland `terminal` variable → `kitty -1`) and end-4's `apps.terminal` (`kitty -1`, used by end-4 search results and `$sudo …`). Verified: the launcher's command (`kitty wrap_term_launch.sh btop`) opens btop in kitty.

## Follow-up: launcher run prefix `$` (2026-10-06)
end-4's `$` results ran the command detached (invisible output) and added a calculator row ("$echo hi" parsed as maths) and a web-search row. In the Caelestia launcher (`launcher/AppList.qml`, `shellResults`), `$` now gives:
- only `$` typed: a hint row ("Type a command to run · Opens in kitty, window stays open");
- `$<command>`: one row, "Run in kitty", which runs `[...general.apps.terminal, "fish", "-C", command]`. The output is printed, then an interactive fish stays open.
end-4's `LauncherSearch` service is unchanged, so the ii family keeps the original behaviour. Verified with typed input: hint row, single run row, and Enter opened kitty showing the command output.

## Follow-up: Caelestia-style on-screen keyboard (2026-10-06)
`modules/caelestia/osk/Osk.qml` replaces end-4's `OnScreenKeyboard` in the Caelestia family.
- Unchanged from end-4:
  - layouts from end-4's `layouts.js` (`osk.layout`);
  - the key logic from `OskKey` (press on down; Shift once = next key, twice quickly = caps lock; sticky modifiers), typing through `Ydotool` (needs ydotoold);
  - the `osk` IPC target and `oskToggle`/`oskOpen`/`oskClose` shortcuts;
  - the end-4 focus grab, so it works alongside other panels.
- New look: a Caelestia panel (`m3surfaceContainer`, large rounding, elevation); keys use `surfaceContainerHigh`, special keys `surfaceContainerHighest`. Pressed = `secondaryContainer` with a radius morph, toggled (Shift/caps/mods) = primary. Tonal pin/hide buttons; the window opens on the focused monitor.
- Verified: compile-check OK, renders (screenshot), no warnings.

## Follow-up: cheatsheet restyle, background games, background mute (2026-10-06)
- **Cheatsheet** (`modules/caelestia/cheatsheet/`) replaces end-4's in the Caelestia family.
  - Same data: `HyprlandKeybinds` categories and end-4's filtering/substitution logic and options; `periodic_table.js`.
  - Same `cheatsheet` IPC and shortcuts.
  - New look: Caelestia panel with tonal tab buttons; category cards with key caps (main key in `secondaryContainer`); Caelestia periodic-table tiles.
  - Esc, clicking outside, and Ctrl+Tab/PgUp/PgDn work as before.
- **Background rendering**, in user files (not the repo):
  - `custom/rules.lua`: `hl.window_rule({ match = { class = "^(steam_app_\\d+|gamescope)$" }, render_unfocused = true })`;
  - `custom/general.lua`: `misc.render_unfocused_fps = 60` (default 15).
  - Verified: `hyprctl getprop address:<Star Rail> render_unfocused` = `true`.
- **Background mute** (`modules/caelestia/BackgroundMute.qml`, `caelestia.backgroundMute { enable, classes }`, quick toggle "Mute games in background").
  - What it does: playback streams whose `application.process.id` owns a game window are muted while that window isn't focused, and unmuted when it is. Only streams it muted are unmuted.
  - Why the pid works: Wine games emit audio from the window's own process (Star Rail: `StarRail.exe` pid = stream pid).
  - Why the shell has to do it: games only see focus through Wine/X11 focus events, and many have no "mute in background" option.
  - Verified: with Claude focused, Star Rail's 3 streams became muted.

## Follow-up: "Caelestia" page in end-4's settings app (2026-10-06)
`modules/settings/CaelestiaConfig.qml`, the second page in `settings.qml`. It edits the same `config.json`, so changes apply live:
- **Panel style:** panel family (Caelestia / illogical-impulse / Waffle).
- **Dock (Caelestia):** enable, keep shown on startup, reveal at bottom edge, show on empty workspace, icon size, pinned apps (`dock.pinnedApps`, comma separated, committed on editing finished).
- **Utilities drawer:** System card, quick sliders; reset the quick-toggle order and visibility.
- **Dashboard tabs:** To do, Timer.
- **Games:** mute in background, game class regex (validated; an invalid regex keeps the old one), background game FPS.
- **Display:** VRR (off / always / fullscreen / fullscreen games).
- **Debug:** adapter self-test.

Background FPS and VRR use end-4's `HyprlandConfigOption`. It reads `hyprctl getoption` and writes `hyprland/shellOverrides/main.lua`, which loads last, so these override `custom/*.lua`.

Also: end-4's `ConflictKiller` opened its "Shell conflicts killer" dialog on every shell start because `kded6` runs on a Plasma account (KDE apps start it; the tray works alongside it). With the `shared-desktop` marker, only mako/dunst count as conflicts now.

## Follow-up: Caelestia-style settings app (2026-10-06)
- `settings.qml` now hosts `modules/caelestia/settings/SettingsFrame.qml`:
  - sidebar with title, a tonal "Config file" button (right-click copies the path) and pill navigation;
  - rounded page container with a close button and the same page fade/slide.
- The frame is a separate file because `import Caelestia.Config` brings its own `Config` type, which shadows end-4's `Config` (`Config.ready` broke in the first attempt).
- Page paths go through `Quickshell.shellPath()`, since they're relative to settings.qml.
- `ContentSection` (shared widget) renders each section as a card (title with the icon in primary, then options on `surfaceContainer`, large rounding). `OptionalMaterialSymbol` gained `iconColor`.
- Pages and their end-4 controls are unchanged. `ContentSection` is also used by end-4's welcome app, which gets the same cards.
- Ctrl+PgUp/PgDn/Tab still switch pages (the layout takes focus).
- Verified: screenshot, Ctrl+PgDn page switch, clean log.

## Follow-up: Wallhaven in the Anime tab (2026-10-06)
`services/Booru.qml` gains a `wallhaven` provider (`/mode wallhaven`).
- **API:** `https://wallhaven.cc/api/v1/search`: `q` = tags (empty = `toplist`), `categories` (config `sidebar.booru.wallhaven.categories`, default `010` = anime), `purity` (`100` safe; with `/lewd`, `110`, or `111` when an API key is set), `sorting` (config, default `relevance`), `page`. Wallhaven returns 24 per page.
- **Mapping:** grid `preview_url` = `thumbs.large`; Open/Download `file_url` = full `path`; `source` = the wallhaven page. "Tags" show the category, resolution and palette (the search API returns no tags).
- **API key:** `/wallhavenkey <key>` stores it in the keyring (`KeyringStorage` `apiKeys.wallhaven`, i.e. KWallet via Secret Service; `/wallhavenkey` alone clears it). It is sent as the `X-API-Key` header, and unlocks NSFW plus your account's filters. Get it at https://wallhaven.cc/settings/account.
- Verified: the live API response matches the mapping; both families compile; clean shell log.

## Follow-up: Ollama on LM Studio's models, no copies (2026-10-06)
- Install `ollama-cuda` (0.35.1; detects the RTX 5090 as CUDA compute 12.0, 31.4 GiB).
- It runs as a **user** service, `~/.config/systemd/user/ollama.service` (copy in `dots-extra/systemd-user/`, enabled), not the packaged system one:
  - `OLLAMA_MODELS=/mnt/games/Users/windy_dust_2025/.ollama/models`, on the same NTFS volume as LM Studio's `downloadsFolder`;
  - `OLLAMA_HOST=127.0.0.1:11434`, `OLLAMA_FLASH_ATTENTION=1`.
- `tools/ollama-import-lmstudio.sh [filter]`: for each LM Studio repo, sha256 each GGUF, **hard-link** it into the blob store as `sha256-<digest>`, then `ollama create lmstudio/<repo>` from a Modelfile with one `FROM` per file (split parts and `mmproj` projectors included). Ollama reports "using existing layer", so there is no copy and no extra space.
- Imported 7 models (~380 GB, 0 bytes extra): qwen3.8-27b (+vision), muse-glimmer-30b (+vision), qwen3-coder-next, gpt-oss-safeguard-120b, devstral-2-123b, laguna-s-2.1, nemotron-3-super-120b.
- Ollama 0.35 handles split GGUFs.
- Tested:
  - qwen3.8-27b: 2.4 s load, 78 tok/s (fully on the GPU);
  - gpt-oss-safeguard-120b (split): 36 s load, 39 tok/s (partly on the CPU).
- The AI chat lists Ollama models via `scripts/ai/show-installed-ollama-models.sh` when its service starts (restart the shell after importing).
- New LM Studio downloads: re-run the script; already-linked files are skipped.
- Caveat: if LM Studio deletes or re-downloads a model, Ollama keeps its hard link, so the space is only freed after `ollama rm`.

## Gap review: end-4 functions still unavailable in the Caelestia family (2026-10-08)
Method: every `quickshell:<action>` used by Hyprland keybinds, checked against the GlobalShortcuts/CustomShortcuts registered by the modules the Caelestia family loads. Plus PLAN.md phases, the docs, and runtime logs.

**Not working**
1. ~~`Super+J` → `quickshell:barToggle`: no handler~~ **fixed 2026-10-08** (ScreenState.barHidden).
2. Holding Super → `quickshell:workspaceNumber` (end-4 bar shows workspace numbers): no handler, no effect.
3. ~~Bar privacy indicators and updates counter~~ **added 2026-10-08** (status icons + popouts).
4. ~~Launcher actions calling the `caelestia` CLI~~ **fixed 2026-10-09**: Random → end-4 `randomFromCurrentFolder`, Settings → end-4 settings app, Variant → end-4 palette type, Scheme hidden.
5. Assistant **detach** (`sidebarLeftToggleDetach`) only toggles the drawer.
6. ii-only options in the settings app do nothing in this family (ii bar style/position, screen corners, ii dock, ii overview, notification popup monitor).

**Restyled:** workspace overview (`modules/caelestia/overview`: Super+Tab, plus Windows-style Alt+Tab: hold Alt, Tab / Shift+Tab step through workspaces in order, release Alt switches; `caelestia.overview.altTabSkipEmpty`), lock screen (hyprlock, Caelestia theme).

**Works, still end-4 styled** (PLAN Phase 7 / 8 restyle not done): polkit dialog, region tools (screenshot / OCR / Lens / record), screen translator, overlay widgets (Super+G), wallpaper selector, Assistant contents (AI / translator / anime), Todo / Timer tabs.

**Plan items open:** Phase 8 Caelestia lock with end-4's PAM + keyring flow; Phase 9 performance measurement, visualiser off in fullscreen games, KEYBINDS/UPDATING docs; open question 1 (KDE apps show Oxygen colours in Hyprland because `kdeglobals` is shared).

**Fixed during the review:** `notifications.forceMonitor` (upstream rename 9e1568f missed `Config.qml`; the settings Interface page threw TypeErrors and the ii notification popup read `undefined`).

**About page:** a "Dotfiles: Caelestia" section (logo tinted for the dark theme, caelestia-dots/caelestia, shell source, issues, Discord).

## Follow-up: Super+J, privacy and update icons (2026-10-08)
- **Super+J** (`quickshell:barToggle`): `KeybindBridge` toggles `ScreenState.barHidden` on the focused screen. `BarWrapper` uses `persistentNow = Config.bar.persistent && !barHidden` for the exclusive zone and visibility. Hidden = only the frame edge, windows re-flow, and hovering the edge still reveals the bar. Runtime only (shell.json untouched). Verified: global fired, bar hid and returned, the focused window moved 25 px and grew.
- **Privacy** and **updates** status icons (`bar/components/StatusIcons.qml`), always offered ahead of the configured list (unless shell.json lists `privacy`/`updates`) and collapsed when idle:
  - Privacy: a red `mic` icon while an audio-in stream is linked to a source; a red `screen_record` icon while any video source is linked. Computed from `Pipewire.linkGroups` (end-4's `Privacy` service assigns lists to bools, so it's always "true"). Popout `Privacy.qml` lists the apps.
  - Updates: `system_update_alt` + count from end-4 `Updates` (`checkupdates`, every `updates.checkInterval` min); red above `stronglyAdviseUpdateThreshold`. Popout `Updates.qml`: count, advice, **Update now** (end-4 `apps.update`: kitty + `pkexec pacman -Syu`), **Check again**.
  - Verified: a GStreamer test Video/Source with a linked consumer showed the red capture icon, which collapsed after; a fake `checkupdates` (3 lines) showed the icon with "3". Popouts not hovered yet.

## Follow-up: launcher actions without caelestia-cli (2026-10-09)
- `launcher/services/Actions.qml`: `caelestia …` commands are redirected. `wallpaper -r` → `Wallpapers.setRandom()` (end-4 `randomFromCurrentFolder`, colours regenerate); `shell nexus open` → `qs -p settings.qml` (end-4 settings app). Anything else logs a warning. The **Scheme** action (named schemes, caelestia-cli only) is filtered out.
- `M3Variants.qml`: a variant sets end-4 `appearance.palette.type` (`tonalspot` → `scheme-tonal-spot`, …) and runs `switchwall.sh --noswitch --type <type>`. `--type` is passed explicitly because the shell writes config.json with a delay; without it, switchwall re-read the old type and nothing changed. Caelestia's `vibrant` (no end-4 equivalent) is replaced by end-4's **Auto**.
- `Schemes.qml`: no caelestia-cli processes; `currentVariant` mirrors end-4's palette type, so the variant list ticks the active one.
- Verified with typed input: the action list (no Scheme), the variant list (Auto ticked), Monochrome recoloured (primary `#a0cafd` → `#ffffff`), Settings opened the settings app, Random switched the wallpaper and colours. Then restored to Auto + the previous wallpaper.
