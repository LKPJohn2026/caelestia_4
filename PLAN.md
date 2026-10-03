# caelestia_4 — Plan

**Goal:** end-4's features and KDE integration (illogical-impulse) with Caelestia's design: the screen frame, drawers that slide out of the edges, the dashboard, the launcher, and the background.

**Approach:** add a third **panel family**, `caelestia`, to end-4's Quickshell config (`ii`), next to the existing `ii` and `waffle` families. Port Caelestia's UI into that family and rewire it to end-4's services.

**Status:** planning · **Written:** 2026-10-03 · **Machine:** CachyOS, Plasma 6.7.5 (Oxygen) as the main session, RTX 5090 + AMD iGPU, 57" 7680×2160 @ 1.5× / 240 Hz

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
| When the custom UI breaks | Super+Alt+W back to stock `ii` | Log out to another session |
| Compatibility layer | Adapters: Caelestia-shaped facades over end-4 services | The mirror image: a shim for end-4's `Config`, `Persistent`, `Directories`, `functions` and script paths |

**Decision:** end-4 is the base. The features and KDE integration are the functional core and the part upstream changes most, so they should keep updating through merges. The visual layer is where this project customizes anyway, so that is the part maintained by hand. Revisit only if an exact Caelestia look becomes more important than keeping up with end-4.

### 1.2 The extension point

end-4 was designed for this:

- `shell.qml` loads services once, then loads one **panel family** through `PanelFamilyLoader`, chosen by `Config.options.panelFamily`.
- `families: ["ii", "waffle"]` plus the `panelFamilyCycle` global shortcut (Super+Alt+W) switch families live, without restarting.
- `waffle` (a Windows 11 look, 142 QML files) shows a full alternate UI can sit on the same 46 services.

## 2. Source facts (checked 2026-10-03)

| | end-4 / dots-hyprland | caelestia-dots / shell |
|---|---|---|
| Version used for the plan | `main` @ `547836f1b0` (2026-09-28) | `v2.5.0` (2026-09-18), `main` @ `454f46da16` |
| License | GPL-3.0 | GPL-3.0 |
| Quickshell | Own pinned build `illogical-impulse-quickshell-git` @ `7511545e`. Conflicts with `quickshell` and `quickshell-git` | Needs `quickshell-git`. "Has to be the git version" |
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

| end-4 feature | Placement in the `caelestia` family |
|---|---|
| AI chat (`Ai`), Translator (`Translation`), Booru (optional) | **New "Assistant" drawer** from the left edge, coming out of the bar and frame like the other drawers. Restyled end-4 left sidebar |
| Quick toggles: night light (`Hyprsunset`), EasyEffects, keep awake (`Idle`), game mode, Bluetooth, Wi-Fi | Caelestia **sidebar / utilities** cards |
| Todo (`Todo`), Timer/Pomodoro (`TimerService`) | New **dashboard tabs** next to Media / Performance / Weather |
| Launcher search: apps, calculator, emoji (`Emojis`), clipboard (`Cliphist`), web/actions (`LauncherSearch`) | Caelestia **launcher** UI, end-4 search backend |
| Wallpaper selector + Material You theming | Caelestia launcher **wallpaper list** → end-4 `Wallpapers` + `MaterialThemeLoader` |
| Overview (workspaces + window previews) | end-4 `overview` with a Caelestia skin (blob container, tokens) |
| Cheatsheet (`HyprlandKeybinds`) | end-4 module, Caelestia skin |
| Region selector / OCR / Lens, screen translator, on-screen keyboard | end-4 modules, Caelestia skin (lower priority) |
| Polkit dialog (`PolkitService`) | end-4 module, Caelestia skin |
| Song recognition (`SongRec`), privacy indicators (`Privacy`), updates (`Updates`), keyring (`KeyringStorage`) | Bar status icons and popouts |
| Settings app | **end-4 `modules/settings`**, plus a "Caelestia family" page. Caelestia's `nexus` (65 files) is **not ported** |

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
- [ ] `shell.qml`: `families: ["ii", "waffle", "caelestia"]` plus a `PanelFamilyLoader { identifier: "caelestia" }`.
- [ ] `panelFamilies/CaelestiaFamily.qml` (empty `Scope` + `PanelLoader`s).
- [ ] `Config.qml`: `caelestia` section. `panelFamily` comment lists the new value.
- [ ] `modules/caelestia/adapters/`: all adapters from §3.3, each with a short contract comment (properties and functions the UI uses).
- [ ] Copy `modules/caelestia/components/` and run the import rewrite.
- **Done when:** Super+Alt+W cycles ii → waffle → caelestia (blank) → ii without errors in `qs log`.

### Phase 3: Frame + bar, the signature look (3–4 sessions) ⭐ first usable milestone
- [ ] Port `modules/drawers/*` (Drawers, Panels, Exclusions, Regions, Interactions, ContentWindow).
- [ ] Port `modules/bar/**` (32 files): workspaces, active window, tray (end-4 `TrayService`), clock, status icons, popouts.
- [ ] Add status icons: privacy, updates, song recognition, keyboard layout.
- [ ] Hyprland: reserve space for the frame and bar, gaps that match the frame thickness, rules for layer blur on the Caelestia layer namespace.
- **Done when:** a full day of normal use in the `caelestia` family with no crashes; the frame and bar match the Phase 0 reference at 1.5× scale.

### Phase 4: Notifications, OSD, session (2 sessions)
- [ ] Notifications (popups + sidebar history) on end-4 `Notifications`. **No second daemon.**
- [ ] OSD (volume, brightness, keyboard layout) on end-4 services.
- [ ] Session menu (lock / logout / suspend / reboot / shutdown) using end-4's session actions.
- **Done when:** a `notify-send` storm, volume and brightness keys, and every session action work. Toggling back to `ii` still shows the same notification history.

### Phase 5: Launcher + wallpapers + theming (2–3 sessions)
- [ ] Caelestia launcher UI over `LauncherSearch` / `LauncherApps` / `AppSearch`: apps, calculator, emoji, clipboard, actions.
- [ ] Wallpaper list over end-4 `Wallpapers`. Selecting one runs end-4's color generation. The `Colours` adapter updates the frame and every drawer live.
- [ ] Make sure the KDE color hook stays disabled (see §4.4).
- **Done when:** changing the wallpaper recolors both families, and Plasma's `kdeglobals` is untouched (checked by checksum).

### Phase 6: Dashboard (2–3 sessions)
- [ ] Port dashboard tabs: Dash, Media (`MprisController`; lyrics from the plugin if they work), Performance (`ResourceUsage` with plugin sparklines), Weather.
- [ ] New tabs in Caelestia style: **Todo** (`Todo`), **Timer** (`TimerService`).
- **Done when:** every tab shows live data and the new tabs keep their state across switching families.

### Phase 7: end-4 exclusives in Caelestia style (3–5 sessions)
- [ ] **Assistant drawer** (left edge): AI chat (`Ai`, with end-4's provider config and keyring), Translator. Booru is optional and off by default.
- [ ] Sidebar/utilities quick toggles: night light, EasyEffects, keep awake, game mode, Bluetooth, Wi-Fi.
- [ ] Overview, cheatsheet, polkit dialog: end-4 modules with a Caelestia skin (tokens, blob containers, fonts).
- [ ] Lower priority: region selector/OCR, screen translator, on-screen keyboard, media controls.
- **Done when:** every end-4 feature you use daily is reachable in the `caelestia` family without switching back to `ii`.

### Phase 8: Background + lock (2 sessions)
- [ ] Background: wallpaper, desktop clock, audio visualiser (plugin `VisualiserBars` + cava).
- [ ] Lock: Caelestia lock UI with end-4's PAM flow and keyring unlock (`KeyringStorage`), so the keyring still unlocks at login.
- **Done when:** lock/unlock works with the keyring opened, and idle → lock works through `Idle`.

### Phase 9: Polish + performance (1–2 sessions)
- [ ] Measure idle RAM/CPU against upstream `ii` (Caelestia's reference is ~1.5 GB idle). Lazy-load drawers.
- [ ] Turn off visualiser and blur during fullscreen games (`GameMode` adapter).
- [ ] Settings page for the family in end-4's settings app.
- [ ] Docs: `docs/INSTALL.md`, `docs/UPDATING.md`, `docs/KEYBINDS.md`, screenshots.

### Phase 10: Keeping up with upstream (ongoing)
- [ ] `tools/sync-upstreams.sh`:
  1. Snapshot.
  2. Merge `upstream/main` (end-4).
  3. Bump the Caelestia subtree to a new tag.
  4. Re-run the import rewrite.
  5. Rebuild the plugin.
  6. Run smoke tests (qmllint + a launch check).
- [ ] Keep changes to end-4's own files small. Today only `shell.qml`, `Config.qml` and the installer edits from §4.4 change; everything else lives in new files. That keeps upstream merges easy.
- [ ] `modules/caelestia/README.md` records the upstream Caelestia commit each ported file came from.

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

## 7. Open questions

1. **KDE app colors under Hyprland.** With `QT_QPA_PLATFORMTHEME=kde`, Dolphin and other KDE apps read the shared `kdeglobals`, so in Hyprland they show **Oxygen** colors. Options:
   - (a) accept that, simplest;
   - (b) a login/logout script that swaps `kdeglobals` per session, which is risky if a session crashes;
   - (c) use the separate `DankMatugen`-style color-scheme file and switch only the scheme name per session.
   Decide in Phase 5.
2. Bar position: Caelestia's frame bar is left and vertical. Keep it, or allow a top bar on the 32:9 screen?
3. Lyrics and the visualiser come from the Caelestia plugin's services. Keep them as the only plugin *services* in use, or drop them to cut dependencies?
4. Distribution: keep private, or publish under GPL-3.0 later (needs `LICENSE`, `NOTICE` with both upstreams credited, and the screenshots policy)?

## 8. Licensing

Both upstreams are GPL-3.0. A private repo is fine. Any release must stay GPL-3.0, keep both copyright notices, and credit **end-4/dots-hyprland** and **caelestia-dots/shell** (`NOTICE` + per-module README).

## 9. References
- end-4/dots-hyprland: `shell.qml`, `panelFamilies/`, `modules/{ii,waffle,common}`, `services/`, `sdata/dist-arch/*/PKGBUILD`, `sdata/subcmd-install/` — https://github.com/end-4/dots-hyprland
- caelestia-dots/shell: `shell.qml`, `modules/drawers/`, `plugin/src/Caelestia/`, README dependency list — https://github.com/caelestia-dots/shell
- caelestia-dots/caelestia (dots + `manifest.toml`) — https://github.com/caelestia-dots/caelestia
- Quickshell — https://quickshell.outfoxxed.me
- Plasma backup — `oxygen-plasma` (private)
