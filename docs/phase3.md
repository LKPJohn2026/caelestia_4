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
