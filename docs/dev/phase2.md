# Phase 2: Family skeleton + adapters (log)

## 2.1 Adapter strategy: revised from PLAN §3.3 (2026-10-03)

The plan assumed one adapter per Caelestia service, each over an end-4 service. After measuring what the
Caelestia UI actually uses (`grep` of `Service.member` over all UI except `nexus`) and checking what each
service **owns**, the rule became:

> **Back a service with end-4 only if it owns something that must be single:** a D-Bus name, a hardware
> bus, the colour pipeline, or a dependency on `caelestia-cli` (not installed). Otherwise reuse
> Caelestia's own thin wrapper over Quickshell / NetworkManager / PipeWire / Hyprland.

### Backed by end-4 (hand-written adapters in `modules/caelestia/adapters/`)
> **2026-10-22, backend step 1:** `Notifs`/`NotifData`, `Nmcli` and `Brightness` are now upstream Caelestia's own
> services again (end-4's Notifications, Network and Brightness are no longer instantiated), and battery warnings come
> only from Caelestia's BatteryMonitor. Still backed by end-4: `Colours`, `Wallpapers`, `Recorder`, `IdleInhibitor`.
> **2026-10-22, backend step 2:** plugin at 29fcf69a (Multimedia, Shaders, State modules). The background, Nexus
> preview, Nexus wall grid and launcher items draw through Caelestia.Multimedia's `Visual` / `WallpaperImpl`
> (`components/widgets/WallpaperImpl.qml`, transition from shell.json `background.wallpaperTransition`). `Wallpapers`
> still applies through end-4 and lists videos too; a video wallpaper stays on mpvpaper (`WallpaperImpl` never plays,
> see the measurements in docs/feature-comparison.md). Transition ShaderEffects log "no GLSL ES version in common" once
> (Qt's default vertex shader vs the 300es/330 fragment shaders); harmless on desktop GL, checked by rendering.
> **2026-10-22, backend step 3:** colours come from caelestia-cli (AUR `caelestia-cli`, config
> `~/.config/caelestia/cli.json`): wallpaper colours with end-4's colour style as the Material variant, or its preset
> schemes, kept in `~/.local/state/caelestia/scheme.json`, which `Colours` reads directly again (all roles + term0-15).
> Its postHook `scheme.py bridge` renders end-4's outputs from that scheme (matugen json → colours.json, Hyprland,
> hyprlock, fuzzel theme; material_colors.scss → applycolor.sh → terminals, kitty, apptheme.py). switchwall.sh stays the
> entry point (`scheme.py wall` / `scheme.py mode`); only an accent colour (`--color`) still uses matugen, and then the
> Caelestia half keeps the scheme colours. cli.json leaves GTK, Qt, htop, fuzzel, Discord, Chromium, Hyprland and
> terminals off (end-4 / apptheme.py do those without overwriting user files). Without caelestia-cli everything falls
> back to the old matugen path. `services.smartScheme` stays unused (always `--no-smart`: light/dark is end-4's switch).
| Adapter | end-4 source | Why it must be end-4 | Not supported (yet) |
|---|---|---|---|
| `Colours` | `Appearance.m3colors` (58 of 74 roles bound live; key colours mapped; term0-15 = Caelestia defaults) | one colour pipeline (end-4 matugen); Caelestia reads `caelestia-cli` scheme files | colour **preview** while browsing wallpapers |
| `Notifs` + `NotifData` | `Notifications` (list mirrored by id, newest first; `dnd` ↔ `silent`; close → `discardNotification`; popup hide → `timeoutNotification`; hover → end-4 timer stop/start; urgency string → enum) | only one notification server may own `org.freedesktop.Notifications` | — |
| `Wallpapers` | `Wallpapers.apply` / `randomFromCurrentFolder`; current = `Config.options.background.wallpaperPath` | applying runs end-4's colour generation; Caelestia would call `caelestia wallpaper` | colour preview (image preview works) |
| `Recorder` | `scripts/videos/record.sh` (gpu-screen-recorder since 2026-10-14, was wf-recorder; state via `pidof`, pause marker in `$XDG_RUNTIME_DIR`) | Caelestia calls `caelestia record` | — (pause added 2026-10-14) |
| `IdleInhibitor` | `Idle.inhibit` / `toggleInhibit` | one keep-awake state for both families | — |
| `Brightness` | `Brightness.getMonitorForScreen` wrapped in a `Monitor` type | two `ddcutil` managers would race on the DDC/CI bus | — |

### Caelestia's own, kept as-is (imports rewritten only)
`Audio`, `GameMode`, `Hypr`, `Nmcli`, `VPN`, `Players`, `Screens`, `ShellState`, `Time`, `Weather`.
- `Weather` stays Caelestia's: end-4's weather has current conditions only, but the dashboard needs a 7-day + hourly forecast.
- `Players`: IPC target renamed `mpris` → `caelestiaMpris` (end-4 owns `mpris`).
- Their settings come from Caelestia's `~/.config/caelestia/shell.json` (C++ `GlobalConfig`).

### Name-clash audit
- IPC targets: the only clashes were `brightness` (gone: the Brightness adapter registers none) and `mpris` (renamed).
- Global shortcuts: Caelestia's `CustomShortcut` uses `appid: "caelestia"`, end-4 uses `quickshell` → no clash.

## 2.2 Files
- `modules/caelestia/components/` and `utils/`: copied from Caelestia v2.5.0 + `tools/port-imports.sh`.
- `modules/caelestia/assets/`: Caelestia assets (logo, GIFs, fallback wallpaper, Google Sans Flex). `utils/SysInfo.qml` logo path changed to be file-relative (Caelestia used the shell root, which is now end-4's).
- `tools/port-imports.sh`: lines ending `// caelestia4: keep` are never rewritten (adapters import end-4's own `qs.services as E4`, `qs.modules.common as E4C`).
- end-4 files changed (kept minimal for upstream merges):
  - `shell.qml`: `families` += `"caelestia"`, plus a `PanelFamilyLoader`
  - `modules/common/Config.qml`: `panelFamily` comment + `caelestia { debugProbe }`
- New: `panelFamilies/CaelestiaFamily.qml` (empty family + probe), `modules/caelestia/AdapterProbe.qml`.

## 2.3 Verification
- Static: every new/changed QML file parses (`qmlformat`). Note: `qmlformat` **segfaults** on `adapters/VPN.qml` only when end-4's `.qmlformat.ini` (`MaxColumnWidth=110`) applies. Same file, outside `ii/` or with `--ignore-settings` → OK. This is a formatter bug, not a syntax error.
- Runtime: in `e4test` only. The full end-4 shell must not run in the main Plasma session (e.g. `ConflictKiller` targets `kded6`).
  1. As main user: `tools/stage-for-test.sh` → `/var/tmp/caelestia4-stage/`
  2. As `e4test`: `bash /var/tmp/caelestia4-stage/deploy.sh`. This backs up upstream `ii` once, installs the config + plugin, and adds `QML_IMPORT_PATH` to `~/.config/hypr/custom/env.lua`.
  3. Log out/in. Ctrl+Super+P ×2 → `caelestia`, then check the probe output in `qs log -c ii`.
- **Done when:** Ctrl+Super+P cycles ii → waffle → caelestia (blank) → ii without errors, and the log shows `[caelestia4 probe] OK` for every adapter.

> Correction: the panel-family key is **Ctrl+Super+P** (`hypr/hyprland/keybinds.lua:58`, `quickshell:panelFamilyCycle`). Super+Alt+W came from end-4's outdated waffle README. Alternative: `qs -c ii ipc call panelFamily cycle`.

## 2.4 First runtime test in e4test (2026-10-03)
- Family cycle (Ctrl+Super+P): ii → waffle → caelestia (blank) → ii works.
- Probe: **16/17 OK** (Notifs, Wallpapers, Recorder, IdleInhibitor, Brightness, Brightness.Monitor + all 10 kept Caelestia services).
- **Colours FAIL**: every member "missing", no error from Colours.qml. **Cause:** Quickshell's `pragma Singleton` pre-scan stops at the first `{` in the file, and the adapter's header comment contained `transparency{enabled,base,layers}` *above* the pragma. So `Colours` was registered as a plain type, not a singleton instance. The other adapters had pragma-after-comment too, but no `{` in their comments, so they worked by luck.
- **Fix:** all hand-written adapters now start with their `pragma` lines; comments follow. New `tools/lint-caelestia.sh` (run by `stage-for-test.sh`) fails if `{` comes before `pragma Singleton`, or if an unported `qs.*` import exists. Verified: it flags the old file and passes the fixed one.
- Other new warnings in the log are **upstream end-4** behaviour when switching ii ↔ waffle (duplicate IpcHandler registration while the old family unloads, waffle `AppButton` anchor, `WorkspaceModel` null id). None involve caelestia4 code.

## 2.5 Re-test after the fix: ✅ PHASE 2 COMPLETE (2026-10-03)
Two passes into the `caelestia` family, identical results:
- **18/18 checks OK, 0 FAIL**: all 17 adapters plus `Colours.palette` and `Brightness.Monitor`. The probe reaches `done`.
- Live data through the adapters:
  - `notifs mirrored: 8` (end-4's history)
  - `wallpaper: …/ii/assets/images/default_wallpaper.png` (end-4 config)
  - `light: false`, `primary: #d1c2d2` (end-4's generated palette)
- A real Caelestia component (`StyledText`) was created, so the plugin + ported components load in the session.
- No warnings or errors from any caelestia4 file.
