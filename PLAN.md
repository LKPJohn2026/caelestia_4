# caelestia_4 — Plan

**Goal:** end-4's features and KDE integration (illogical-impulse) with Caelestia's design: the screen frame, drawers that slide out of the edges, the dashboard, the launcher, and the background.

**Approach:** add a third **panel family**, `caelestia`, to end-4's Quickshell config (`ii`), next to the existing `ii` and `waffle` families. Port Caelestia's UI into that family and rewire it to end-4's services.

**Status:** in daily use on the main account since 2026-10-03, as a Hyprland session next to Plasma. Phases 0–7 are done; 8–10 are partly done (see §5 and §11). · **Written:** 2026-10-03 · **Reviewed:** 2026-10-09 · **Machine:** CachyOS, Plasma 6.7.5 (Oxygen) as the main session, RTX 5090 + AMD iGPU, Samsung Odyssey Neo G9 57" (G95NC) 7680×2160 @ 1.5× / 240 Hz over DP 2.1

### Current state (2026-10-09)
| | |
|---|---|
| Hyprland | 0.56.2 (Lua config), standard `Hyprland` session (not uwsm, see §10) |
| Quickshell | own package `caelestia4-quickshell` **0.3.2** (`4f508be`), built against Qt **6.12**. Was `41651d7`; moved because 41651d7 doesn't compile on Qt 6.12 |
| Caelestia | `third_party/caelestia-shell` v2.5.0; C++ plugin built into `~/.local/lib/qt6/qml` (rebuilt for Qt 6.12) |
| end-4 | merged at `547836f1b0` (2026-09-28), not re-synced since |
| Family | `caelestia` is the default `panelFamily`; 216 QML files in `modules/caelestia/`; `ii`/`waffle` are still one Ctrl+Super+P away |
| Lock | hyprlock with a Caelestia-style theme (§5 Phase 8) |
| Idle cost | `qs` ~1.0 GB RSS (Caelestia's reference: ~1.5 GB), CPU near idle |

---

## 1. Why this approach

Option 3 of three. The other two were rejected.

| Option | Result | Verdict |
|---|---|---|
| 1. Configure end-4 to look like Caelestia | ~30–40% of the look. No frame, no edge drawers | Rejected: misses the part that matters |
| 2. Run both shells side by side | Two notification daemons, two polkit agents, two lock screens, two Quickshell builds | Rejected: too fragile for daily use |
| **3. A `caelestia` panel family in end-4** | All end-4 services + KDE integration; Caelestia UI on top; one shortcut switches families | **Chosen** |

### 1.1 Why end-4 is the base and not Caelestia

The opposite direction would be Caelestia as the base, with end-4's ~25–30 extra services ported in. That is less work up front, because ~130 UI files don't need porting. It is more expensive later:

| | **end-4 as base (chosen)** | Caelestia as base |
|---|---|---|
| Work up front | Higher: port ~130 Caelestia UI files + adapters | Lower: port ~25–30 end-4 services + scripts + Python venv |
| How faithful the look is | Close; checked against Phase 0 reference captures | Exact out of the box |
| Upstream updates | end-4: `git merge`. Caelestia: scripted re-sync of the UI port | Caelestia: merge, with conflicts in the C++ plugin. end-4: **every feature ported by hand, forever** |
| Settings for new features | New `caelestia` section in end-4's QML `Config.qml` | New C++ config sections in `Caelestia.Config` → **a modified plugin**, rebuilt and conflicting on every update |
| KDE integration | Comes with end-4 (packages, env, portal) | Rebuilt from scratch. Caelestia uses Thunar, its own Qt theme engine, foot |
| Stability | Pinned Quickshell, unmodified plugin | `quickshell-git` + other `-git` deps; plugin modified |
| When the custom UI breaks | Ctrl+Super+P back to stock `ii` | Log out to another session |
| Compatibility layer | Adapters: Caelestia-shaped facades over end-4 services | The mirror image: a shim for end-4's `Config`, `Persistent`, `Directories`, `functions` and script paths |

**Decision:** end-4 is the base. The features and KDE integration are the functional core and the part upstream changes most, so they should keep updating through merges. The visual layer is where this project customizes anyway, so that is the part maintained by hand. Revisit only if an exact Caelestia look becomes more important than keeping up with end-4.

### 1.2 The extension point

end-4 was designed for this:

- `shell.qml` loads services once, then loads one **panel family** through `PanelFamilyLoader`, chosen by `Config.options.panelFamily`.
- `families: ["ii", "waffle"]` plus the `panelFamilyCycle` global shortcut (Ctrl+Super+P) switch families live, without restarting.
- `waffle` (a Windows 11 look, 142 QML files) shows a full alternate UI can sit on the same 46 services.

## 2. Source facts (checked 2026-10-03)

| | end-4 / dots-hyprland | caelestia-dots / shell |
|---|---|---|
| Version used for the plan | `main` @ `547836f1b0` (2026-09-28) | `v2.5.0` (2026-09-18), `main` @ `454f46da16` |
| License | GPL-3.0 | GPL-3.0 |
| Quickshell | Own pinned build `illogical-impulse-quickshell-git` @ `7511545e`. Conflicts with `quickshell` and `quickshell-git` | Needs `quickshell-git`. "Has to be the git version" |
| → caelestia_4 uses | `caelestia4-quickshell`: first `41651d7d` (Phase 1), now **v0.3.2 `4f508be`** (2026-10-08, Qt 6.12 fix `5d5d498`) | same package |
| UI size | `modules/ii`: 199 QML · `modules/waffle`: 142 QML | 284 QML total. UI without the `nexus` settings app: ~130 |
| Services | 46 QML singletons in `services/` | 17 QML singletons in `services/`, plus a large C++ plugin |
| Config | `modules/common/Config.qml` (JsonObject tree) | C++ `Caelestia.Config`, read from `~/.config/caelestia/shell.json` |
| Extra build deps | — | `cmake`, `ninja`, `qt6-shadertools`, `qt6-m3shapes-git`, `libcava`, `aubio`, `libqalculate`, `lm_sensors`, `ddcutil` |

### The Caelestia C++ plugin (`plugin/src/Caelestia`)
Caelestia's UI depends on this plugin, so it can't be dropped:

- **Blobs**: shader-based shapes (blob rects, inverted rects). They draw the frame and drawer shapes.
- **Components**: `AnimatedRepeater`, `ButtonRow`, circular/linear indicators, `SparklineItem`, `VisualiserBars`, `WavyLine`, `LazyListView`.
- **Config / Settings / Tokens**: typed settings tree plus design tokens. `Caelestia.Config` is imported by almost every module.
- **Services**: cpu, gpu, memory, storage, network usage, cava, beat tracker, lyrics, Hyprland extras and devices, session manager.
- **Images / Models / I18n**: image analyser and caching, app database, translations, `qalculator`, toaster.

**Decision:** keep the plugin as a compiled dependency, built from a pinned Caelestia tag. Don't rewrite it. It provides visuals, tokens and a few metrics. Behavior and user data still come from end-4's services.

## 3. Architecture

```
end-4 services (46)  ──►  adapters/ (Caelestia-shaped facades)  ──►  modules/caelestia/** (ported Caelestia UI)
        │                                                                     │
        │                                       Caelestia C++ plugin (Blobs, Components, Tokens, metrics)
        ▼
end-4 Config.qml (+ new `caelestia` section)        Caelestia.Config (visual tokens only, shell.json)
```

### 3.1 Layout inside `dots/.config/quickshell/ii/`
```
panelFamilies/CaelestiaFamily.qml        # new family entry point
modules/caelestia/
  adapters/                              # Notifs, Players, Hypr, Colours, Nmcli, ShellState, Time, …
  components/                            # vendored from caelestia `components/` (import path rewritten)
  drawers/  bar/  dashboard/  launcher/  notifications/  osd/  session/
  sidebar/  utilities/  background/  lock/  assistant/  (new) overview-skin/ (new)
  README.md                              # attribution + upstream commit per file
```

### 3.2 Import namespacing (the main porting rule)
Both projects use `qs.services`, `qs.components` and `qs.modules.*`, and both have services with the same names (`Audio`, `Brightness`, `Wallpapers`, `Weather`). Inside end-4's tree, `qs.services` means **end-4's** services.

- Rewrite `import qs.components` → `import qs.modules.caelestia.components`
- Rewrite `import qs.services` → `import qs.modules.caelestia.adapters`
- Rewrite `import qs.modules.<x>` → `import qs.modules.caelestia.<x>`
- Leave `import Caelestia…` (plugin) imports alone.

This is done by a script (`tools/port-imports.sh`), so every re-sync from upstream Caelestia is repeatable.

### 3.3 Adapter map: Caelestia service → end-4 source

Each adapter is a QML `Singleton` that exposes the **property and function names the Caelestia UI expects**, backed by end-4. That way ported QML keeps working after only its import lines change.

| Caelestia service | end-4 backing | Notes |
|---|---|---|
| `Audio` | `Audio` | sink/source volume, mute, device lists |
| `Brightness` | `Brightness` | ddcutil handled by end-4 |
| `Colours` | `MaterialThemeLoader` + `Appearance.m3colors` | **one color pipeline** (end-4 matugen); Caelestia's palette roles map onto M3 roles |
| `GameMode` | new small adapter over `HyprlandConfig` | toggles animations/blur off |
| `Hypr` | `HyprlandData` (+ plugin `hyprextras`) | workspaces, clients, active window, keyboard layout via `HyprlandXkb` |
| `IdleInhibitor` | `Idle` | |
| `Nmcli` | `Network` | Wi-Fi/ethernet state, connect actions |
| `NotifData`, `Notifs` | `Notifications` | **end-4 stays the only notification daemon** |
| `Players` | `MprisController` | |
| `Recorder` | end-4 `scripts/videos` | |
| `Screens` | `Quickshell.screens` + `GlobalStates` | |
| `ShellState` | `GlobalStates` | drawer open/close state lives here |
| `Time` | `DateTime` | |
| `VPN` | `Network` (+ small nmcli helper) | only if needed |
| `Wallpapers` | `Wallpapers` | wallpaper switching triggers end-4 theming |
| `Weather` | `Weather` | |
| plugin metrics (cpu/gpu/mem/disk/net) | `ResourceUsage` (or keep plugin) | prefer end-4 so one source feeds both families |

### 3.4 Where end-4's features go in the Caelestia design

| end-4 feature | Planned placement in the `caelestia` family | Status (2026-10-09) |
|---|---|---|
| AI chat (`Ai`), Translator (`Translation`), Booru (optional) | **New "Assistant" drawer** from the left edge, coming out of the bar and frame like the other drawers. Restyled end-4 left sidebar | ✅ drawer done; contents still end-4 styled. Booru gained a **Wallhaven** provider; AI sees **Ollama** models (LM Studio GGUFs, no copies) |
| Quick toggles: night light (`Hyprsunset`), EasyEffects, keep awake (`Idle`), game mode, Bluetooth, Wi-Fi | Caelestia **sidebar / utilities** cards | ✅ **all 16** end-4 toggles + edit mode; System card, quick sliders, eye-protection panel |
| Todo (`Todo`), Timer/Pomodoro (`TimerService`) | New **dashboard tabs** next to Media / Performance / Weather | ✅ |
| Launcher search: apps, calculator, emoji (`Emojis`), clipboard (`Cliphist`), web/actions (`LauncherSearch`) | Caelestia **launcher** UI, end-4 search backend | ✅ merged; `$` runs in kitty with visible output. ⚠ Caelestia actions Random/Settings/Scheme/Variant still call the missing `caelestia` CLI |
| Wallpaper selector + Material You theming | Caelestia launcher **wallpaper list** → end-4 `Wallpapers` + `MaterialThemeLoader` | ✅ list; end-4's selector window still end-4 styled |
| Overview (workspaces + window previews) | end-4 `overview` with a Caelestia skin (blob container, tokens) | ⚠ works (Super+Tab), not reskinned |
| Cheatsheet (`HyprlandKeybinds`) | end-4 module, Caelestia skin | ✅ Caelestia restyle |
| Region selector / OCR / Lens, screen translator, on-screen keyboard | end-4 modules, Caelestia skin (lower priority) | OSK ✅ restyled (needs `ydotoold`); region tools + translator ⚠ end-4 styled |
| Polkit dialog (`PolkitService`) | end-4 module, Caelestia skin | ⚠ end-4 styled |
| Song recognition (`SongRec`), privacy indicators (`Privacy`), updates (`Updates`), keyring (`KeyringStorage`) | Bar status icons and popouts | ✅ privacy + updates icons/popouts; song recognition as a quick toggle; keyring = KWallet via Secret Service |
| Settings app | **end-4 `modules/settings`**, plus a "Caelestia family" page. Caelestia's `nexus` (65 files) is **not ported** | ✅ Caelestia page + Caelestia-style frame; About credits Caelestia |
| Dock (not in the original plan) | — | ✅ new Caelestia-style dock with previews, pinning, `caelestia.dock.*` |

### 3.5 Config strategy
- **Behavior** (what's on, positions, timers): end-4 `Config.qml`, new section `caelestia: JsonObject { … }`. Existing keys are reused where they mean the same thing (`bar.vertical` doesn't apply; the frame bar is always vertical-left).
- **Visual tokens** (rounding, spacing, frame thickness, animation curves, fonts): `Caelestia.Config` / `shell.json`, so Caelestia's tokens and presets keep working unchanged.
- One documented file per side: `~/.config/illogical-impulse/config.json` and `~/.config/caelestia/shell.json`.

## 4. Safety rules (apply in every phase)

1. **Plasma (Oxygen) is never touched.** The backup is the `oxygen-plasma` repo. Check it with `git diff` after every install step.
2. **Nothing system-wide that a user-local version can replace.**
   - The Caelestia plugin installs to `~/.local/lib/qt6/qml`. The import path is added **only in the Hyprland session** (`QML_IMPORT_PATH` in Hyprland's `env.lua`).
   - Quickshell is the one exception. Only one package can be installed, so it is a pacman package.
3. **Snapshots:** CachyOS already has `snapper` + `snap-pac` + `limine-snapper-sync`, so every pacman transaction is snapshotted and bootable from Limine. Take a manual snapshot before each phase anyway: `sudo snapper create -d "caelestia_4 phase N"`.
4. **The end-4 installer runs with** `--skip-plasmaintg --skip-fish`, and **without** `--skip-backup`, so its backup prompt still appears. Before running it:
   - remove `dots/.config/kdeglobals` from the file list;
   - remove the `kwriteconfig6 … widgetStyle Darkly` call;
   - make the matugen `kde-material-you-colors-wrapper.sh` hook do nothing. It rewrites `kdeglobals`, which Plasma shares.
5. **Environment variables live only in Hyprland's Lua config.** Never in `/etc/environment`, `~/.profile` or `environment.d`.
6. **Separate login session:** an SDDM entry "Hyprland (caelestia_4)" starts Hyprland with its own config folder.
7. **First tests in a throwaway user account** (Phase 0), before anything runs in the main home folder.

**How these held up (2026-10-09):**
- Rule 1: Plasma's look and config are untouched by the installer. User-requested Plasma changes are made on purpose and recorded in the `oxygen-plasma` repo: fcitx5 as KWin's input method, Shake Cursor off, and the boot `display-watchdog` service.
- Rule 5 holds. The environment additions (fcitx5, `AQ_DRM_DEVICES`, `XDG_CURRENT_DESKTOP=Hyprland:KDE`) all live in `hypr/custom/env.lua`.
- Rule 6 changed in practice. The login manager is **plasmalogin** (not SDDM), and the session is the stock `Hyprland` entry, which shares the home folder with Plasma. Shared-desktop conflicts are handled by the `~/.config/caelestia4/shared-desktop` marker (gsettings, kdeglobals and kded6 left alone).
- Rule 7 done. The `e4test` account was used for Phases 0–7, then removed.

## 5. Phases

Effort is in working sessions (~2–4 h each), as a rough guide.

### Phase 0: Baseline (1–2 sessions)
- [x] Manual snapper snapshot.
- [x] Create throwaway user `e4test`. Install **upstream end-4** there with its official installer. Log in, check that it works: services, the KDE bits (Dolphin, polkit-kde, plasma-nm, bluedevil, `xdg-desktop-portal-kde`), and the `waffle` family switch.
- [x] Hardware check in that session:
  - which GPU drives the screen (`AQ_DRM_DEVICES` → the card with the monitor attached; confirm with `/dev/dri/by-path`);
  - 240 Hz + VRR, scale 1.5, `QT_SCALE_FACTOR` behavior.
- [x] Separately, install **upstream Caelestia** for `e4test` (swapping Quickshell packages) to record its look as a visual reference: screenshots and screen recordings of every drawer at 7680×2160.
- **Done when:** both upstreams were seen working on this hardware, the references are saved in `docs/reference/`, and Plasma is unchanged (`git diff` is clean in `oxygen-plasma`).

### Phase 1: Repo and toolchain (1–2 sessions)
- [x] Bring end-4 into this repo as **upstream**: `git remote add upstream https://github.com/end-4/dots-hyprland`, merge `main` at a pinned commit. A private GitHub repo can't be a fork of a public one, hence the remote.
- [x] Vendor Caelestia **shell source at tag `v2.5.0`** under `third_party/caelestia-shell/` with `git subtree`. Used for the plugin build and as the UI port source.
- [x] **Choose one Quickshell commit** → `41651d7d` (see docs/phase1.md) that runs both end-4 `ii` and the Caelestia UI:
  - try end-4's pin `7511545e` with the Caelestia plugin;
  - if the Caelestia QML needs newer APIs, move to the oldest `quickshell-git` commit that Caelestia v2.5.0 accepts, then re-test `ii`;
  - package it as `caelestia4-quickshell` (`provides/conflicts` like end-4's PKGBUILD).
- [x] Build the Caelestia plugin into `~/.local` (CMake `-DCMAKE_INSTALL_PREFIX=$HOME/.local`). Needs `qt6-m3shapes-git` from the AUR.
- [x] `tools/port-imports.sh` (import rewrite, §3.2) and `tools/sync-upstreams.sh`.
- **Done when:** `qs -c ii` runs the `ii` family on the chosen Quickshell, and a test QML that imports `Caelestia.Config` and `Caelestia.Blobs` loads in that session.

### Phase 2: Family skeleton + adapters (2 sessions)
- [x] `shell.qml`: `families: ["ii", "waffle", "caelestia"]` plus a `PanelFamilyLoader { identifier: "caelestia" }`.
- [x] `panelFamilies/CaelestiaFamily.qml` (empty `Scope` + `PanelLoader`s).
- [x] `Config.qml`: `caelestia` section. `panelFamily` comment lists the new value.
- [x] `modules/caelestia/adapters/`: all adapters from §3.3, each with a short contract comment (properties and functions the UI uses).
- [x] Copy `modules/caelestia/components/` and run the import rewrite.
- **Done when:** Ctrl+Super+P cycles ii → waffle → caelestia (blank) → ii without errors in `qs log`.

### Phase 3: Frame + bar, the signature look (3–4 sessions) ⭐ first usable milestone (done 2026-10-03, docs/phase3.md; Phases 4 and 6 were folded in)
- [x] Port `modules/drawers/*` (Drawers, Panels, Exclusions, Regions, Interactions, ContentWindow).
- [x] Port `modules/bar/**` (32 files): workspaces, active window, tray (end-4 `TrayService`), clock, status icons, popouts. Network popout shows Wi-Fi + ethernet ("both" view).
- [x] Add status icons: privacy ✅ + updates ✅ (2026-10-08), keyboard layout (Caelestia `kbLayout`, off by default), speaker on (`shell.json`). Song recognition lives in the quick toggles instead.
- [x] Hyprland: reserve space for the frame and bar (Caelestia `Exclusions`), Super+J hides/shows the bar (`ScreenState.barHidden`).
- **Done when:** ✅ daily use since 2026-10-03.

### Phase 4: Notifications, OSD, session (folded into Phase 3)
- [x] Notifications (popups + sidebar history) on end-4 `Notifications`. **No second daemon.**
- [x] OSD (volume, brightness, keyboard layout) on end-4 services.
- [x] Session menu (lock / logout / suspend / reboot / shutdown) using end-4's session actions.

### Phase 5: Launcher + wallpapers + theming (done 2026-10-03, docs/phase5.md)
- [x] Caelestia launcher UI over `LauncherSearch` / `LauncherApps` / `AppSearch`: apps, calculator, emoji, clipboard, actions (merged "option C").
- [x] Wallpaper list over end-4 `Wallpapers`; the `Colours` adapter recolors everything live.
- [x] KDE colour hook disabled on the shared account (`switchwall.sh` checks the `shared-desktop` marker).
- [ ] Follow-up: Caelestia launcher actions **Random / Settings / Scheme / Variant** call the missing `caelestia` CLI. Repoint them to end-4 (`switchwall.sh`, settings app) or hide them.

### Phase 6: Dashboard (folded into Phases 3 + 7)
- [x] Dash, Media (with plugin lyrics), Performance, Weather.
- [x] **Todo** and **Timer** tabs (end-4 widgets, `keepLoaded` fix for the collapsing panes).

### Phase 7: end-4 exclusives in Caelestia style (done for daily use; docs/phase7.md, docs/end4-parity.md)
- [x] **Assistant drawer** (left edge): AI chat, Translator, Anime (Booru + Wallhaven with keyring API key).
- [x] Utilities drawer: all 16 end-4 quick toggles (edit mode, tooltips, right-click actions), System card (uptime / reload / end-4 settings / session), quick sliders, Eye-protection panel (night light schedule, warmth, gamma, anti-flashbang).
- [x] Audio popout: per-app mixer (icons resolved via the owning window), mic slider.
- [x] **Dock** (new): Caelestia style, pinned + running apps, live previews, pin/reveal options.
- [x] Cheatsheet and on-screen keyboard restyled; settings app framed in Caelestia style.
- [x] Background mute for games (`BackgroundMute.qml`) + background rendering for Steam/gamescope windows.
- [ ] Still end-4 styled: workspace overview, polkit dialog, region selector / OCR / Lens / recorder, screen translator, overlay widgets (Super+G), wallpaper selector window, Assistant **contents**, Todo/Timer widgets.
- [ ] Not handled: holding Super for workspace numbers (end-4 bar feature), Assistant "detach".

### Phase 8: Background + lock (partly done)
- [x] Background: wallpaper. The desktop clock and visualiser are ported but **off by default** (Caelestia config `background.desktopClock` / `visualiser`).
- [x] Lock, **changed approach** (2026-10-08): **hyprlock** (`lock.useHyprlock = true`) with a **Caelestia-style hyprlock theme**, instead of a Caelestia QML lock. Reason: the G95NC drops off DP 2.1 for ~30 s on wake, and the in-shell `WlSessionLock` sometimes failed to put a surface back, which gave Hyprland's "lockscreen crashed" screen. hyprlock survived the same test. The keyring is KWallet, unlocked at login by `pam_kwallet5` + `pam_kwallet_init`, so the lock doesn't need to unlock it.
- **Done when:** ✅ idle → lock → unlock works (tested with a monitor drop).

### Phase 9: Polish + performance (partly done)
- [x] Settings page for the family in end-4's settings app (Caelestia page; also VRR and background FPS).
- [ ] Measure idle RAM/CPU against upstream `ii`. First reading: `qs` ~1.0 GB RSS in the caelestia family (2026-10-09); no `ii` comparison yet. Lazy-load drawers if needed.
- [ ] Turn off visualiser and blur during fullscreen games (moot while the visualiser is off; game mode toggle exists).
- [ ] Docs: `docs/install.md` exists (main-account install + every later fix); `docs/UPDATING.md`, `docs/KEYBINDS.md` and screenshots are still to do.

### Phase 10: Keeping up with upstream (ongoing)
- [x] `tools/sync-upstreams.sh` exists (end-4 merge / Caelestia tag bump; snapshot first). **Never run for real yet.**
- [x] Qt minor updates: rebuild `caelestia4-quickshell` (`makepkg -Cf`, clean) + `tools/build-caelestia-plugin.sh`. Done once for Qt 6.12 (docs/install.md).
- [ ] First real end-4 re-sync (base is `547836f1b0`, 2026-09-28).
- [ ] Keep changes to end-4's own files small. Grown beyond the original three; current edits are marked `caelestia4:` in: `shell.qml`, `Config.qml`, `settings.qml`, `modules/settings/{About,CaelestiaConfig}.qml`, `modules/common/widgets/{ContentSection,OptionalMaterialSymbol}.qml`, `services/{Booru,ConflictKiller}.qml`, `modules/ii/sidebarLeft/Anime.qml`, `hypr/hyprland.lua` (+ `hyprland/session.lua`), `execs.lua`, `switchwall.sh`, `hyprlock.conf`, matugen hyprlock template, and `sdata/dist-arch/illogical-impulse-kde/PKGBUILD` (gnome-keyring dropped).
- [ ] `modules/caelestia/README.md` recording the upstream Caelestia commit for each ported file (not written yet).

## 6. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| No single Quickshell commit runs both | Medium | High | Phase 1 tests this before any porting. Fallback: port the Caelestia QML that needs newer APIs, or move end-4 forward |
| Caelestia plugin ABI breaks with Quickshell/Qt updates | Medium | Medium | Pin plugin tag + Quickshell commit together. Rebuild in the sync script. Snapshot first |
| end-4 hook rewrites `kdeglobals` and changes Plasma | High if not handled | High | §4.4 edits, checksum check in Phase 5, `oxygen-plasma` repo as restore |
| Two notification / polkit / lock owners | Low (by design) | High | Only end-4's services run. Caelestia's service singletons are never loaded |
| Upstream end-4 refactors panel families | Low–Medium | Medium | Changes kept small; regular syncs; pin commits |
| Performance at 7680×2160 with blur + visualiser | Low (RTX 5090) | Low | Phase 9 measurements, game mode |
| Scope creep (porting everything) | High | Medium | Phases 3–6 are the core; 7–8 are prioritized; `nexus` is out of scope |
| **Qt minor updates break Quickshell / the plugin** (happened: Qt 6.12, 2026-10-08) | Every Qt release | High (shell crashes) | pacman hook warns; clean rebuild of both; the pin moved to v0.3.2 when 41651d7 stopped compiling (docs/install.md) |
| **Monitor drops off DP 2.1 on boot / wake** (G95NC + NVIDIA, upstream bug, unfixed) | Frequent | High: black screen, crashed lock | `display-watchdog` boot service (oxygen-plasma repo); hyprlock instead of the in-shell lock; DP 1.4 would avoid it at 120 Hz |
| Shell restarts while locked kill an in-shell lock | Was possible | High | hyprlock runs as its own process; check `pidof hyprlock` before restarting `qs` |
| Hot reloads leave Quickshell without theme icons | After many reloads | Low | Clean restart via Hyprland (`pkill -x qs; hyprctl dispatch 'hl.dsp.exec_cmd("qs -c ii")'`) |

## 7. Open questions

1. **KDE app colors under Hyprland.** ✅ Decided: **(a) accept**. KDE/Qt apps show Plasma's Oxygen colours in Hyprland (`QT_QPA_PLATFORMTHEME=kde`, shared `kdeglobals`, which the `shared-desktop` marker protects). Options (b) per-session `kdeglobals` swap and (c) a separate scheme file are still possible later.
2. **Bar position.** ✅ Kept: Caelestia's vertical left bar. Super+J hides it per screen; no top-bar variant.
3. **Lyrics and visualiser** from the plugin. ✅ Kept: lyrics are used in the dashboard Media tab; the visualiser is ported but off by default.
4. **Distribution:** still open. Private repo for now; a release needs `LICENSE`/`NOTICE` crediting both upstreams (the settings About page already credits both).

## 8. Licensing

Both upstreams are GPL-3.0. A private repo is fine. Any release must stay GPL-3.0, keep both copyright notices, and credit **end-4/dots-hyprland** and **caelestia-dots/shell** (`NOTICE` + per-module README).

## 9. References
- end-4/dots-hyprland: `shell.qml`, `panelFamilies/`, `modules/{ii,waffle,common}`, `services/`, `sdata/dist-arch/*/PKGBUILD`, `sdata/subcmd-install/` — https://github.com/end-4/dots-hyprland
- caelestia-dots/shell: `shell.qml`, `modules/drawers/`, `plugin/src/Caelestia/`, README dependency list — https://github.com/caelestia-dots/shell
- caelestia-dots/caelestia (dots + `manifest.toml`) — https://github.com/caelestia-dots/caelestia
- Quickshell — https://quickshell.outfoxxed.me
- Plasma backup — `oxygen-plasma` (private)

## 10. System integration beyond the plan (main account, details in docs/install.md)

| Area | What is in place |
|---|---|
| Session | Stock `Hyprland` entry under plasmalogin, next to Plasma. **uwsm rejected** (not installed; would move env handling and break the KWallet fix). |
| GPU / display | `AQ_DRM_DEVICES=/dev/dri/nvidia-dgpu` (udev symlink to the RTX 5090); VRR fullscreen-only; vertical workspace animation; games keep rendering in the background (`render_unfocused`, 60 fps). |
| Keyring / logins | gnome-keyring removed; KWallet owns Secret Service; `pam_kwallet_init` in Hyprland; `XDG_CURRENT_DESKTOP=Hyprland:KDE` so Chromium/Electron use the same KWallet key as Plasma; Brave data re-keyed (`tools/brave-rekey.py`). Logins survive session switches. |
| Input | fcitx5 + Bamboo in both sessions, Super+Space toggle; `ydotoold` (Hyprland only) for the on-screen keyboard. |
| Apps | KDE Connect daemon + tray + `hypr-kdeconnect-fix` remote input; session restore (`hyprland/session.lua`) reopens apps on their workspaces; default terminal kitty everywhere. |
| Games | Background mute (shell), background rendering (Hyprland), VRR. |
| Local AI | `ollama-cuda` as a user service; LM Studio's 7 GGUFs imported as hard links (`tools/ollama-import-lmstudio.sh`, 0 bytes extra); listed in the AI chat. |
| Lock | hyprlock + Caelestia-style theme (Google Sans Flex installed user-locally, full matugen palette). |
| Plasma side (oxygen-plasma repo) | Shake Cursor off; `display-watchdog` boot service for the DP 2.1 black screen. |

## 11. Next steps (prioritized, 2026-10-09)

1. **Launcher actions**: repoint Random → end-4's `scripts/colors/random/` scripts, Settings → end-4 settings app, Scheme/Variant → end-4 scheme options (or hide them). Small; currently they do nothing.
2. **Reskin the remaining end-4 surfaces**, most visible first: workspace overview → polkit dialog → region tools / screen translator → overlay widgets → wallpaper selector → Assistant contents and Todo/Timer widgets.
3. **Phase 9 measurement**: idle RAM/CPU in `caelestia` vs `ii` (the `caelestia` family is ~1.0 GB now); lazy-load drawers only if needed.
4. **Upstream**: first real `tools/sync-upstreams.sh end4 <ref>` run (base is 11+ days old), then write `modules/caelestia/README.md` (per-file upstream commits) and `docs/UPDATING.md` (sync + Qt-rebuild routine).
5. **Docs**: `docs/KEYBINDS.md` (the cheatsheet covers it in-app) and screenshots.
6. Optional: hold-Super workspace numbers, Assistant detach, avatar on the lock screen (`~/.face`), desktop clock / visualiser on.

