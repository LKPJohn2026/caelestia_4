// caelestia4: the Caelestia-design panel family (see docs/dev/PLAN.md, docs/dev/phase3.md).
//  - Caelestia design: frame + bar + all drawers (dashboard, launcher, notifications, OSD, session,
//    sidebar, utilities, popouts, toasts) and the background, running on end-4 services via adapters.
//  - Launcher = Caelestia launcher + end-4 LauncherSearch (Phase 5 merge); Overview (modules/caelestia/overview) = end-4's
//    workspace grid in Caelestia style, Super+Tab and Windows-style Alt+Tab.
//  - Assistant drawer (assistant/Wrapper.qml) hosts end-4's left-sidebar content (AI, translator) in the frame.
//  - end-4 modules reused as-is (re-skinned in Phase 7): overlay, wallpaper selector, lock.
//  - Dock (modules/caelestia/dock): Caelestia-style dock with end-4's dock features (caelestia.dock.enable).
//  - KeybindBridge routes end-4's session / right-sidebar / media keys to the Caelestia drawers.
import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.caelestia
import qs.modules.caelestia.background as CBackground
import qs.modules.caelestia.drawers as CDrawers
import qs.modules.caelestia.dock as CDock
import qs.modules.caelestia.osk as COsk
import qs.modules.caelestia.cheatsheet as CCheatsheet
import qs.modules.caelestia.overview as COverview
import qs.modules.caelestia.polkit as CPolkit
import qs.modules.caelestia.regionSelector as CRegion
import qs.modules.caelestia.screenTranslator as CTranslator
import qs.modules.caelestia.assistant as CAssistant
import qs.modules.ii.lock
import qs.modules.caelestia.overlay
import qs.modules.caelestia.wallpaperSelector as CWallpaper

Scope {
    // Caelestia core
    PanelLoader { component: GSFLoader {} }
    PanelLoader { component: ServiceLoader {} }
    PanelLoader { component: CBackground.Background {} }
    PanelLoader { component: CDrawers.Drawers {} }
    PanelLoader { component: Shortcuts {} }
    PanelLoader { component: BatteryMonitor {} }
    PanelLoader { component: KeybindBridge {} }
    PanelLoader { component: BackgroundMute {} } // mute games while unfocused (caelestia.backgroundMute)
    PanelLoader { component: COverview.Overview {} } // workspaces grid, Super+Tab / Alt+Tab (end-4 data, Caelestia style)
    PanelLoader { extraCondition: Config.options.caelestia.dock.enable; component: CDock.Dock {} }
    PanelLoader { component: COsk.Osk {} } // on-screen keyboard (end-4 logic, Caelestia style)
    PanelLoader { component: CRegion.RegionSelector {} } // screenshot / Lens / OCR / record (end-4 logic, Caelestia style)
    PanelLoader { component: CTranslator.ScreenTranslator {} } // screen translator (end-4 Google Cloud logic, Caelestia style)
    PanelLoader { component: CPolkit.Polkit {} } // polkit auth dialog (end-4 PolkitService, Caelestia style)
    PanelLoader { component: CCheatsheet.Cheatsheet {} } // keybinds + periodic table (end-4 data, Caelestia style)
    PanelLoader { component: CAssistant.DetachedWindow {} } // Assistant popped out into a window (Super+Alt+A / Ctrl+D)

    // end-4 modules, as-is
    PanelLoader { component: Lock {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: CWallpaper.WallpaperSelector {} } // Ctrl+Super+T (end-4 Wallpapers service, Caelestia style)
}
