# Phase 1: Repo and toolchain (log)

## 1.1 One Quickshell for both shells: ✅ decided (2026-10-03)

**Pin: `quickshell-git` 0.3.1 r18, revision `41651d7dcd62a9400eb6f4f8a8580efe00901efb`.**

| Shell | On end-4's pin `7511545e` (0.2.1) | On `41651d7d` (0.3.1) |
|---|---|---|
| Caelestia v2.5.0 | ❌ fails at load: `Unrecognized pragma "DefaultEnv …"` | ✅ fully working (Phase 0.9) |
| end-4 `ii` @ `547836f1b0` | ✅ (upstream default) | ✅ user-tested: bar, both sidebars, overview, launcher, notifications, lock, settings, waffle switch |

### end-4 log on `41651d7d` (`docs/logs/ii-on-quickshell-41651d7.log`)
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
