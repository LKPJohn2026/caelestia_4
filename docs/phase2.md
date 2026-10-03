# Phase 2: Family skeleton + adapters (log)

## 2.1 Adapter strategy: revised from PLAN §3.3 (2026-10-03)

The plan assumed one adapter per Caelestia service, each over an end-4 service. After measuring what the
Caelestia UI actually uses (`grep` of `Service.member` over all UI except `nexus`) and checking what each
service **owns**, the rule became:

> **Back a service with end-4 only if it owns something that must be single:** a D-Bus name, a hardware
> bus, the colour pipeline, or a dependency on `caelestia-cli` (not installed). Otherwise reuse
> Caelestia's own thin wrapper over Quickshell / NetworkManager / PipeWire / Hyprland.

### Backed by end-4 (hand-written adapters in `modules/caelestia/adapters/`)
| Adapter | end-4 source | Why it must be end-4 | Not supported (yet) |
|---|---|---|---|
| `Colours` | `Appearance.m3colors` (58 of 74 roles bound live; key colours mapped; term0-15 = Caelestia defaults) | one colour pipeline (end-4 matugen); Caelestia reads `caelestia-cli` scheme files | colour **preview** while browsing wallpapers |
| `Notifs` + `NotifData` | `Notifications` (list mirrored by id, newest first; `dnd` ↔ `silent`; close → `discardNotification`; popup hide → `timeoutNotification`; hover → end-4 timer stop/start; urgency string → enum) | only one notification server may own `org.freedesktop.Notifications` | — |
| `Wallpapers` | `Wallpapers.apply` / `randomFromCurrentFolder`; current = `Config.options.background.wallpaperPath` | applying runs end-4's colour generation; Caelestia would call `caelestia wallpaper` | colour preview (image preview works) |
| `Recorder` | `scripts/videos/record.sh` (wf-recorder; state via `pgrep -x wf-recorder`) | Caelestia calls `caelestia record` | **pause** (wf-recorder can't) |
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
  3. Log out/in. Super+Alt+W ×2 → `caelestia`, then check the probe output in `qs log -c ii`.
- **Done when:** Super+Alt+W cycles ii → waffle → caelestia (blank) → ii without errors, and the log shows `[caelestia4 probe] OK` for every adapter.
