# Phase 7: end-4 exclusives in the Caelestia design (log)

## 7.1 Assistant drawer (2026-10-03)
end-4's left sidebar (AI chat, Translator, optional Anime) now lives **inside Caelestia's frame** as a new drawer
that slides out next to the bar, instead of end-4's own `SidebarLeft` window (no longer loaded in the caelestia family).
- New `modules/caelestia/assistant/Wrapper.qml`: same pattern as Caelestia's right `sidebar/Wrapper.qml` (offsetScale slide + fade), mirrored to the left. Hosts end-4's `SidebarLeftContent` unchanged (`scopeRoot` = wrapper). Width = end-4 `sidebarWidth` (460); **Ctrl+O** toggles `sidebarWidthExtended` (750). **Esc** closes. Focus goes to the active tab on open.
- Wiring, all marked `caelestia4:`:
  - `components/ScreenState.qml`: `property bool assistant`.
  - `drawers/Panels.qml`: `Assistant.Wrapper` anchored top/bottom/left (left = bar edge) + alias.
  - `drawers/ContentWindow.qml`:
    - `PanelBg { id: assistantBg }`: the blob surface, so it grows out of the frame like the other drawers.
    - Keyboard focus `OnDemand` while open.
    - Joins the focus grab (outside click closes it) and the fullscreen reset.
  - `drawers/Regions.qml`: input region while (partly) shown.
- Keys (`KeybindBridge`): end-4's `sidebarLeftToggle/Open/Close/ToggleDetach` (Super+A / Super+B / Super+O) → Assistant. Detach isn't supported in the drawer; it toggles instead.
- `GlobalStates.sidebarLeftOpen` ↔ focused screen's `assistant`, so end-4 code that closes "the sidebar" (e.g. after opening a link from AI chat) closes the drawer.
- Visuals: drawer surface = Caelestia blob/animation; inner widgets = end-4's (tab bar, chat bubbles), already on the same Material You palette. A full widget-level restyle is a later step.

## 7.2 Dashboard: Todo + Timer tabs
- `dashboard/Content.qml`: two tabs after Weather. **Todo** (`checklist`) = end-4 `TodoWidget`; **Timer** (`timer`) = end-4 `PomodoroWidget` (pomodoro + stopwatch, end-4 `TimerService`). Same data as end-4's right sidebar.
- `dashboard/E4Pane.qml`: fixed-size pane (≈520×420) because end-4's widgets fill their parent.
- Toggles: `Config.options.caelestia.dashboardTodo` / `dashboardTimer` (default true).
- `ContentWindow` keyboard focus is now `OnDemand` while the dashboard is open, so the Todo add dialog can take typing. OnDemand only takes focus on click.

## 7.3 Utilities: quick toggles
- `utilities/cards/Toggles.qml`: appended **Night light** (`E4.Hyprsunset.toggleTemperature()`, state `temperatureActive`) and **EasyEffects** (`E4.EasyEffects.toggle()`, shown only if available; availability is fetched when the card loads, because end-4 only does that from its own toggle widget).
- Already present via Caelestia + adapters: Wi-Fi, Bluetooth, mic, keep awake (IdleInhibitor → end-4 Idle), game mode, DND (Notifs → end-4 silent), settings (→ end-4 settings app).

## 7.4 Not done yet
- Caelestia-style skin for end-4's cheatsheet, polkit dialog, region selector, screen translator, OSK (they work as-is).
- Widget-level restyle inside the Assistant (tab bar → Caelestia tabs, chat bubbles → Caelestia cards).

## Verification
- `lint-caelestia.sh` OK; `compile-check.sh`: CaelestiaFamily OK, IllogicalImpulseFamily OK.
- **Runtime test 1 (e4test, 2026-10-03):** Assistant, toggles OK. Log clean (probe 18/18; no caelestia4 errors) except:
  - **Bug: Todo / Timer panes collapsed, text overlapping.** Log: `Loader @dashboard/Content.qml[151] Binding loop detected for property "active"`. **Cause:** Caelestia loads dashboard panes lazily (`active` depends on the pane's x/width within the flickable). An unloaded pane has width 0, so (un)loading the end-4 panes changed the row width, which re-evaluated `active` (loop). The pane was measured at 0 and end-4's ColumnLayout squeezed its rows on top of each other.
  - **Fix:** tab entries get `keepLoaded: true`; the delegate's `active` returns true for them, so they're never lazily unloaded. `E4Pane` now has a plain fixed 560×480 (no token lookups).
  - `.face` missing ×25: dashboard avatar; the test user has no `~/.face` (harmless).
