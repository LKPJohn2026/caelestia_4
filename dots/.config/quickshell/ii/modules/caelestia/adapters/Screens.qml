pragma Singleton

import Quickshell
import Caelestia.Config

Singleton {
    id: root

    // caelestia4: screens a window can be shown on. When the only monitor goes (one that drops off its link on resume),
    // Hyprland puts up a virtual output named FALLBACK that nobody sees, and while no output at all is there,
    // Qt has a placeholder screen with no name. A ShellScreen whose QScreen is gone names itself "{ NULL SCREEN }". A
    // full set of windows on any of these is made only to be destroyed a moment later, with "Config.* accessed without
    // a screen" and "dangling screen" warnings on the way, and each name gets its own per-screen config layer in the
    // plugin.
    readonly property list<ShellScreen> real: Quickshell.screens.filter(s => s.name !== "" && s.name !== "{ NULL SCREEN }" && s.name !== "FALLBACK")
    readonly property list<ShellScreen> screens: real.filter(s => GlobalConfig.forScreen(s.name).enabled)

    function isExcluded(screen: ShellScreen): bool {
        return !GlobalConfig.forScreen(screen.name).enabled;
    }
}
