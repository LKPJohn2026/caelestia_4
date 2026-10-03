# Phase 3: Frame + bar, and the rest of the Caelestia design (log)

## 3.1 Scope change: Phases 3-6 ported together (2026-10-03)
Caelestia's frame (`drawers/ContentWindow.qml`, `Panels.qml`) references **every** drawer panel directly:
bar + popouts, dashboard, launcher, notifications, OSD, session, sidebar, utilities, toasts. The frame can't be
ported alone. Because Phase 2 already provides every service these panels use (adapters + plugin +
components), porting them all at once is mostly copy + `port-imports.sh`. PLAN Phases 3-6 are therefore
merged into one "first light" port; later work is runtime fixes plus end-4 feature integration.

Ported (Caelestia v2.5.0 → `modules/caelestia/`): `background`, `bar`, `dashboard`, `drawers`, `launcher`,
`notifications`, `osd`, `session`, `sidebar`, `utilities`, `windowinfo`, plus root helpers `Shortcuts`,
`GSFLoader`, `ServiceLoader`, `BatteryMonitor`. 196 QML files after porting; 203 in the family incl. new files.

**Deliberately not ported:**
- `lock`: Phase 8. end-4's lock is used meanwhile.
- `IdleMonitors`: end-4's hypridle owns idle → lock; a second idle manager would conflict.
- `areapicker`: end-4's region selector covers it.
- `nexus` (settings app): see the stand-in below.

## 3.2 Fixes applied while porting
- Shell-root paths → `modules/caelestia/assets/…`: `GSFLoader` font, `launcher/services/Apps.qml` terminal wrapper (Phase 2: `SysInfo` logo).
- **`nexus` stand-in** (`modules/caelestia/nexus/`): `WindowFactory.create()` and the docked `Nexus` popout open **end-4's settings app** (`qs -p settings.qml`); the popout closes itself. Upstream Caelestia files stay unmodified, so re-syncs stay easy.
- IPC audit: the caelestia family registers `audio caelestiaMpris drawers gameMode hypr idleInhibitor nexus notifs toaster wallpaper`. None clash with end-4.

## 3.3 Family composition (`panelFamilies/CaelestiaFamily.qml`)
| From | Parts |
|---|---|
| Caelestia design | `GSFLoader`, `ServiceLoader`, `Background`, `Drawers` (frame, bar, popouts, dashboard, launcher, notifications, OSD, session, sidebar, utilities, toasts), `Shortcuts` (appid `caelestia`), `BatteryMonitor` |
| end-4 as-is (re-skin in Phase 7) | `Overview` (Super search, Super+Tab, Super+V clipboard, Super+. emoji), `Cheatsheet`, `SidebarLeft` (AI, translator), `RegionSelector`, `ScreenTranslator`, `OnScreenKeyboard`, `Overlay`, `WallpaperSelector`, **`Lock`**, **`Polkit`** |
| Not loaded (Caelestia has its own) | ii `Bar`/`VerticalBar`, `OnScreenDisplay`, `SessionScreen`, `SidebarRight`, `NotificationPopup`, `MediaControls`, `Background`, `Dock`, `ScreenCorners` |

**`KeybindBridge`** registers end-4's shortcut names whose ii modules aren't loaded, so the same Hyprland keys work:
- `sessionToggle/Open/Close` (Ctrl+Alt+Del) → Caelestia session menu
- `sidebarRightToggle/Open/Close` (Super+N) → Caelestia sidebar
- `mediaControlsToggle/Open/Close` (Super+M) → Caelestia dashboard

Caelestia's own shortcuts (`caelestia:launcher`, `:dashboard`, `:utilities`, `:showall`, …) exist but have **no Hyprland bind yet**. The Caelestia launcher vs end-4 search question is part of Phase 5 (PLAN §3.4).

## 3.4 Verification
- Static: `tools/lint-caelestia.sh` OK; 203/203 files parse (`qmlformat --ignore-settings`).
- Runtime (e4test): pending.

## 3.5 Test 1 in e4test (2026-10-03): the caelestia family never loaded
- Log: `Type CaelestiaFamily unavailable` ← … ← `bar/popouts/Wrapper.qml[147]: Cannot assign to non-existent property "currentPageIdx"`.
- **Cause:** the `Nexus` stand-in declared `property QtObject nState`. The wrapper uses grouped assignments (`nState.currentPageIdx: …`), which QML checks against the **declared** type. One bad leaf type makes the whole chain (`Wrapper` → `ClipWrapper` → `Panels` → `ContentWindow` → `Drawers` → family) unavailable.
- **Effect on the test:** the deploy triggered a live reload, which failed, so Quickshell kept the previous (Phase 2, blank) config. Every check the user ran actually exercised **waffle** (end-4's Windows-style family): Super+N = action center, Super+M = media pane, etc. **No Phase 3 code ran.**
- **Fixes:**
  - `nexus/Nexus.qml`: `nState` is now a declared inline component type (`NexusState`).
  - Family cycle reordered `["ii", "caelestia", "waffle"]`: one Ctrl+Super+P press reaches caelestia.
  - New **`tools/compile-check.sh`**: compiles a family's whole type tree without instantiating it. Fake HOME, private D-Bus, private **headless sway** (Quickshell `PanelWindow` needs layer-shell, so `offscreen` fails with "No PanelWindow backend loaded"). Needs `sway` installed. From now on, staging requires compile-check OK for both CaelestiaFamily and IllogicalImpulseFamily.
- Lesson: syntax checks (`qmlformat`) can't catch type errors. A compile check must pass before anything is staged.
- 2026-10-03: `sway` installed. compile-check: **CaelestiaFamily OK, IllogicalImpulseFamily OK**. Negative test: restoring the old `Nexus.qml` reproduces the exact e4test error chain (`Wrapper.qml[147] … currentPageIdx`). `stage-for-test.sh` now refuses to stage unless compile-check passes.
