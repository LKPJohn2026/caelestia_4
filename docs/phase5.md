# Phase 5: Launcher merge (option C) (log)

**Decision (user, 2026-10-03): option C.** Caelestia's launcher design with end-4's search features inside it. Super opens it.

## Design
- **Caelestia launcher stays the UI** (`modules/caelestia/launcher/`). Its own modes are unchanged:
  - apps: Caelestia `Apps` with its usage-ranked app DB
  - `>` commands: calc, scheme, variant, wallpaper, …
  - `>wallpaper `: wallpaper grid
- **New `e4` state in `AppList.qml`** backed by end-4's `LauncherSearch` service (`E4.LauncherSearch.query` ← typed text via a `Binding` while in that state; `results` → list model). Entered when:
  - the text starts with an end-4 prefix: `;` clipboard, `:` emoji, `=` math, `$` shell command, `?` web search, `/` end-4 actions. end-4's `>` app prefix is skipped because it clashes with Caelestia's `>` and apps are Caelestia's job.
  - **or** nothing matches as an app. end-4's fallbacks (math result, run as command, web search, actions) then appear instead of "No results".
- **`launcher/items/E4ResultItem.qml`**: Caelestia-styled row for an end-4 `LauncherSearchResult`. Icon by `iconType` (System → themed icon, Material → symbol, Text → emoji), name (monospace for math), "type · comment" subtitle, verb on the right (Open / Copy / Run …). Click or Enter → `execute()` and close the launcher.
- `Content.qml`: Enter in the `e4` state calls the item's `activate()`. The placeholder lists the prefixes.

## Keys (caelestia family)
| Key | Before | Now |
|---|---|---|
| Super (tap) | end-4 overview + search | **Caelestia launcher** (`searchToggleRelease` + `Interrupt` semantics kept) |
| Super+V | end-4 clipboard in overview | launcher pre-filled `;` (same key again closes) |
| Super+. | end-4 emoji in overview | launcher pre-filled `:` |
| Super+Tab | end-4 overview | **`WorkspaceOverview.qml`**: end-4's `OverviewWidget` (workspace grid) without the search bar |

end-4's `Overview` module is **no longer loaded** in the caelestia family, because it registers all of the shortcuts above. `WorkspaceOverview` keeps its window namespace (`quickshell:overview`) and IPC target (`search`). Pre-fill finds the launcher field via `ShellState.componentsForActive().find("launcherSearch")` and retries for up to 1 s while the drawer opens.

## Not merged (yet)
- end-4's sub-actions per result (e.g. clipboard Copy/Delete buttons): only the main `execute()` is wired.
- Clipboard **images** show as text entries (no thumbnails).
- end-4's `showDefaultActionsWithoutPrefix` list appears only in the no-match fallback.

## Verification
- `lint-caelestia.sh` OK; `compile-check.sh`: CaelestiaFamily OK, IllogicalImpulseFamily OK.
- Runtime (e4test): pending.
