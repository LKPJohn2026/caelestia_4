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
