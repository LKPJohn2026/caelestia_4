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
Method: every `quickshell:<action>` used by Hyprland keybinds, checked against the GlobalShortcuts/CustomShortcuts registered by the modules the Caelestia family loads. Plus docs/dev/PLAN.md phases, the docs, and runtime logs.

**Not working**
1. ~~`Super+J` → `quickshell:barToggle`: no handler~~ **fixed 2026-10-08** (ScreenState.barHidden).
2. Holding Super → `quickshell:workspaceNumber` (end-4 bar shows workspace numbers): no handler, no effect.
3. ~~Bar privacy indicators and updates counter~~ **added 2026-10-08** (status icons + popouts).
4. ~~Launcher actions calling the `caelestia` CLI~~ **fixed 2026-10-09**: Random → end-4 `randomFromCurrentFolder`, Settings → end-4 settings app, Variant → end-4 palette type, Scheme hidden.
5. Assistant **detach** (`sidebarLeftToggleDetach`) only toggles the drawer.
6. ii-only options in the settings app do nothing in this family (ii bar style/position, screen corners, ii dock, ii overview, notification popup monitor).

**Restyled:** workspace overview (`modules/caelestia/overview`: Super+Tab, plus Windows-style Alt+Tab: hold Alt, Tab / Shift+Tab step through workspaces in order, release Alt switches; `caelestia.overview.altTabSkipEmpty`), lock screen (hyprlock, Caelestia theme), polkit dialog (`modules/caelestia/polkit`), region tools (`modules/caelestia/regionSelector`: screenshot / Lens / OCR / record, shape and action switchable from the toolbar), screen translator (`modules/caelestia/screenTranslator`).

**Works, still end-4 styled** (PLAN Phase 7 / 8 restyle not done): overlay widgets (Super+G), wallpaper selector, Assistant contents (AI / translator / anime), Todo / Timer tabs.

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
- `launcher/services/Actions.qml`: `caelestia …` commands are redirected. `wallpaper -r` → `Wallpapers.setRandom()` (end-4 `randomFromCurrentFolder`, colours regenerate); `shell nexus open` → `WindowFactory.create()` (the Nexus control centre, ported 2026-10-12). Anything else logs a warning. The **Scheme** action (named schemes, caelestia-cli only) is filtered out.
- `M3Variants.qml`: a variant sets end-4 `appearance.palette.type` (`tonalspot` → `scheme-tonal-spot`, …) and runs `switchwall.sh --noswitch --type <type>`. `--type` is passed explicitly because the shell writes config.json with a delay; without it, switchwall re-read the old type and nothing changed. Caelestia's `vibrant` (no end-4 equivalent) is replaced by end-4's **Auto**.
- `Schemes.qml`: no caelestia-cli processes; `currentVariant` mirrors end-4's palette type, so the variant list ticks the active one.
- Verified with typed input: the action list (no Scheme), the variant list (Auto ticked), Monochrome recoloured (primary `#a0cafd` → `#ffffff`), Settings opened the settings app, Random switched the wallpaper and colours. Then restored to Auto + the previous wallpaper.

**Keyring check fixed for KWallet:** end-4's `scripts/keyring/is_unlocked.sh` asked gnome-keyring's `login` collection, so with
KWallet a missing `illogical-impulse` entry looked "locked" and KeyringStorage never finished loading (stored API keys:
Google Cloud for the screen translator, Wallhaven, … never loaded or saved). It now asks the Secret Service for its default
collection (`kdewallet`). Content-region detection in the region selector and text colours in the translator need end-4's
Python venv (`~/.local/state/quickshell/.venv`, end-4 installer), not set up here: those features quietly do nothing.

## Follow-up: AI chat on the Gemini Interactions API (2026-10-09)
- Google now recommends the **Interactions API** (`POST /v1beta/interactions`, GA); `generateContent` (what end-4 used,
  `…/models/<m>:streamGenerateContent`) is "legacy". Gemini 2.5 is restricted to existing users and isn't accepted by
  the Interactions API at all.
- New `api_format: "gemini-interactions"`: `services/ai/InteractionsApiStrategy.qml` + `services/ai/interactions.js`.
  - Stateless (`store: false`): the whole chat goes out as steps each turn (`user_input`, the model's own steps
    unchanged incl. thought signatures, `function_result` with the call's `call_id`). Editing / regenerating /
    switching models / loading saved chats keep working. Raw steps are kept per message (`providerSteps`, saved with chats).
  - Streaming SSE (`stream: true`): `step.start` / `step.delta` (text, thought_summary, thought_signature,
    arguments_delta, text_annotation_delta, google_search_call/result) / `step.stop`, `interaction.completed` (usage).
    Thought summaries show as end-4's collapsible think block; citations as source chips; search queries as chips.
  - Key in the `x-goog-api-key` header; body via heredoc + attachments base64-inlined by jq (images, PDFs, audio,
    video, text files; earlier turns' files are resent; no Files API upload).
  - Function calls are handled after curl exits (Ai.qml `deferredFunctionCall`), so the follow-up request starts on a
    stopped Process.
- Models (from https://ai.google.dev/gemini-api/docs/models): **Gemini 3.8 Flash** (default, free tier),
  **Gemini 3.5 Flash-Lite** (free tier), **Gemini 3.1 Pro** (`gemini-3.1-pro-preview`, paid only). Saved choices
  `gemini-2.5-flash` / `gemini-3-flash` map to 3.8 Flash. User `extraModels` with `api_format: "gemini"` still use
  the old strategy.
- Tests: `node tools/test-gemini-interactions.js` (streams shaped per the API reference). Live run checked up to the
  API (request accepted by the endpoint, error rendering); no Gemini key is stored yet, so no real answer was tested.

## Gap review: full pass before the uwsm move (2026-10-11)
Method: (1) every `quickshell:<x>` in Hyprland keybinds vs GlobalShortcut/CustomShortcut handlers in what the Caelestia
family loads; (2) every end-4 GlobalShortcut and IpcHandler target vs ours; (3) every `ipc call` in configs/scripts;
(4) end-4 services nothing in the family references; (5) end-4 module features side by side (session, OSD,
notifications, bar, background, screen corners); (6) external tools; (7) the live shell log.

**Complete:** all 28 keybound shell shortcuts have handlers; all IPC calls used by configs/scripts
(`cliphistService`, `panelFamily`, `dock`) are answered; every end-4 service is reachable except `SessionWarnings`
(session screen only), `TrayService` (end-4 tray pinning) and `LauncherApps` (dead upstream). Tools all present except
the ones below.

**Broken**
1. ~~**end-4 Python venv missing**~~ **fixed 2026-10-11** (`~/.local/state/quickshell/.venv`, created by end-4's installer, never set up here):
   - `switchwall.sh` → `generate_colors_material.py` fails silently: `material_colors.scss` is empty, so
     `generated/terminal/kitty-theme.conf` / `sequences.txt` keep raw `#$term0 #` placeholders: **terminal colours don't
     follow the wallpaper** and junk sequences are written to open terminals. (Shell/app colours are fine: matugen.)
   - screen translator: `token-from-key-venv.sh` (google-auth) can't get a token even with a key;
   - region selector content regions, translator text colours (opencv/numpy).
   - (Wallpaper-selector thumbnails are fine: ImageMagick fallback.)
2. ~~`easyeffects` started every login though not installed~~ **fixed 2026-10-11** (only if installed).

**Missing in the Caelestia family**
3. Session menu: Caelestia has logout / shutdown / hibernate / reboot; end-4 also has **lock, sleep, task manager,
   reboot to firmware**, and warns when the package manager is running or a download is in progress.
4. Holding Super: `workspaceNumber` sets `GlobalStates.superDown`, but only end-4's bar reads it (no numbers shown).
5. OSD: no gamma indicator (end-4 shows it when brightness keys fall back to hyprsunset gamma).
6. Assistant detach (`sidebarLeftToggleDetach` only toggles).
7. Video wallpapers: `mpvpaper` not installed and Caelestia's background loads the path as an image (end-4 shows the
   thumbnail).
8. Aliases only for manual use: shortcuts `barOpen`/`barClose`, `osdVolumeTrigger`/`osdVolumeHide`; IPC targets `bar`,
   `sidebarLeft`, `sidebarRight`, `session`, `mediaControls`, `osdVolume`.

**Different by design (feature exists elsewhere):** bar media / resources / weather / unread count / utility buttons →
dashboard tabs and the utilities drawer; floating media controls → dashboard media tab; screen corners + hot corners →
Caelestia frame + edge hover; ii-only settings (bar style, screen corners, ii dock/overview, popup monitor, tray
pinning) have no effect. Inline notification replies: neither shell.

**Still end-4 styled:** overlay widgets (Super+G), wallpaper selector, Assistant contents, Todo/Timer tabs.

**Log:** only noise (monitor hot-unplug "dangling screen"/"screen not set" from the G95NC DP drop, notifications
restored from disk with missing fields).

## Fix: keep awake didn't stop lock / screen-off / suspend (2026-10-11)
- Symptom: with keep awake on, the PC still suspended after a while. The journal shows every suspend came from
  `systemctl` in the user's session (hypridle's 15-min listener), i.e. hypridle never saw the inhibitor.
- Cause: end-4's `Idle` service only used a Wayland idle inhibitor on a 1x1 layer surface with no screen set. Hyprland
  counts it only while the surface is "alive and visible" (`recheckIdleInhibitorStatus`), and the surface is lost when
  the G95NC drops off DP (`drm: Connector DP-2 disconnected`, "dangling screen" warnings).
- Fix (`services/Idle.qml`, shared by both families): while inhibiting, also hold
  `systemd-inhibit --what=idle --mode=block` (hypridle honours logind idle inhibitors; independent of surfaces). Only
  `idle`, so a deliberate suspend still works. The inhibitor window now binds `screen: Quickshell.screens[0]` so it is
  recreated after a monitor drop.
- Verified: logind `BlockInhibited` = "idle" exactly while keep awake is on; a test hypridle listening only to logind
  (3 s timeout) logged "Ignoring from onIdled(), inhibit locks: 1" with keep awake on and fired with it off.

## Fix: end-4 Python venv, kitty config, EasyEffects (2026-10-11)
- **venv** created as end-4's installer does: `uv venv -p 3.12` at `~/.local/state/quickshell/.venv` +
  `sdata/uv/requirements.txt` (all 16 imported modules load). `tools/install-main.sh` now creates it if missing.
  - Wallpaper colours → terminals work again: `material_colors.scss` is filled and `applycolor.sh` substitutes all
    `$termN` placeholders (it runs in the background, so the file updates ~1 s after `switchwall.sh` returns).
  - Translator sign-in script runs (a dummy key fails on the key itself, not on imports).
- **kitty** was never using end-4's config: `copy_if_missing` did `cp -a src dst` into an existing empty
  `~/.config/kitty`, nesting it as `~/.config/kitty/kitty/kitty.conf`. Moved up; kitty now loads it (JetBrains Mono,
  fish, wallpaper theme include, Ctrl+C copy-or-interrupt, Ctrl+F search). `copy_if_missing` copies contents now.
- **EasyEffects**: not installed; end-4's autostart now starts it only if present (`command -v easyeffects`).
  (Under uwsm it isn't started at all, see docs/uwsm.md.)

## Upstream syncs (2026-10-11)
- **end-4**: merged `upstream/main` (18 commits; no conflicts). Relevant: OS-name parsing (`SystemInfo.qml`), suppress
  app maximize requests, scroll-direction fix in binds, no blur behind `quickshell:background` (doesn't apply to
  `caelestia-background`: Hyprland rule patterns match the whole namespace). Upstream also pins Quickshell `4f508be`,
  the same as `caelestia4-quickshell`.
- **Caelestia**: subtree `third_party/caelestia-shell` d999d487 (v2.5.0) → `21a75375` (main, +20: PipeWire
  correctness, audio collector quantum, per-monitor tokens, Lyrics NOTIFY, qalc format, …); plugin rebuilt
  (`tools/build-caelestia-plugin.sh`, revision updated). The "Config.* accessed without a screen set" warnings
  (80+ per session) are gone. QML changes ported into our copies: `Workspace.qml` (bool onOtherMonitor),
  `LyricList.qml` (workaround removed), `drawers/ContentWindow.qml` (toplevels count). `lock/` and `nexus` changes
  don't apply (hyprlock); `nexus` is used since 2026-10-12, sync it like the other modules.

## De-duplication (2026-10-11)
- **Network**: one `nmcli monitor` instead of two. `modules/caelestia/adapters/Nmcli.qml` (upstream Caelestia, 1.8k
  lines, own monitor + scans) replaced by a ~230-line adapter over end-4's `Network` service: Wi-Fi state/list/
  enable/scan/disconnect delegate to end-4 (its `WifiAccessPoint` has the same properties as Caelestia's
  `AccessPoint`); wired devices, connect-with-result/password check, saved profiles and forget are one-off nmcli calls
  refreshed on end-4's monitor events. Verified headless: `enp9s0` connected → `activeEthernet`, Wi-Fi radio off →
  no networks (matches `nmcli`).
- **Keep awake**: the end-4 `idleInhibitor` quick toggle is gone from the utilities drawer; the Keep Awake card is the
  one control (same Idle service).
- **Orphaned keep-awake lock**: when the shell was killed (plain-session restart `killall qs`), `systemd-inhibit`
  survived and kept idle blocked. The held command is now a loop that exits within 5 s of the shell's death
  (tested with a stand-in parent). (General: Quickshell children such as `nmcli monitor` also outlive a killed
  shell in the plain session; under uwsm the shell unit's cgroup is killed as a whole.)
- Not duplicated (checked): fallback keybind pairs, recording/screenshot backends, notifications/DND/idle adapters,
  weather (only Caelestia's runs), daemons. Upstream Caelestia's runtime Caps/Num Lock binds accumulate per shell
  start (harmless, upstream).

## Gaps closed + cleanup before uwsm (2026-10-11)
**Gaps closed**
- Session menu: + lock, sleep, reboot to firmware, task manager (end-4 `Session` functions) and end-4's warnings
  (package manager running / download in progress, refreshed when the menu opens). Logout/shutdown/hibernate/reboot
  stay Caelestia's (logind; end-4's logout is `pkill Hyprland`, which uwsm warns against).
- Bar: holding Super shows workspace numbers (`GlobalStates.superDown`, end-4 `showNumberDelay` 300 ms, cancelled when
  Super is used in a shortcut; `alwaysShowNumbers` respected).
- OSD: gamma slider (wb_twilight) while hyprsunset gamma < 100 % (brightness lowered past 0), shown on change.
- Aliases: shortcuts `barOpen`/`barClose`/`osdVolumeTrigger`/`osdVolumeHide`; IPC targets `bar`, `sidebarLeft`,
  `sidebarRight`, `session`, `mediaControls`, `osdVolume` → Caelestia drawers.
- Not yet: Assistant detach, video wallpapers (no mpvpaper).

**Cleanup**
- Waffle family removed (145 files; ii family kept as Ctrl+Super+P fallback). `CalendarView` (only used by Waffle)
  stays as unused upstream code. `tools/sync-end4.sh` merges end-4 and keeps removed paths removed (modify/delete
  conflicts resolved, files added under removed dirs dropped); tested on a clone with a fake upstream.
- Removed the Phase 2 adapter self-test (`AdapterProbe`, `caelestia.debugProbe`, settings Debug section) and 4
  unused Caelestia components (VerticalFadeFlickable/ListView, WavyTopRect, AnimLoader).
- Kept on purpose (sync-friendly): end-4 files we don't load (ii modules for the fallback family, other-distro
  installers in sdata/, LauncherApps, legacy GeminiApiStrategy for user `gemini` models).
- Local build leftovers (untracked, regenerable): `packaging/caelestia4-quickshell/{src,pkg}`, the 0.3.1 package,
  `build/caelestia-plugin` (~4.4 GB).

## RAM investigation: "38 GiB used" (2026-10-11)
- Breakdown: apps (AnonPages) 13.4 GiB; **zram 16.8 GiB** holding 27.9 GiB of swapped pages at a poor 1.66× ratio;
  shmem/slab/page tables ~5.4; drivers ~2. btop's "used" includes zram's compressed pages, which belong to no process.
- Cause: `/tmp` (tmpfs = RAM) held **26 GiB in `/tmp/cursor-sandbox-cache`**. Cursor's agent sandbox points every
  package manager cache (npm, pip, uv, Playwright Chromium, cargo, …) at `os.tmpdir()/cursor-sandbox-cache/<random>`,
  a new random folder per Cursor start, never cleaned. Mostly incompressible archives → poor zram ratio.
- Fix (user's choice: keep in RAM, auto-clean): `~/.config/user-tmpfiles.d/cursor-sandbox-cache.conf`
  (`e /tmp/cursor-sandbox-cache - - - 1d`, copy in `dots-extra/user-tmpfiles.d/`) + user
  `systemd-tmpfiles-clean.timer` enabled (daily). First run: /tmp 27 GiB → 430 MiB, zram RAM 16.8 → 1 GiB,
  used 38 → 22 GiB.
- uwsm wouldn't have prevented it (Cursor already runs in its own scope; the tmpfs pages were charged to it). The
  real uwsm benefit found: `systemd-oomd` (active, swap limit 90 %) kills the unit with the most swap, and today
  Hyprland + shell + Steam + games share `session-5.scope`, so an OOM caused by a game could take down the session.
  uwsm gives each app its own unit (uwsm README: piling apps into the compositor's unit is "bad practice").

## Settings app rebuilt (2026-10-11)
- Standard structure, one setting per row (icon, title, one-line description, control on the right; whole row
  toggles switches): **Appearance, Desktop, Windows, Input, Display, Sound, Power & idle, Apps & services, Games,
  Advanced, end-4 panels (fallback), About**. Pages + rows in `modules/settings/c4/` (imported as a module in
  `settings.qml`, otherwise Quickshell's scanner finds the row types piecemeal). end-4's original page files stay in
  the repo unlisted (sync-friendly); our old `CaelestiaConfig.qml` page is gone (contents moved).
- Sources written: end-4 `config.json` (`Config.options`), Caelestia `shell.json` (`Caelestia.Config as CC`,
  `CC.GlobalConfig.x = v`, only changed keys saved), Hyprland options (`Hyp*Row`: live `hyprctl getoption`, saved
  by end-4's configurator to `hypr/hyprland/shellOverrides/main.lua`, which loads last), hypridle timers
  (`scripts/caelestia4/hypridle-timeouts.sh` → `~/.config/hypr/hypridle-timeouts.conf`, sourced by
  `hypridle.conf`; restarts hypridle as unit or Hyprland child), monitors (`hl.monitor` live + 15 s keep/revert,
  `scripts/caelestia4/monitors-save.sh` → `monitors.lua`, previous kept as `.bak`).
- New: ~60 Caelestia options (bar, status icons, dashboard, launcher, notifications, OSD, toasts, transparency,
  scales, frame, fonts), ~27 Hyprland options (gaps, borders, rounding, opacity, blur, shadows, animations, layout,
  keyboard layouts/options/repeat, pointer speed/accel, natural scroll, follow mouse, VRR, background fps),
  idle timers, display mode/scale/rotation.
- Fixes found on the way: end-4's Hyprland option saving never worked here before the venv (VRR / background fps
  settings didn't persist); the installer would have overwritten `shellOverrides/main.lua` (now excluded);
  `StyledComboBox` icon `active` was `undefined` (bool warning); `CalendarView` removed with Waffle.
- Checks: `tools/check-settings-pages.sh` instantiates every page headlessly (all clean); the settings app launched
  silently on a spare workspace (no warnings); Hyprland rows read live values (gaps 4, blur on, vrr 2, …) and a
  save round-trips through the overrides file.

## Anime tab: unreachable APIs fixed (2026-10-12)
Live test per provider (empty search, safe, page 1) before → after:
- **danbooru** 403 (Cloudflare "Just a moment" for the fake Chrome user agent) → honest app UA `caelestia4-booru/1.0` → OK.
- **zerochan** 503/500: an empty `c=` gave an error page; and the API itself answers **HTTP 500 with valid JSON**
  wrapped in a stray leading `{` and trailing page HTML → `c=` only with a search term, status 500 accepted,
  `parseFirstJsonObject()` extracts the real object → OK (AVIF thumbnails load via kimg_avif).
- **waifu.im** 400 ("Value cannot be null") from an empty `IncludedTags=` → only sent with tags → OK.
- **t.alcy.cc** returned the HTML home page (API needs a category path) → default category `pc`; only image-URL
  lines parsed (unknown categories answer "404 page not found") → OK.
- **gelbooru** 401: the API is now key-only → `/gelboorukey <api_key> <user_id>` (keyring `apiKeys.gelbooru`); without
  a key the tab explains where to get one instead of failing.
- yande.re, konachan, wallhaven already worked. Errors now say what happened (unreachable / refused / rate-limited /
  server problem) instead of the generic tip.
- Verified through the service: all 8 return images (gelbooru: the key guidance).

## Random wallpaper: sources + "fill my screen" (2026-10-12)
- Settings > Appearance > Wallpaper: **source** (Wallhaven general+anime; Konachan and yande.re when the Anime tab
  policy is Shown), **"Only wallpapers that fill my screen"** (at least the largest monitor, 7680×2160 here) and a
  **Get one** button with live status. Config: `caelestia.randomWallpaper.{source, matchScreen}`.
- `scripts/caelestia4/random-wallpaper.sh <source> [min-w min-h]`: the server filters size (Wallhaven
  `atleast=`+`ratios=landscape`, Moebooru `width:>= height:>=`); Moebooru picks the first landscape post of 50 random
  ones; saved/applied like end-4 (alternating `random_wallpaper[-1].ext`, `switchwall.sh --image`); exit 2 + message
  when nothing that large exists (yande.re rarely has 8K). `DRYRUN=1` stops before downloading.
- Dry runs at 7680×2160: Wallhaven 8192×4096, Konachan 10039×4134, yande.re "none that large".
- end-4's **osu! seasonal** source is dropped from the picker: `osu.ppy.sh/api/v2/seasonal-backgrounds` now answers
  403 (Cloudflare) to every request. end-4's script file stays untouched.
- **/mode** (2026-10-12): "Invalid API provider" came from (1) Enter sending the typed text and ignoring the highlighted
  suggestion (`/mode` or `/mode wa` → empty/partial name), (2) the list showing display names ("yande.re") while
  lookup used keys (`yandere`), (3) arguments split on single spaces (double space → empty). Now `Booru.resolveProvider`
  matches key or display name ignoring case/punctuation, or a unique prefix; Enter on `/mode` takes the highlighted
  provider; `/mode` alone shows the current provider and choices; args split on any whitespace.
- **Screen shape first** (2026-10-12): new switch "Prefer my screen's shape (32:9)" (`caelestia.randomWallpaper.
  preferScreenRatio`, default on), independent of "fill my screen". Order: exact monitor resolution (when filling the
  screen) → same aspect ratio (Wallhaven `ratios=32x9`, with `atleast=` when filling; Moebooru: 100 random posts
  ranked by closeness to 32:9, within 2 % = same shape) → closest shape / any landscape. Status shows the tier.
  Dry runs at 7680×2160: Wallhaven exact 7680×2160 / 32:9 without size floor; Konachan exact / 32:9 3498×975;
  yande.re closest shape (no 32:9 there).

## end-4 panels removed (2026-10-12)
Final gap review before removal (live, uwsm session): all 29 keybound shell shortcuts and every IPC call from configs/
scripts are handled by the Caelestia family; end-4's quick toggles are covered by the utilities drawer. Closed first:
- **Assistant detach**: Super+Alt+A / Ctrl+D pops the Assistant into a normal window (`assistant/DetachedWindow.qml`),
  Super+A shows/hides it while detached; again to reattach.
- **Video wallpapers**: Caelestia's background shows end-4's first-frame thumbnail and, while `mpvpaper` runs, turns
  transparent one layer above it (`Wallpapers.isVideo`/`videoPlaying`). Under uwsm mpvpaper is its own unit. Needs
  `sudo pacman -S mpvpaper`.
- **Desktop weather**: beside Caelestia's desktop clock (Caelestia Weather service, refreshed every 30 min). New
  settings section Desktop > "Desktop clock & weather" (the clock had no setting before).

Removed: the ii panel family (`IllogicalImpulseFamily`, Ctrl+Super+P, settings "end-4 panels" page and "Panel set"
row) and 127 files of end-4 modules nothing else loads (bar, vertical bar, background, dock, media controls,
notification popup, OSD, overview, polkit, screen corners, screen translator, session screen, right sidebar except
todo/pomodoro/volumeMixer). Kept (the Caelestia family reuses them): lock, overlay, wallpaper selector, sidebarLeft
(Assistant), todo/pomodoro, cheatsheet + OSK data, region selector, all services and the settings app. The lock
screen's tray files moved from `modules/ii/bar` to `modules/ii/lock`. `tools/sync-end4.sh` keeps all of it removed.
`tools/compile-check.sh` now uses the running compositor when sway isn't installed (compile only, nothing created).

## Remaining end-4 parts restyled to Caelestia (2026-10-12)
Logic stays end-4's (services, Persistent state, IPC, shortcuts, keys); the UI is Caelestia components and tokens.
- **Dashboard Todo / Timer** (`dashboard/TodoTab.qml`, `TimerTab.qml`): inline "Add a task" field, To do / Done chips;
  pomodoro ring (CircularProgress, wavy while running), stopwatch with a laps panel. Keys as before.
- **Wallpaper selector** (`wallpaperSelector/WallpaperSelector.qml`, Ctrl+Super+T): places sidebar, path bar (click or
  Ctrl+L to type), Caelestia cached thumbnails instead of end-4's thumbnail script, search / Random / Dark-Light /
  system picker. Videos listed (end-4 `Wallpapers.extensions` + mp4/webm/mkv/avi/mov).
- **Overlay widgets** (Super+G, moved to `modules/caelestia/overlay`): Caelestia frame and title buttons, pill taskbar
  (right-click a widget button recentres it), recorder / resources / FPS limiter / notes in Caelestia controls, mixer
  rebuilt on Caelestia's Audio adapter with the shared `components/widgets/StreamIcon.qml` (also used by the bar popout).
- **Assistant** (moved to `modules/caelestia/assistant`): tonal tabs, EmptyState, composer with a round send button,
  chips for model/tool/commands/tags, key caps; end-4 colour/rounding tokens mapped to Colours/Tokens throughout.
  Deeper buttons (think-block expand, sources, attachments, next page, language picker, image actions) are still
  end-4 RippleButtons, now in Caelestia colours.
- Gotchas found: Caelestia.Config's attached `Config` shadows end-4's `Config` regardless of import order (alias it,
  `CC.Tokens`); later imports win for same-named QML types (StyledText); an inline component named `Key` compiled in
  the compile check but failed at runtime ("Key is not a type") - always read the live log after deploying.
