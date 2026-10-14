# Phase 1: Repo and toolchain (log)

## 1.1 One Quickshell for both shells: ✅ decided (2026-10-03)

**Pin: `quickshell-git` 0.3.1 r18, revision `41651d7dcd62a9400eb6f4f8a8580efe00901efb`.**

| Shell | On end-4's pin `7511545e` (0.2.1) | On `41651d7d` (0.3.1) |
|---|---|---|
| Caelestia v2.5.0 | ❌ fails at load: `Unrecognized pragma "DefaultEnv …"` | ✅ fully working (Phase 0.9) |
| end-4 `ii` @ `547836f1b0` | ✅ (upstream default) | ✅ user-tested: bar, both sidebars, overview, launcher, notifications, lock, settings, waffle switch |

### end-4 log on `41651d7d` (`docs/dev/logs/ii-on-quickshell-41651d7.log`)
31 lines: 4 INFO, 10 DEBUG, 16 WARN, 1 "ERROR". **None comes from a Quickshell API or version mismatch.** A version problem looks like Caelestia's: `Unrecognized pragma`, `… is not a type`, `module "Quickshell.X" is not installed`. Nothing like that appears.

| Message | Cause | Action |
|---|---|---|
| `first_run.txt`, `generated/wallpaper/category.txt` missing | First-run state files not created yet | none |
| `translations/vi_VN.json` missing | Locale is `vi_VN`; end-4 has no Vietnamese file, so it falls back to English | none (optional: contribute a translation) |
| `[KeyringStorage] Entry not found, initializing.` (ERROR) | First use of the keyring entry; logged at ERROR level but expected | none |
| `NotificationPopup.qml[17]` `'enable' of undefined` | `Config.options.notifications.forceMonitor.enable` read before config is ready | end-4 startup order; harmless |
| `BarContent.qml[134]` undefined → double | `workspacesWidget.widgetPadding` read before `Workspaces` exists | same |
| `ToolbarTabBar.qml[59]` undefined → `QQuickItem*` | `contentItem.children[currentIndex]` empty at startup | same |
| `AiChat.qml` / `Anime.qml` `'commandPrefix' of null` | Bindings run while lazy sidebar content is created or torn down | same |
| `Parameter "mouse" is not declared` | Qt 6.11 deprecation in end-4 `NotificationGroup.qml:88` | upstream cleanup, harmless |
| `Could not register app ID` (portal) | Known QApplication + portal message | none |
| `failed to create compose table` | Qt compose table for the `vi_VN` locale | only affects dead-key composition |

### Consequences
- Phase 1's top risk ("no single Quickshell runs both") is **closed**.
- The machine currently has AUR `quickshell-git` at `41651d7d`. **It isn't pinned yet:** a yay devel update (`yay -Syu --devel`) would rebuild it from a newer commit.
  - Next Phase 1 step: package it as `caelestia4-quickshell` with `#commit=41651d7…` and `provides/conflicts=(quickshell quickshell-git)`, like end-4's PKGBUILD. Until then, avoid `--devel` updates.
- end-4's installer will try to reinstall `illogical-impulse-quickshell-git` (pinned `7511545e`) on its next run. Our install flow must skip that metapackage or replace it with ours.

## 1.2 Repo layout: ✅ (2026-10-03)
- **end-4 upstream:** remote `upstream` = `end-4/dots-hyprland`, merged at **`547836f1b0`** with `--allow-unrelated-histories`. Submodule `dots/.config/quickshell/ii/modules/common/widgets/shapes` initialized (`e31ec4cb`).
- **Caelestia source:** `git subtree --squash` at `third_party/caelestia-shell/`, tag **v2.5.0** (tag object `96470e43` → commit **`d999d487`**).

## 1.3 Caelestia C++ plugin, built user-locally: ✅
- `tools/build-caelestia-plugin.sh`: `ENABLE_MODULES=plugin` only, prefix `~/.local`, `INSTALL_QMLDIR=lib/qt6/qml`. Installs `~/.local/lib/qt6/qml/Caelestia/` with 9 modules: `Caelestia`, `.Blobs`, `.Components`, `.Config`, `.I18n`, `.Images`, `.Models`, `.Services`, `.Settings`. Backing libraries go to `Caelestia/lib/` and are found through `$ORIGIN` rpath, so the install can be moved.
- Build deps added to the system: `aubio` (repo), `libcava` (AUR, LukashonakV fork; the repo `cava` package has no library). 5 compiler warnings, 0 errors.
- **Smoke test** `tools/tests/plugin-smoke/` (offscreen, Quickshell `41651d7d`):
  - with `QML_IMPORT_PATH=~/.local/lib/qt6/qml` → `SMOKE OK … BlobRect = caelestia::blobs::BlobRect(…)` ✅
  - without it → `module "Caelestia.Blobs" is not installed` ✅. This proves the plugin is invisible outside sessions that set the import path, so Plasma is unaffected.
- Still needed at **runtime** for the ported UI (Phase 3): `qt6-m3shapes-git` (AUR, by Caelestia's author). Not needed for the plugin build.

## 1.4 Pinned Quickshell package: ✅ installed (2026-10-03)
`packaging/caelestia4-quickshell/PKGBUILD`: `git+…#commit=41651d7d…`, `provides=(quickshell quickshell-git)`, `conflicts=(quickshell quickshell-git illogical-impulse-quickshell-git)`. It's the same revision as the currently installed AUR `quickshell-git`, so installing it changes nothing functionally. It only stops `--devel` updates from moving the version.
Install (user): `cd packaging/caelestia4-quickshell && makepkg -si`

## 1.5 Tools: ✅
- `tools/port-imports.sh`: rewrites `qs.components|utils|services|modules.*` → `qs.modules.caelestia.{components,utils,adapters,*}` in place. Tested on a copy of all of Caelestia's `components/ modules/ services/ utils/`: **688/688 imports rewritten, 0 left, 0 double rewrites, idempotent.** (First version double-rewrote 588 lines because sed kept applying rules after a match; fixed with `;t`.)
- `tools/sync-upstreams.sh end4 <ref>` / `caelestia <tag>`: refuses to run on a dirty tree, merges or subtree-pulls, rebuilds the plugin, reruns the smoke test.

## 1.6 Remaining (needs sudo, user)
- [x] `makepkg -si` the pinned Quickshell package (1.4): replaced AUR `quickshell-git`; `qs --version` → "distributed by caelestia_4", plugin smoke test re-passed, `pacman -Dk` clean
- [ ] GPU udev symlink for `AQ_DRM_DEVICES` (Phase 0 note): a rule matching PCI `0000:01:00.0` → `/dev/dri/nvidia-dgpu`
- [ ] `yay -S qt6-m3shapes-git` (can wait until Phase 3)

**Phase 1 done criteria:**
- `qs -c ii` runs on the chosen Quickshell ✅ (user-tested in `e4test`)
- a test QML importing `Caelestia.Config` + `Caelestia.Blobs` loads ✅
