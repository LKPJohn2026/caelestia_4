// caelestia4: the Caelestia-design panel family (see PLAN.md, docs/phase3.md).
//  - Caelestia design: frame + bar + all drawers (dashboard, launcher, notifications, OSD, session,
//    sidebar, utilities, popouts, toasts) and the background, running on end-4 services via adapters.
//  - Launcher = Caelestia launcher + end-4 LauncherSearch (Phase 5 merge); WorkspaceOverview = end-4 overview
//    grid without its search (Super+Tab).
//  - end-4 modules reused as-is (re-skinned in Phase 7): cheatsheet, left sidebar (AI,
//    translator), region tools, screen translator, OSK, overlay, wallpaper selector, lock, polkit.
//  - KeybindBridge routes end-4's session / right-sidebar / media keys to the Caelestia drawers.
import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.caelestia
import qs.modules.caelestia.background as CBackground
import qs.modules.caelestia.drawers as CDrawers
import qs.modules.ii.cheatsheet
import qs.modules.ii.lock
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenTranslator
import qs.modules.ii.sidebarLeft
import qs.modules.ii.wallpaperSelector

Scope {
    // Caelestia core
    PanelLoader { component: GSFLoader {} }
    PanelLoader { component: ServiceLoader {} }
    PanelLoader { component: CBackground.Background {} }
    PanelLoader { component: CDrawers.Drawers {} }
    PanelLoader { component: Shortcuts {} }
    PanelLoader { component: BatteryMonitor {} }
    PanelLoader { component: KeybindBridge {} }
    PanelLoader { component: WorkspaceOverview {} }

    // end-4 modules, as-is
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: WallpaperSelector {} }

    // Phase 2 adapter self-test (Config.options.caelestia.debugProbe)
    PanelLoader {
        extraCondition: Config.options.caelestia.debugProbe
        component: AdapterProbe {}
    }
}
